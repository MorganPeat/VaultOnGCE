locals {

  # Port on which Vault runs
  vault_port = "8200"

  # Port to use for vault health check http endpoint. Only accessible from Google health check addresses.
  health_check_port = "8300"

  # CIDR range for the subnet
  subnet_cidr_range = "10.1.0.0/20"

  # Base OS image to use on Vault VM
  vault_instance_base_image = "debian-cloud/debian-10"

  # URL for LB health check - uninitialised vault can accept traffic, standbys cannot
  hc_workload_request_path = "/v1/sys/health?uninitcode=200"

  # URL for autoheal health check - uninitialised vault is health as are standbys
  hc_autoheal_request_path = "/v1/sys/health?uninitcode=200&standbyok=true"
}


# Ensure GOOGLE_APPLICATION_CREDENTIALS environment variable points to the location of a SA key json file
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

