#  Copyright 2018-2019 Spotify AB.
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.

variable "grr_frontend_image" {
  description = "Docker image to run for GRR frontend"
}

variable "grr_frontend_image_tag" {
  description = "Docker image tag to pull of image specified by grr_frontend_image"
}

variable "grr_frontend_port" {
  description = "GRR frontend port that clients will connect to"
  default     = 443
}

variable "grr_frontend_monitoring_port" {
  description = "GRR frontend monitoring stats port"
  default     = 5222
}

variable "grr_frontend_network_tag" {
  description = "Firewall network tag to open ports for GRR frontend"
  default     = "grr-frontend"
}

variable "grr_frontend_target_size" {
  description = "The number of GRR Frontend instances that should always be running"
  default     = 3
}

variable "grr_frontend_address" {
  description = "The GRR frontend address. Needs to match the configured DNS record"
}

variable "grr_frontend_machine_type" {
  description = "The machine type to spawn for the frontend instance group"
  default = "n1-standard-1"
}

module "grr_frontend_container" {
  # Pin module for build determinism
  source = "github.com/terraform-google-modules/terraform-google-container-vm?ref=f299e4c3b13a987482f830489222006ef85075ed"

  container = {
    image = "${var.grr_frontend_image}:${var.grr_frontend_image_tag}"

    env = [
      {
        name  = "NO_CLIENT_UPLOAD"
        value = "false"
      },
      {
        name  = "FRONTEND_SERVER_PORT"
        value = "${var.grr_frontend_port}"
      },
      {
        name  = "MONITORING_HTTP_PORT"
        value = "${var.grr_frontend_monitoring_port}"
      },
      {
        name  = "MYSQL_HOST"
        value = "${google_sql_database_instance.grr_db.ip_address.0.ip_address}"
      },
      {
        name  = "MYSQL_PORT"
        value = 3306
      },
      {
        name  = "MYSQL_DATABASE_NAME"
        value = "${google_sql_database.grr_db.name}"
      },
      {
        name  = "MYSQL_DATABASE_USERNAME"
        value = "${google_sql_user.grr_user.name}"
      },
      {
        name  = "MYSQL_DATABASE_PASSWORD"
        value = "${random_string.grr_user_password.result}"
      },
      {
        name  = "CLIENT_PACKING_FRONTEND_HOST"
        value = "${var.grr_frontend_address}"
      },
      {
        name  = "CLIENT_INSTALLER_FINGERPRINT"
        value = "${random_id.client_installer_fingerprint.dec}"
      },
      {
        name  = "FRONTEND_PUBLIC_SIGNING_KEY"
        value = "${base64encode(data.tls_public_key.frontend_executable_signing.public_key_pem)}"
      },
      {
        name  = "CLIENT_INSTALLER_BUCKET"
        value = "${google_storage_bucket.client_installers.name}"
      },
      {
        name  = "CLIENT_INSTALLER_ROOT"
        value = "${var.client_installers_bucket_root}"
      },
      {
        name  = "SERVER_RSA_KEY_LENGTH"
        value = "${var.frontend_rsa_key_length}"
      },
      {
        name  = "FRONTEND_CERT"
        value = "${base64encode(tls_locally_signed_cert.frontend.cert_pem)}"
      },
      {
        name  = "CA_CERT"
        value = "${base64encode(tls_self_signed_cert.frontend_ca.cert_pem)}"
      },
      {
        name  = "FRONTEND_PRIVATE_KEY"
        value = "${base64encode(tls_private_key.frontend.private_key_pem)}"
      },
      {
        name  = "CA_PRIVATE_KEY"
        value = "${base64encode(tls_private_key.frontend_ca.private_key_pem)}"
      },
      {
        name  = "FRONTEND_PRIVATE_SIGNING_KEY"
        value = "${base64encode(tls_private_key.frontend_executable_signing.private_key_pem)}"
      },
    ]
  }

  restart_policy = "Always"
}

resource "random_id" "client_installer_fingerprint" {
  keepers = {
    # Generate a new fingeprint everytime the CA or frontend image changes
    ca_cert            = "${tls_self_signed_cert.frontend_ca.cert_pem}"
    frontend_image     = "${var.grr_frontend_image}"
    frontend_image_tag = "${var.grr_frontend_image_tag}"
  }

  byte_length = 2
}

resource "random_id" "frontend_instance_config" {
  keepers = {
    # Automatically generate a new id if OS image or container config changes
    container_os_image   = "${module.grr_frontend_container.vm_container_label}"
    container_definition = "${module.grr_frontend_container.metadata_value}"
  }

  byte_length = 2
}

