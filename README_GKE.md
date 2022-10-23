## GCP
- Create new gmail account 
- Create new free cloud platform (300USD Credit)
- Create a service account api []
Enable : 
- Compute Engine API
- Identity and Access Management (IAM) API
- Cloud DNS API
- Cloud Deployment Manager V2 API
- Cloud Deployment Manager API
- Kubernetes Engine API
- Config Monitoring for Ops API
- Cloud Logging API
- Artifact Registry API


## Dependencies 
```
sudo apt-get install kubectl google-cloud-sdk-gke-gcloud-auth-plugin
```

## Authentication 
```
gcloud auth activate-service-account sa-deel-adm@deel-cloud-demo.iam.gserviceaccount.com --key-file=deel-cloud-demo-41d9821b7384.json
```

## GCP, GKE and Terraform
A complete infrastruture can be spined-up to google cloud leveraging IaC and Hashicorp terraform. 
Feature : 
- GKS Private Cluster with max 3 nodes (autoscaling on)
- Bastion host to access the management plane + an IPSec VPN to get access from local client. 

```
cd terraform
terraform init
terraform validate
terraform plan
terraform apply 
```

### Get K8s cluster configuration (And test)
```
gcloud auth login
gcloud config set project deel-cloud-demo
gcloud container clusters get-credentials deel-app-cluster --zone europe-west3
kubectl config view
kubectl cluster-info
```

## VPN 
An IPSec VPN is provisonned by terraform on the bastion host to access remotely the private cluster. To configure the local vpn client you can run : 
```
gcloud compute ssh --zone europe-west3-b deel-app-cluster-bastion -- sudo journalctl -u google-startup-scripts.service -e

Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script: Connect to your new VPN with these details:
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script:
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script: Server IP: 35.207.89.211
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script: IPsec PSK: 3WhPiMAUYbugn89UPCRj
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script: Username: vpnuser
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script: Password: 7G5rokoG2Buv8WtV
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script:
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script: Write these down. You'll need them to connect!
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script:
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script: VPN client setup: https://vpnsetup.net/clients
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script:
Oct 16 14:34:59 deel-app-cluster-bastion google_metadata_script_runner[491]: startup-script: ================================================
```

## Docker & GCR 
Buildkit is used to build the service container. Once the built, the container is pushed to GCR. 

### Docker auth to GCR 
```
gcloud auth configure-docker europe-west3-docker.pkg.dev

```

### Docker Build
```
docker build -t gcr.io/deel-cloud-demo/deel-app:0.2.0
docker push
```


## Helm chart 
Install/Unistall from local chart. 
```
helm install deel-app ./
helm uninstall deel-app 
```

To authenticate and push to remote helm chart. 
```
gcloud artifacts repositories create deel-helm-repo --repository-format=docker --location=europe-west3 --description="Deel Demo Helm repository"

export GOOGLE_APPLICATION_CREDENTIALS=deel-cloud-demo-41d9821b7384.json
gcloud auth application-default print-access-token
gcloud auth application-default print-access-token | helm registry login -u oauth2accesstoken --password-stdin https://europe-west3-docker.pkg.dev

helm install deel-app oci://europe-west3-docker.pkg.dev/deel-cloud-demo/deel-helm-repo/deel-app --version 0.1.1


helm push deel-app-0.1.0.tgz oci://europe-west3-docker.pkg.dev/deel-cloud-demo/deel-helm-repo
helm install deel-app oci://europe-west3-docker.pkg.dev/deel-cloud-demo/deel-helm-repo/deel-app --version 0.1.0
```

To deploy 

## Ngnix Ingress
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create ns nginx
helm install nginx ingress-nginx/ingress-nginx --namespace nginx --set rbac.create=true --set controller.publishService.enabled=true
```

Then get the external-ip and set it with gcloud (suppose the zone already exist and ns where configured properly)
```
kubectl get svc -n nginx
NAME                                       TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
nginx-ingress-nginx-controller             LoadBalancer   10.102.111.227   35.246.203.108   80:30907/TCP,443:31465/TCP   58s
nginx-ingress-nginx-controller-admission   ClusterIP      10.102.1.16      <none>           443/TCP                      58s

