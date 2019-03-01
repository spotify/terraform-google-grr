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
