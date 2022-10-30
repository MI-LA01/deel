resource "google_compute_ha_vpn_gateway" "ha_gateway1" {
  #provider = google
  region   = var.region
  name     = "ha-vpn-1"
  network  = var.network_link
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
 #provider        = google
  name            = "hq-portugal"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  description     = "An externally managed VPN gateway"
  interface {
    id         = 0
    ip_address = var.on_prem_ip1
  }
}

# google_compute_network.tf_vpc_net1 = "deel-kubernetes-cluster"
# google_compute_subnetwork.tf_vpc_net1_subnet1 = "deel-kubernetes-cluster--subnet"

# resource "google_compute_network" "tf_vpc_net1" {
#   name                    = "tf-vpc-net-1"
#   routing_mode            = "GLOBAL"
#   auto_create_subnetworks = false
# }

# resource "google_compute_subnetwork" "tf_vpc_net1_subnet1" {
#   name          = "ha-vpn-subnet-1"
#   ip_cidr_range = "10.0.1.0/24"
#   region        = "us-central1"
#   network       = google_compute_network.tf_vpc_net1.self_link
# }

# resource "google_compute_subnetwork" "tf_vpc_net1_subnet2" {
#   name          = "ha-vpn-subnet-2"
#   ip_cidr_range = "10.0.2.0/24"
#   region        = "us-west1"
#   network       = google_compute_network.tf_vpc_net1.self_link
# }

# resource "google_compute_router" "router1" {
#   name    = "ha-vpn-router-1"
#   network = google_compute_network.tf_vpc_net1.name
#   bgp {
#     asn = var.gcp_asn
#   }
# }

resource "google_compute_vpn_tunnel" "tunnel1" {
 # provider                        = google
  name                            = "ha-vpn-tunnel1"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway1.self_link
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.self_link
  peer_external_gateway_interface = 0
  shared_secret                   = var.gcp_shared_secret
  router                          = var.router_link #"deel-kubernetes-cluster-router" #google_compute_router.router1.self_link
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "tunnel2" {
#  provider                        = google
  name                            = "ha-vpn-tunnel2"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway1.self_link
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.self_link
  peer_external_gateway_interface = 0
  shared_secret                   = var.gcp_shared_secret
  router                          = var.router_link #"deel-kubernetes-cluster-router"
  vpn_gateway_interface           = 1
}

resource "google_compute_router_interface" "router1_interface1" {
  name       = "router1-interface1"
  router     = var.router_name
  region     = var.region
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_interface" "router1_interface2" {
  name       = "router1-interface2"
  router     = var.router_name
  region     = var.region
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "router1_peer1" {
  name                      = "router1-peer1"
  router                    = var.router_name
  region                    = var.region
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = var.on_prem_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface1.name
}

resource "google_compute_router_peer" "router1_peer2" {
  name                      = "router1-peer2"
  router                    = var.router_name
  region                    = var.region
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = var.on_prem_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface2.name
}

# resource "google_compute_firewall" "tf_firewall" {
#   name    = "terraform-firewall-base"
#   network = google_compute_network.tf_vpc_net1.self_link

#   allow {
#     protocol = "icmp"
#   }


#   allow {
#     protocol = "tcp"
#     ports    = ["22", "80", "443"]
#   }

#   source_ranges = ["0.0.0.0/0"]
# }
