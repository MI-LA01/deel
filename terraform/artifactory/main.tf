data "google_container_registry_repository" "registry" {}

resource "google_artifact_registry_repository" "deel-app-repo" {
  location      = var.region
  repository_id = var.repository_id
  project       = var.project
  description   = "Deel app reposity"
  format        = "DOCKER"
}

resource "google_container_registry" "registry" {
  project  =  var.project
  location = "EU"
}