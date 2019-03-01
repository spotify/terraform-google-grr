variable "gce_region" {
  description = "Region to deploy GCE assets to"
}

variable "gce_project" {
  description = "Project name to deploy assests to"
}

variable "gce_project_id" {
  description = "Project id for project specified in $gce_project"
}

provider "google" {
  project = "${var.gce_project}"
  region  = "${var.gce_region}"
  version = "1.20.0"
}
