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

variable "grr_worker_image" {
  description = "Docker image to run for GRR worker"
}

variable "grr_worker_image_tag" {
  description = "Docker image tag to pull of image specified by grr_worker_image"
}

variable "grr_worker_monitoring_port" {
  description = "GRR worker monitoring stats port"
  default     = 5222
}

variable "grr_worker_target_size" {
  description = "The number of GRR worker instances that should always be running"
  default     = 5
}

variable "grr_worker_machine_type" {
  description = "The machine type to spawn for the worker instance group"
  default     = "n1-standard-1"
}

module "grr_worker_container" {
  # Pin module for build determinism
  source = "github.com/terraform-google-modules/terraform-google-container-vm?ref=f299e4c3b13a987482f830489222006ef85075ed"

  container = {
    image = "${var.grr_worker_image}:${var.grr_worker_image_tag}"

    env = [
      {
        name  = "MONITORING_HTTP_PORT"
        value = "${var.grr_worker_monitoring_port}"
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
        name  = "CA_CERT"
        value = "${base64encode(tls_self_signed_cert.frontend_ca.cert_pem)}"
      },
      {
        name  = "CA_PRIVATE_KEY"
        value = "${base64encode(tls_private_key.frontend_ca.private_key_pem)}"
      },
    ]
  }

  restart_policy = "Always"
}

resource "random_id" "worker_instance_config" {
  keepers = {
    # Automatically generate a new id if OS image or container config changes
    container_os_image   = "${module.grr_worker_container.vm_container_label}"
    container_definition = "${module.grr_worker_container.metadata_value}"
  }

  byte_length = 2
}

resource "google_compute_instance_template" "grr_worker" {
  # Workers may need to be reprovisioned if frontend keys change
  name        = "grr-worker-${random_id.client_installer_fingerprint.dec}-${random_id.worker_instance_config.hex}"
  description = "Managed by Terraform. DO NOT EDIT. Describes how to provision an independent GRR worker."

  tags = [
    "allow-health-checks",
  ]

  labels {
    "container-vm" = "${module.grr_worker_container.vm_container_label}"
  }

  metadata {
    "gce-container-declaration" = "${module.grr_worker_container.metadata_value}"
    "google-logging-enabled"    = "true"

    # Case sesitive
    "enable-oslogin" = "TRUE"
  }

  machine_type = "n1-standard-1"

  disk {
    boot         = true
    source_image = "${module.grr_worker_container.source_image}"
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

resource "google_compute_health_check" "grr_worker_autohealing" {
  name = "grr-worker-autohealing"

  timeout_sec        = 10
  check_interval_sec = 10

  # Workers don't expose any ports, so we assume
  # if the monitoring stats server is up, then
  # the worker is healthy
  tcp_health_check {
    port = "${var.grr_worker_monitoring_port}"
  }
}

resource "google_compute_instance_group_manager" "grr_workers" {
  name        = "grr-workers"
  description = "Managed by Terraform. DO NOT EDIT. Group manager for GRR workers."

  base_instance_name = "grr-worker"

  instance_template = "${google_compute_instance_template.grr_worker.self_link}"

  update_strategy = "ROLLING_UPDATE"

  rolling_update_policy {
    type              = "PROACTIVE"
    minimal_action    = "RESTART"
    max_surge_percent = 100
    min_ready_sec     = 20
  }

  target_size = "${var.grr_worker_target_size}"

  # TODO Make region automatic
  zone = "${var.gce_region}-b"

  auto_healing_policies {
    health_check      = "${google_compute_health_check.grr_worker_autohealing.self_link}"
    initial_delay_sec = 60
  }
}
