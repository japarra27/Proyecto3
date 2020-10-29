# show external ip address of load balancer
output "load-balancer-ip-address" {
  value = google_compute_global_forwarding_rule.global_forwarding_rule.ip_address
}