resource "google_compute_instance_template" "grr_frontend" {
  name        = "grr-frontend-${random_id.client_installer_fingerprint.dec}-${random_id.frontend_instance_config.hex}"
  description = "Managed by Terraform. DO NOT EDIT. Describes how to provision an independent GRR Frontend."

  tags = [
    "${var.grr_frontend_network_tag}",
    "allow-health-checks",
  ]

  labels {
    "container-vm" = "${module.grr_frontend_container.vm_container_label}"
  }

  metadata {
    "gce-container-declaration" = "${module.grr_frontend_container.metadata_value}"
    "google-logging-enabled"    = "true"

    # Case sensitive
    "enable-oslogin" = "TRUE"
  }

  machine_type = "${var.grr_frontend_machine_type}"

  disk {
    boot         = true
    source_image = "${module.grr_frontend_container.source_image}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.grr_subnet.self_link}"

    # Set up NAT
    access_config {}
  }

  lifecycle {
    create_before_destroy = true
  }

  service_account {
    # TODO specify a locked down service account
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_health_check" "grr_frontend_autohealing" {
  name = "grr-frontend-autohealing"

  timeout_sec        = 10
  check_interval_sec = 10

  tcp_health_check {
    port = "${var.grr_frontend_port}"
  }
}

resource "google_compute_instance_group_manager" "grr_frontends" {
  name        = "grr-frontends"
  description = "Managed by Terraform. DO NOT EDIT. Group manager for GRR frontends."

  base_instance_name = "grr-frontend"

  instance_template = "${google_compute_instance_template.grr_frontend.self_link}"

  update_strategy = "ROLLING_UPDATE"

  rolling_update_policy {
    type              = "PROACTIVE"
    minimal_action    = "RESTART"
    max_surge_percent = 100
    min_ready_sec     = 20
  }

  target_size = "${var.grr_frontend_target_size}"

  # TODO Make region automatic
  zone = "${var.gce_region}-b"

  named_port {
    name = "service"
    port = "${var.grr_frontend_port}"
  }

  named_port {
    name = "monitoring"
    port = "${var.grr_frontend_monitoring_port}"
  }

  auto_healing_policies {
    health_check      = "${google_compute_health_check.grr_frontend_autohealing.self_link}"
    initial_delay_sec = 120
  }
}

resource "google_compute_health_check" "grr_frontend_loadbalancing" {
  name = "grr-frontend-loadbalancing"

  timeout_sec        = 10
  check_interval_sec = 10

  # TODO move onto Stackdriver policy that watches monitoring stats
  tcp_health_check {
    port = "${var.grr_frontend_port}"
  }
}

resource "google_compute_target_tcp_proxy" "grr_frontend" {
  name            = "grr-frontend"
  backend_service = "${google_compute_backend_service.grr_frontend.self_link}"
}

resource "google_compute_target_tcp_proxy" "grr_frontend_monitoring" {
  name            = "grr-frontend-monitoring"
  backend_service = "${google_compute_backend_service.grr_frontend_monitoring.self_link}"
}

resource "google_compute_global_forwarding_rule" "grr_frontend" {
  name       = "grr-frontend"
  target     = "${google_compute_target_tcp_proxy.grr_frontend.self_link}"
  port_range = "${var.grr_frontend_port}"
  ip_address = "${google_compute_global_address.grr_frontend_lb.address}"
}

resource "google_compute_global_forwarding_rule" "grr_frontend_monitoring" {
  name       = "grr-frontend-monitoring"
  target     = "${google_compute_target_tcp_proxy.grr_frontend_monitoring.self_link}"
  port_range = "${var.grr_frontend_monitoring_port}"
  ip_address = "${google_compute_global_address.grr_frontend_lb.address}"
}

resource "google_compute_backend_service" "grr_frontend" {
  name          = "grr-frontend"
  description   = "Managed by Terraform. DO NOT EDIT. GRR frontend backend service for responding to clients"
  port_name     = "service"
  protocol      = "TCP"
  health_checks = ["${google_compute_health_check.grr_frontend_loadbalancing.self_link}"]

  backend {
    group = "${google_compute_instance_group_manager.grr_frontends.instance_group}"
  }
}

resource "google_compute_backend_service" "grr_frontend_monitoring" {
  name          = "grr-frontend-monitoring"
  description   = "Managed by Terraform. DO NOT EDIT. GRR frontend backend service for monitoring"
  port_name     = "monitoring"
  protocol      = "TCP"
  health_checks = ["${google_compute_health_check.grr_frontend_loadbalancing.self_link}"]

  backend {
    group = "${google_compute_instance_group_manager.grr_frontends.instance_group}"
  }
}

output "client_fingerprint" {
  value = "${random_id.client_installer_fingerprint.dec}"
}
