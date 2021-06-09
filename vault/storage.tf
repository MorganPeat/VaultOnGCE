####################################################################
# GCS used for vault backend state
####################################################################

# GCS bucket where Vault data will be stored
resource "google_storage_bucket" "vault" {
  project  = var.project_id
  name     = "${var.project_id}-vault-data"
  location = upper(var.region) # Set to multi-region for higher availability
}

# GCS bucket where TLS certs will be stored
resource "google_storage_bucket" "tls" {
  project  = var.project_id
  name     = "${var.project_id}-tls-data"
  location = upper(var.region) # Set to multi-region for higher availability
}
