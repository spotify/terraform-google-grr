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

#/bin/bash

# Make sure we have everything we need
: "${CA_CERT:?CA_CERT must be set}"
: "${CA_CERT_PATH:?CA_CERT_PATH must be set}"
: "${CA_PRIVATE_KEY:?CA_PRIVATE_KEY must be set}"
: "${CA_PRIVATE_KEY_PATH:?CA_PRIVATE_KEY_PATH must be set}"

# Decode and write to file
echo "$CA_CERT" | base64 -d > $CA_CERT_PATH
echo "$CA_PRIVATE_KEY" | base64 -d > $CA_PRIVATE_KEY_PATH
