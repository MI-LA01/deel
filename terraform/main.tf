terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.40.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file_path)

  project = var.project_id
  region  = var.region
  zone    = var.main_zone
}

module "google_artifactory" {
  source = "./artifactory"

  project         = var.project_id
  repository_id   = var.repository_id 
  region          = var.region
}

module "google_networks" {
  source = "./networks"

  project_id = var.project_id
  region     = var.region
}

module "google_kubernetes_cluster" {
  source = "./kubernetes_cluster"

  project_id                 = var.project_id
  region                     = var.region
  node_zones                 = var.cluster_node_zones
  service_account            = var.service_account
  network_name               = module.google_networks.network.name
  subnet_name                = module.google_networks.subnet.name
  master_ipv4_cidr_block     = module.google_networks.cluster_master_ip_cidr_range
  pods_ipv4_cidr_block       = module.google_networks.cluster_pods_ip_cidr_range
  services_ipv4_cidr_block   = module.google_networks.cluster_services_ip_cidr_range
  authorized_ipv4_cidr_block = "${module.bastion.ip}/32"
}

# module "ha_vpn" {
#   source = "./ha_vpn"

#   region       = var.region
#   router_name  = module.google_networks.router.name
#   router_link  = module.google_networks.router.self_link
#   network_name = module.google_networks.network.name
#   network_link = module.google_networks.network.self_link
# }

module "bastion" {
  source = "./bastion"

  project_id   = var.project_id
  region       = var.region
  zone         = var.main_zone
  bastion_name = "deel-app-cluster"
  network_name = module.google_networks.network.name
  subnet_name  = module.google_networks.subnet.name
}
