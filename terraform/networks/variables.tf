variable "project_id" {
  type = string
  description = "The project ID to host the network in"
}

variable "region" {
  type = string
  description = "The region to use"
}

variable "gateway_name" {
  type = string
  default = "vpn-prod-internal"
  description = "The name for the VPN gateway"
}

variable "tunnel_name_prefix" {
  type = string
  default = "vpn-tn-prod-internal"
  description = "The prefix name for the tunnel" 
}

variable "shared_secret" {
  type = string
  default = "secrets" 
  description = "The shared secret" 
}
