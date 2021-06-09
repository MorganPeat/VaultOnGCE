####################################################################
# Compute resources - MIG & startup scripts
####################################################################


###########################
# Startup scripts
###########################

# Vault config file
data "template_file" "vault_config" {
  template = file("${path.module}/templates/config.hcl.tpl")

  vars = {
    lb_ip             = google_compute_forwarding_rule.external.ip_address
    vault_port        = local.vault_port
    health_check_port = local.health_check_port

    kms_project    = var.project_id
    kms_region     = google_kms_key_ring.vault.location
    kms_keyring    = google_kms_key_ring.vault.name
    kms_crypto_key = google_kms_crypto_key.vault_init.name

    storage_bucket = google_storage_bucket.vault.name
  }
}

# VM Startup script
data "template_file" "vault_startup_script" {
  template = file("${path.module}/templates/startup.sh.tpl")

  vars = {
    vault_port       = local.vault_port
    vault_tls_bucket = google_storage_bucket.tls.name
    config           = data.template_file.vault_config.rendered
  }
}


###########################
# MIG
###########################

# Template for Vault VMs
resource "google_compute_instance_template" "vault" {
  project      = var.project_id
  region       = var.region
  name_prefix  = "vault-"
  machine_type = "e2-standard-2"

  tags = ["allow-vault"]

  network_interface {
    subnetwork = google_compute_subnetwork.vault_subnet.id
  }

  disk {
    source_image = var.vault_instance_base_image
    type         = "PERSISTENT"
    disk_type    = "pd-balanced"
    mode         = "READ_WRITE"
    boot         = true
  }

  service_account {
    email  = google_service_account.vault_admin.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    # Supplies more entropy for random number generation
    # Cannot find source of this metadata label!
    "google-compute-enable-virtio-rng" = "true"
    "startup-script"                   = data.template_file.vault_startup_script.rendered
  }

  lifecycle {
    create_before_destroy = true
  }

}

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

# Autoscaling group for Vault VMs
resource "google_compute_region_instance_group_manager" "vault" {
  name    = "vault-igm"
  project = var.project_id
  region  = var.region

  base_instance_name = "vault-${var.region}"
  wait_for_instances = false

  auto_healing_policies {
    health_check      = google_compute_health_check.autoheal.id
    initial_delay_sec = 60
  }

  update_policy {
    type                  = "OPPORTUNISTIC"
    minimal_action        = "REPLACE"
    max_unavailable_fixed = length(data.google_compute_zones.available.names)
  }

  target_pools = [google_compute_target_pool.vault.self_link]

  named_port {
    name = "vault-http"
    port = local.vault_port
  }

  version {
    instance_template = google_compute_instance_template.vault.self_link
  }
}

# Autoscaling policies for vault
resource "google_compute_region_autoscaler" "vault" {
  name    = "vault-as"
  project = var.project_id
  region  = var.region
  target  = google_compute_region_instance_group_manager.vault.self_link

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 3
    cooldown_period = 300

    cpu_utilization {
      target = 0.8
    }
  }
}

# Auto-healing
resource "google_compute_health_check" "autoheal" {
  name    = "vault-health-autoheal"
  project = var.project_id

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 1
  unhealthy_threshold = 2

  https_health_check {
    port         = local.vault_port
    request_path = local.hc_autoheal_request_path
  }
}
