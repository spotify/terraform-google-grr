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
