####################################################################
# Network resources - VPC & firewall
####################################################################



###########################
# VPC
###########################

resource "google_compute_network" "vault_network" {
  name                    = "vault-network"
  project                 = var.project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.service]
}

resource "google_compute_subnetwork" "vault_subnet" {
  name                     = "vault-subnet"
  project                  = var.project_id
  region                   = var.region
  ip_cidr_range            = local.subnet_cidr_range
  network                  = google_compute_network.vault_network.id
  private_ip_google_access = true
}


###########################
# Firewall rules
###########################

# Google health check source CIDRs
data "google_compute_lb_ip_ranges" "ranges" {
}

# Allow Google to talk to Vault HC endpoint
resource "google_compute_firewall" "allow_lb_healthcheck" {
  name          = "vault-allow-lb-healthcheck"
  project       = var.project_id
  network       = google_compute_network.vault_network.id
  source_ranges = concat(data.google_compute_lb_ip_ranges.ranges.network, data.google_compute_lb_ip_ranges.ranges.http_ssl_tcp_internal)
  target_tags   = ["allow-vault"]

  allow {
    protocol = "tcp"
    ports    = [local.health_check_port]
  }

  depends_on = [google_project_service.service]
}

# Allow external CIDRs to talk to Vault
resource "google_compute_firewall" "allow_external" {
  name          = "vault-allow-external"
  project       = var.project_id
  network       = google_compute_network.vault_network.id
  source_ranges = var.allowed_external_cidrs
  target_tags   = ["allow-vault"]

  allow {
    protocol = "tcp"
    ports    = [local.vault_port]
  }

  depends_on = [google_project_service.service]
}

# Allow Vault nodes to talk internally on the Vault ports.
resource "google_compute_firewall" "allow_internal" {
  name          = "vault-allow-internal"
  project       = var.project_id
  network       = google_compute_network.vault_network.id
  source_ranges = [local.subnet_cidr_range]

  allow {
    protocol = "tcp"
    ports    = [local.vault_port]
  }

  depends_on = [google_project_service.service]
}
