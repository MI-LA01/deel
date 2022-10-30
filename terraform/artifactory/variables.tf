variable "repository_id" {
  type = string
  description = "The repository_id"
}

variable "region" {
  type = string
  description = "The zone where the Bastion host is located in."
}

variable "project" {
  type = string
  description = "The project ID to host the network in."
}
