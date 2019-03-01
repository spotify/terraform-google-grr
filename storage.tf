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

variable "client_installers_bucket_root" {
  description = "The root directory where grr client installers should be uploaded to in the client installer bucket"
  default     = "installers"
}

variable "database_version" {
  description = "The version of MySQL that CloudSQL supports"
  default = "MYSQL_5_7"
}

variable "database_tier" {
  description = "Database deployment tier (machien type)"
  default = "db-n1-standard-4"
}

variable "storage_access_logs_bucket_name" {
  description = "Name of the GCS bucket that will store access logs. Needs to be globally unique"
}

variable "client_installers_bucket_name" {
  description = "Name of the GCS bucket that will store generated grr client installers. Needs to be globally unique"
}

variable "gcs_bucket_location" {
  description = "Location of buckets to be created"
  default = "US"
}

resource "google_sql_database_instance" "grr_db" {
  name             = "grr-db-instance-${random_string.database_name_suffix.result}"
  region           = "${var.gce_region}"
  database_version = "${var.database_version}"

  settings {
    tier = "${var.database_tier}"

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "only-for-testing-delete-me"
        value = "0.0.0.0/0"
      }
    }

    database_flags {
      # Artifacts can get very heavy so we set to max size of 1 GB
      name  = "max_allowed_packet"
      value = "1073741824"
    }
  }
}

resource "google_sql_database" "grr_db" {
  name     = "grr-db"
  instance = "${google_sql_database_instance.grr_db.name}"
}

resource "random_string" "grr_user_password" {
  # Make the password extra spicy
  length      = 32
  special     = true
  min_upper   = 8
  min_lower   = 8
  min_numeric = 8
  min_special = 8
}

resource "random_string" "database_name_suffix" {
  length = 4
  special = false
}

resource "google_sql_user" "grr_user" {
  name     = "grr"
  password = "${random_string.grr_user_password.result}"
  instance = "${google_sql_database_instance.grr_db.name}"
}

resource "google_storage_bucket" "access_logs" {
  name     = "${var.storage_access_logs_bucket_name}"
  location = "${var.gcs_bucket_location}"
}

resource "google_storage_bucket" "client_installers" {
  name          = "${var.client_installers_bucket_name}"
  location = "${var.gcs_bucket_location}"
  force_destroy = true

  logging {
    log_bucket = "${google_storage_bucket.access_logs.name}"
  }
}

output "grr_db_ip" {
  value = "${google_sql_database_instance.grr_db.ip_address.0.ip_address}"
}

output "grr_db_user" {
  value = "${google_sql_user.grr_user.name}"
}

output "grr_db_user_password" {
  value     = "${random_string.grr_user_password.result}"
  sensitive = true
}

output "grr_client_installers_bucket" {
  value = "${google_storage_bucket.client_installers.name}"
}
