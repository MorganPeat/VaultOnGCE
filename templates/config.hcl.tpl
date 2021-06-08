####################################################################
# Vault configuration file
####################################################################


log_level = "warn"
ui        = true


###########################
# HA
###########################

# LB address that the cluster can be reached on
api_addr = "https://${lb_ip}:${vault_port}"
# Address that nodes in the cluster can reach this host on
# (LOCAL_IP is replaced with the eth0 IP address by the startup script)
cluster_addr = "https://LOCAL_IP:8201"


###########################1
# Auto-unseal
###########################

seal "gcpckms" {
  project    = "${kms_project}"
  region     = "${kms_region}"
  key_ring   = "${kms_keyring}"
  crypto_key = "${kms_crypto_key}"
}


###########################
# HA storage
###########################

storage "gcs" {
  bucket     = "${storage_bucket}"
  ha_enabled = "true"
}


###########################
# Listeners
###########################

# Local non-TLS listener
# MP: why?
listener "tcp" {
  address     = "127.0.0.1:${vault_port}"
  tls_disable = true
}

# Non-TLS listener for the HTTP health checks.
# Firewall rules must permit only Google LB health checks!
listener "tcp" {
  address     = "${lb_ip}:${health_check_port}"
  tls_disable = true
}

# mTLS listener on the load balancer address
listener "tcp" {
  address            = "${lb_ip}:${vault_port}"
  tls_cert_file      = "/etc/vault.d/tls/vault.crt"
  tls_key_file       = "/etc/vault.d/tls/vault.key"
  tls_client_ca_file = "/etc/vault.d/tls/ca.crt"

  tls_require_and_verify_client_cert = "false" # mTLS disabled
}

# mTLS listener locally. Used by cluster nodes to communicate with each other
listener "tcp" {
  address            = "LOCAL_IP:${vault_port}"
  tls_cert_file      = "/etc/vault.d/tls/vault.crt"
  tls_key_file       = "/etc/vault.d/tls/vault.key"
  tls_client_ca_file = "/etc/vault.d/tls/ca.crt"

  tls_require_and_verify_client_cert = "false" # mTLS disabled
}

###########################
# Stackdriver
###########################

telemetry {
  statsd_address   = "127.0.0.1:8125"
  disable_hostname = true
}
