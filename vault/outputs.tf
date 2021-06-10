output "lb_address" {
  value = google_compute_forwarding_rule.external.ip_address
}

output "lb_port" {
  value = local.vault_port
}