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

data "tls_public_key" "frontend_executable_signing" {
  private_key_pem = "${tls_private_key.frontend_executable_signing.private_key_pem}"
}

resource "tls_private_key" "frontend" {
  algorithm = "RSA"
  rsa_bits  = "${var.frontend_rsa_key_length}"
}

resource "tls_private_key" "frontend_ca" {
  algorithm = "RSA"
  rsa_bits  = "${var.frontend_rsa_key_length}"
}

resource "tls_private_key" "frontend_executable_signing" {
  algorithm = "RSA"
  rsa_bits  = "${var.frontend_rsa_key_length}"
}

resource "tls_self_signed_cert" "frontend_ca" {
  key_algorithm         = "${tls_private_key.frontend_ca.algorithm}"
  private_key_pem       = "${tls_private_key.frontend_ca.private_key_pem}"
  is_ca_certificate     = true
  validity_period_hours = "${365 * 3 * 24}"

  subject {
    common_name  = "${var.grr_ca_cn}"
    organization = "${var.grr_ca_org}"
    country      = "${var.grr_ca_country}"
  }

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "tls_cert_request" "frontend_csr" {
  key_algorithm   = "${tls_private_key.frontend.algorithm}"
  private_key_pem = "${tls_private_key.frontend.private_key_pem}"

  subject {
    common_name  = "${var.frontend_cn}"
    organization = "${var.grr_ca_org}"
    country      = "${var.grr_ca_country}"
  }
}

resource "tls_locally_signed_cert" "frontend" {
  cert_request_pem   = "${tls_cert_request.frontend_csr.cert_request_pem}"
  ca_key_algorithm   = "${tls_private_key.frontend_ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.frontend_ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.frontend_ca.cert_pem}"

  validity_period_hours = "${365 * 2 * 24}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
  ]
}
