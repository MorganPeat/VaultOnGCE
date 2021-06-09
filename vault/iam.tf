####################################################################
# Permissions
####################################################################

locals {
  vault_sa_iam_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
  vault_sa_bucket_iam_roles = [
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin",
  ]
}

# Create the vault-admin service account.
resource "google_service_account" "vault_admin" {
  account_id   = "vault-admin"
  display_name = "Vault Admin"
  project      = var.project_id
}

# Give project-level IAM permissions to the service account.
resource "google_project_iam_member" "project_iam" {
  for_each = toset(local.vault_sa_iam_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.vault_admin.email}"
}

# Give bucket-level permissions to the service account.
resource "google_storage_bucket_iam_member" "vault" {
  for_each = toset(local.vault_sa_bucket_iam_roles)
  bucket   = google_storage_bucket.vault.id
  role     = each.key
  member   = "serviceAccount:${google_service_account.vault_admin.email}"
}

resource "google_storage_bucket_iam_member" "tls" {
  bucket = google_storage_bucket.tls.id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.vault_admin.email}"
}

# Give kms cryptokey-level permissions to the service account.
resource "google_kms_crypto_key_iam_member" "ck_iam" {
  crypto_key_id = google_kms_crypto_key.vault_init.self_link
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.vault_admin.email}"
}