gcloud dns record-sets transaction start --zone=public-grt

gcloud dns record-sets transaction add 35.246.203.108 \
    --name=deel.grt.soy \
    --ttl=300 \
    --type=A \
    --zone=public-grt 

gcloud dns record-sets transaction execute --zone=public-grt
```

Workaround required for webhook, authorise master to speak with nodes tcp:8443

```
gcloud compute firewall-rules list --filter 'name~^gke' --format 'table(
>         name,
>         network,
>         direction,
>         sourceRanges.list():label=SRC_RANGES,
>         allowed[].map().firewall_rule().list():label=ALLOW,
>         targetTags.list():label=TARGET_TAGS
>     )'
NAME                                  NETWORK                  DIRECTION  SRC_RANGES       ALLOW                         TARGET_TAGS
gke-deel-app-cluster-dbe0bb6b-all     deel-kubernetes-cluster  INGRESS    10.101.0.0/16    ah,sctp,tcp,udp,icmp,esp      gke-deel-app-cluster-dbe0bb6b-node
gke-deel-app-cluster-dbe0bb6b-master  deel-kubernetes-cluster  INGRESS    10.100.100.0/28  tcp:10250,tcp:443             gke-deel-app-cluster-dbe0bb6b-node
gke-deel-app-cluster-dbe0bb6b-vms     deel-kubernetes-cluster  INGRESS    10.10.0.0/16     icmp,tcp:1-65535,udp:1-65535  gke-deel-app-cluster-dbe0bb6b-node

Replace master src_ranges and target tag 
gcloud compute firewall-rules create deel-app-cluster-master-nginx-ingress --action ALLOW --direction INGRESS  --source-ranges 10.100.100.0/28 --rules tcp:8443 --target-tags gke-deel-app-cluster-dbe0bb6b-node --project deel-cloud-demo

```


## Cert manager for Nginx 
```
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.9.1/cert-manager.yaml
kubectl get pods --namespace cert-manager
NAME                                      READY   STATUS    RESTARTS   AGE
cert-manager-55649d64b4-rwf2d             1/1     Running   0          41s
cert-manager-cainjector-666db4777-54l74   1/1     Running   0          41s
cert-manager-webhook-6466bc8f4-4xh2b      1/1     Running   0          40s

kubectl create --edit -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/staging-issuer.yaml
kubectl create --edit -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/production-issuer.yaml

# This a fix.. https://github.com/kubernetes/ingress-nginx/issues/5401
kubectl delete -A ValidatingWebhookConfiguration nginx-ingress-nginx-admission 
```


## Nginx enable underscores in headers 
The profile_id request header is not supported by ingress-nginx on k8s. 
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ingress-nginx-controller 
  namespace: nginx
  labels:
    app: nginx
data:
  enable-underscores-in-headers: "true"

```

Then : 

```
kubectl apply -f configmap.yml 
kubectl describe cm nginx-ingress-nginx-controller -n nginx
Name:         nginx-ingress-nginx-controller
Namespace:    nginx
Labels:       app=nginx
              app.kubernetes.io/component=controller
              app.kubernetes.io/instance=nginx
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=ingress-nginx
              app.kubernetes.io/part-of=ingress-nginx
              app.kubernetes.io/version=1.4.0
              helm.sh/chart=ingress-nginx-4.3.0
Annotations:  meta.helm.sh/release-name: nginx
              meta.helm.sh/release-namespace: nginx

Data
====
allow-snippet-annotations:
----
true
enable-underscores-in-headers:
----
true

BinaryData
====

Events:  <none>
```


