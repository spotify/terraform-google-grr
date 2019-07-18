variable "client_installers_bucket_root" {
  description = "The root directory where grr client installers should be uploaded to in the client installer bucket"
  default     = "installers"
}

variable "gce_region" {
  description = "Region to deploy GCE assets to"
}

variable "gce_project" {
  description = "Project name to deploy assests to"
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

variable "grr_frontend_address" {
  description = "The GRR frontend address. Needs to match the configured DNS record"
}

variable "grr_adminui_image" {
  description = "Docker image to run for GRR adminui"
}

variable "grr_adminui_image_tag" {
  description = "Docker image tag to pull of image specified by grr_adminui_image"
}

variable "grr_adminui_port" {
  description = "GRR AdminUI port that clients will connect to"
  default     = 443
}

variable "grr_adminui_monitoring_port" {
  description = "GRR AdminUI monitoring stats port"
  default     = 5222
}

variable "grr_adminui_network_tag" {
  description = "Firewall network tag to open ports for GRR admin UI"
  default     = "grr-adminui"
}

variable "grr_adminui_target_size" {
  description = "The number of GRR AdminUI instances that should always be running"
  default     = 2
}

variable "grr_adminui_iap_client_id" {
  description = "The OAuth2 Client id for the previously set up IAP Credential"
}

variable "grr_adminui_iap_client_secret" {
  # We rely on the redirect_uri being hard to compromise and accept the risk of client secret leaking
  description = "The OAuth2 Client secret for the previously set up IAP Credential"
}

variable "grr_adminui_machine_type" {
  description = "The machine type to spawn for the adminui instance group"
  default     = "n1-standard-1"
}

variable "grr_adminui_external_hostname" {
  description = "This is the hostname that users will access the GRR AdminUI from. Usually the DNS name configured."
}

variable "grr_adminui_keyring_name" {
  description = "The name of the GKS keyring that houses the key used to encrypt SSL certificate"
}

variable "grr_adminui_key_name" {
  description = "The name of the key wihtin the specified keyring that was used to ecnrypt SSL certificate"
}

variable "_admin_ui_backend_service_name" {
  description = "Needed to break dependency cycle. Do not change."
  default     = "grr-adminui"
}

variable "grr_adminui_username" {
  description = "The GRR adminUI username"
  default     = "root"
}

variable "grr_ca_cn" {
  description = "Common name for internal CA"
}

variable "frontend_cn" {
  description = "Common name to use frotend certificate"
}

variable "grr_ca_org" {
  description = "Organization for internal CA"
}

variable "grr_ca_country" {
  description = "Country for internal CA"
}

variable "frontend_rsa_key_length" {
  default = 2048
}

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

variable "grr_frontend_image" {
  description = "Docker image to run for GRR frontend"
}

variable "grr_frontend_image_tag" {
  description = "Docker image tag to pull of image specified by grr_frontend_image"
}

variable "grr_frontend_target_size" {
  description = "The number of GRR Frontend instances that should always be running"
  default     = 3
}

variable "grr_frontend_machine_type" {
  description = "The machine type to spawn for the frontend instance group"
  default     = "n1-standard-1"
}

variable "database_version" {
  description = "The version of MySQL that CloudSQL supports"
  default     = "MYSQL_5_7"
}

variable "database_tier" {
  description = "Database deployment tier (machien type)"
  default     = "db-n1-standard-4"
}

variable "storage_access_logs_bucket_name" {
  description = "Name of the GCS bucket that will store access logs. Needs to be globally unique"
}

variable "client_installers_bucket_name" {
  description = "Name of the GCS bucket that will store generated grr client installers. Needs to be globally unique"
}

variable "gcs_bucket_location" {
  description = "Location of buckets to be created"
  default     = "US"
}

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
