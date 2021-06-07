# Ensure GOOGLE_APPLICATION_CREDENTIALS environment variable is set

/*

# Cannot use this block at present, module can't depend on it

provider "google" {
  project = var.project_id
  region  = var.region
}

# Ensure compute API is enabled
resource "google_project_service" "compute_api" {
  project                    = var.project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}
*/

# Go for it!
module "vault" {
  source  = "terraform-google-modules/vault/google"
  version = "5.3.0"

  project_id = var.project_id
  region     = var.region

  storage_bucket_class    = "MULTI_REGIONAL"
  storage_bucket_location = "eu"

  # manage_tls = true # TODO: manage TLS
  # network  ="" # TODO: create own network
  # vault_allowed_cidrs =[ "0.0.0.0/0" ] # TODO: restrict access to vault to desktop IP

  allow_ssh                    = false # Best practice to disable SSH access
  storage_bucket_force_destroy = true  # This is only a demo so remove data on destroy to save ££
  vault_version                = "1.6.0"
}


output "vault_addr" {
  value = module.vault.vault_addr
}