## Firewalling (not working for cert-manager)
```
gcloud compute firewall-rules list --filter 'name~^gke' --format 'table(
        name,
        network,
        direction,
        sourceRanges.list():label=SRC_RANGES,
        allowed[].map().firewall_rule().list():label=ALLOW,
        targetTags.list():label=TARGET_TAGS
)'


gcloud compute firewall-rules create deel-app-cluster-master-nginx-ingress --action ALLOW --direction INGRESS  --source-ranges 10.100.100.0/28 --rules tcp:8443 --target-tags gke-deel-app-cluster-dbe0bb6b-node --project deel-cloud-demo
```

Automated DNS record with Nginx/Ingress via Workload Identity 

DNS_SA_NAME="external-dns-sa"
GKE_PROJECT_ID="deel-cloud-demo" 
DNS_SA_EMAIL="$DNS_SA_NAME@${GKE_PROJECT_ID}.iam.gserviceaccount.com"
gcloud iam service-accounts create $DNS_SA_NAME --display-name $DNS_SA_NAME

gcloud projects add-iam-policy-binding $GKE_PROJECT_ID --member serviceAccount:$DNS_SA_EMAIL --role "roles/dns.admin"
gcloud iam service-accounts add-iam-policy-binding $DNS_SA_EMAIL --role "roles/iam.workloadIdentityUser" --member "serviceAccount:$GKE_PROJECT_ID.svc.id.goog[default/external-dns]"
kubectl create --namespace "default" -f x.yaml
kubectl annotate serviceaccount "external-dns" --namespace default "iam.gke.io/gcp-service-account=$DNS_SA_EMAIL"
kubectl patch deployment "external-dns" --namespace default --patch '{"spec": {"template": {"spec": {"nodeSelector": {"iam.gke.io/gke-metadata-server-enabled": "true"}}}}}'

https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/gke.md#worker-node-service-account

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  labels:
    app.kubernetes.io/name: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
  labels:
    app.kubernetes.io/name: external-dns
rules:
  - apiGroups: [""]
    resources: ["services","endpoints","pods","nodes"]
    verbs: ["get","watch","list"]
  - apiGroups: ["extensions","networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get","watch","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
  labels:
    app.kubernetes.io/name: external-dns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
  - kind: ServiceAccount
    name: external-dns
    namespace: default # change if namespace is not 'default'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  labels:
    app.kubernetes.io/name: external-dns  
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app.kubernetes.io/name: external-dns
  template:
    metadata:
      labels:
        app.kubernetes.io/name: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
        - name: external-dns
          image: k8s.gcr.io/external-dns/external-dns:v0.11.0
          args:
            - --source=service
            - --source=ingress
            - --domain-filter=grt.soy # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
            - --provider=google
            - --log-format=json # google cloud logs parses severity of the "text" log format incorrectly
            - --google-project=deel-cloud-demo # Use this to specify a project different from the one external-dns is running inside
            - --google-zone-visibility=public # Use this to filter to only zones with this visibility. Set to either 'public' or 'private'. Omitting will match public and private zones
            - --policy=sync # upsert-only would prevent ExternalDNS from deleting any records, omit to enable full synchronization
            - --registry=txt
            - --txt-owner-id=my-identifier
```

kubectl apply -f 


## Readings :

- https://medium.com/bluekiri/deploy-a-nginx-ingress-and-a-certitificate-manager-controller-on-gke-using-helm-3-8e2802b979ec
- https://thoeny.dev/create-a-private-gcp-kubernetes-cluster-using-terraform
- https://www.padok.fr/en/blog/kubernetes-google-cloud-platform-app-helm
- https://phoenixnap.com/kb/helm-install-command
- https://blog.container-solutions.com/using-google-container-registry-with-kubernetes
- https://overlaid.net/2020/04/03/terraform-an-ha-vpn-between-gcp-and-cisco/#configuring-cisco
- https://cloud.google.com/community/tutorials/nginx-ingress-gke
- https://github.com/hashicorp/learn-terraform-provision-gke-cluster/blob/main/vpc.tf
- https://github.com/hwdsl2/setup-ipsec-vpn