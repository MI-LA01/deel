variable gcp_asn {
  description = "BGP ASN or GCP Cloud Router"
  default     = 64997
}

variable on_prem_asn {
  description = "BGP ASN or On-Prem Router"
  default     = 65000
}

variable gcp_shared_secret {
  description = "VPN shared secret"
  default     = "d0v3r1a1d"
}

variable on_prem_ip1 {
  description = "The IP of the on-prem VPN gateway"
  default     = "176.79.249.208"
}

variable "region" {
  type = string
  description = "The region to use"
}

variable "router_name" {
  type = string
  description = "the router name"
}

variable "router_link" {
  type = string
  description = "the router self link"
}

variable "network_name" {
  type = string
  description = "The name of the network that should be used."
}

variable "network_link" {
  type = string
  description = "The uri of the network that should be used."
}

# variable "subnet_name" {
#   type = string
#   description = "The name of the subnet that should be used."
# }

