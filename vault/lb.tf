####################################################################
# Load balancer
####################################################################

# This legacy health check is required because the target pool requires an HTTP
# health check.
resource "google_compute_http_health_check" "vault" {
  name    = "vault-health-legacy"
  project = var.project_id

  check_interval_sec  = 15
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  port                = local.health_check_port
  request_path        = local.hc_workload_request_path
}


resource "google_compute_target_pool" "vault" {
  name    = "vault-tp"
  project = var.project_id
  region  = var.region

  health_checks = [google_compute_http_health_check.vault.name]
}

resource "google_compute_forwarding_rule" "external" {
  name                  = "vault-external"
  project               = var.project_id
  region                = var.region
  ip_protocol           = "TCP"
  port_range            = local.vault_port
  load_balancing_scheme = "EXTERNAL"
  network_tier          = "PREMIUM"
  target                = google_compute_target_pool.vault.self_link
}

