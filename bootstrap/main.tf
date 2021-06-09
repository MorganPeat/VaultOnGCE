####################################################################
# Bootstrap a GCP project for a Vault setup
####################################################################

locals {
  # Must not clash with other subnets (i.e. vault)
  packer_subnet_cidr_range = "10.1.0.0/20"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required services on the project
resource "google_project_service" "service" {
  for_each           = var.project_services
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}
