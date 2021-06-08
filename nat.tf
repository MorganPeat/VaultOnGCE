####################################################################
# NAT so VMs can access internet downloads
####################################################################


# Create a NAT router so the nodes can reach the public Internet
resource "google_compute_router" "vault_router" {
  name    = "vault-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vault_network.id

  bgp {
    asn = 64514
  }
}

# NAT on the main subnetwork
resource "google_compute_router_nat" "vault_nat" {
  name                               = "vault-nat-1"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.vault_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.vault_subnet.name
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }
}



