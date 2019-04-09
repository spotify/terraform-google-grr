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

variable "gce_project_id" {
  description = "Project id for project specified in $gce_project"
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
