output "packer_subnetwork" {
  value = google_compute_subnetwork.packer_subnet.id
}