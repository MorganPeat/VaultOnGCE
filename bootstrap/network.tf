####################################################################
# Network resources - VPC & firewall
####################################################################



###########################
# VPC
###########################

resource "google_compute_network" "packer_network" {
  name                    = "packer-network"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "packer_subnet" {
  name                     = "packer-subnet"
  project                  = var.project_id
  region                   = var.region
  ip_cidr_range            = local.packer_subnet_cidr_range
  network                  = google_compute_network.packer_network.id
  private_ip_google_access = true
}


###########################
# Firewall rules
###########################

# Allow SSHing into machines tagged "allow-ssh"
resource "google_compute_firewall" "allow-ssh" {
  name          = "packer-allow-ssh"
  project       = var.project_id
  network       = google_compute_network.packer_network.id
  source_ranges = var.allowed_external_cidrs
  target_tags   = ["allow-ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  lifecycle {
    ignore_changes = [
      source_service_accounts,
      source_tags,
      target_service_accounts,
    ]
  }
}

