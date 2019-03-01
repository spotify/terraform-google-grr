variable "dns_zone_name" {
  description = "The name of the managed DNS zone for GRR"
}

variable "dns_zone_fqdn" {
  description = "The FQDN of the managed DNS zone for GRR"
}

variable "dns_default_ttl" {
  description = "The default TTL for DNS records in seconds"
  default     = 300
}

resource "google_dns_record_set" "frontend" {
  # If you change this, you MUST update CLIENT_PACKING_FRONTEND_HOST

  name         = "frontend.${var.dns_zone_fqdn}"
  managed_zone = "${var.dns_zone_name}"
  type         = "A"
  ttl          = "${var.dns_default_ttl}"

  rrdatas = ["${google_compute_global_address.grr_frontend_lb.address}"]
}

resource "google_dns_record_set" "grr" {
  name         = "${var.dns_zone_fqdn}"
  managed_zone = "${var.dns_zone_name}"
  type         = "A"
  ttl          = "${var.dns_default_ttl}"

  rrdatas = ["${google_compute_global_address.grr_adminui_lb.address}"]
}

output "frontend_fqdn" {
  value = "${google_dns_record_set.frontend.name}"
}
