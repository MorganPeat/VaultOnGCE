####################################################################
# Crypto assets used for vault mTLS
####################################################################

provider "tls" {}


###########################
# Root CA
###########################

# Generate a self-signed TLS certificate that will act as the root CA.
resource "tls_private_key" "root" {
  algorithm = "RSA"
}

# Sign root cert ourselves
resource "tls_self_signed_cert" "root" {
  key_algorithm   = tls_private_key.root.algorithm
  private_key_pem = tls_private_key.root.private_key_pem

  subject {
    common_name         = "Example Inc. Root"
    organization        = "Example, Inc"
    organizational_unit = "Department of Certificate Authority"
    street_address      = ["123 Example Street"]
    locality            = "The Intranet"
    province            = "CA"
    country             = "US"
    postal_code         = "95559-1227"
  }

  validity_period_hours = 26280
  early_renewal_hours   = 8760
  is_ca_certificate     = true

  allowed_uses = ["cert_signing"]
}

resource "local_file" "root" {
  content  = tls_self_signed_cert.root.cert_pem
  filename = "ca.crt"
}

###########################
# Server cert
###########################

# Vault server key
resource "tls_private_key" "vault_server" {
  algorithm = "RSA"
}

# Create the request to sign the cert with our CA
resource "tls_cert_request" "vault_server" {
  key_algorithm   = tls_private_key.vault_server.algorithm
  private_key_pem = tls_private_key.vault_server.private_key_pem

  dns_names = ["vault.example.net"]

  ip_addresses = [google_compute_forwarding_rule.external.ip_address, "127.0.0.1"]

  subject {
    common_name         = "vault.example.net"
    organization        = "Example, Inc"
    organizational_unit = "IT Security Operations"
  }
}

# Sign the cert
resource "tls_locally_signed_cert" "vault_server" {
  cert_request_pem   = tls_cert_request.vault_server.cert_request_pem
  ca_key_algorithm   = tls_private_key.root.algorithm
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem

  validity_period_hours = 17520
  early_renewal_hours   = 8760

  allowed_uses = ["server_auth"]
}


###########################
# GCS
###########################

resource "google_storage_bucket_object" "vault_ca_cert" {
  name    = "ca.crt"
  content = tls_self_signed_cert.root.cert_pem
  bucket  = google_storage_bucket.tls.name
}

resource "google_storage_bucket_object" "vault_server_cert" {
  name    = "vault.crt"
  content = tls_locally_signed_cert.vault_server.cert_pem
  bucket  = google_storage_bucket.tls.name
}


resource "google_storage_bucket_object" "vault_private_key" {
  name    = "vault.key"
  content = tls_private_key.vault_server.private_key_pem
  bucket  = google_storage_bucket.tls.name
}

