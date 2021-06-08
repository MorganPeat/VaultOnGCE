####################################################################
# KMS assets used for auto-unseal
####################################################################

resource "google_kms_key_ring" "vault" {
  name     = "vault"
  location = var.region
  project  = var.project_id

  depends_on = [google_project_service.service]
}

resource "google_kms_crypto_key" "vault_init" {
  name            = "vault-init"
  key_ring        = google_kms_key_ring.vault.id
  rotation_period = "604800s"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }
}
