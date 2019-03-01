resource "google_compute_network" "grr_network" {
  name                    = "grr-network"
  auto_create_subnetworks = false
  description             = "Managed by Terraform. DO NOT EDIT. Network created exclusively for GRR and its components."
}

resource "google_compute_subnetwork" "grr_subnet" {
  name                     = "grr-subnet"
  ip_cidr_range            = "192.168.1.0/24"
  region                   = "${var.gce_region}"
  network                  = "${google_compute_network.grr_network.self_link}"
  description              = "Managed by Terraform. DO NOT EDIT. Subnet used to house GRR instances for the specified region."
  private_ip_google_access = true
}

resource "google_compute_global_address" "grr_frontend_lb" {
  name        = "grr-frontend-lb"
  description = "Managed by Terraform. DO NOT EDIT. Reserved IP address for GRR Frontend end load balancer."
}

resource "google_compute_global_address" "grr_adminui_lb" {
  name        = "grr-adminui-lb"
  description = "Managed by Terraform. DO NOT EDIT. Reserved IP address for GRR Admin UI."
}

resource "google_compute_firewall" "grr_default" {
  name    = "grr-default"
  network = "${google_compute_network.grr_network.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "grr_allow_health_checks" {
  name    = "grr-allow-health-checks"
  network = "${google_compute_network.grr_network.self_link}"

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  target_tags = ["allow-health-checks"]
}

resource "google_compute_firewall" "grr_frontend" {
  name    = "grr-frontend"
  network = "${google_compute_network.grr_network.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["${var.grr_frontend_port}", "${var.grr_frontend_monitoring_port}"]
  }

  target_tags = ["${var.grr_frontend_network_tag}"]
}

output "frontend_lb_address" {
  value = "${google_compute_global_address.grr_frontend_lb.address}"
}
