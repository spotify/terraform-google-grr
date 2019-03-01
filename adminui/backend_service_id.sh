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
set -e

function check_installed() {
  set +e
  command -v $1 > /dev/null
  if [[ $? -gt 0 ]]; then
    echo "Error: $1 is not installed."
    exit 1
  fi;
  set -e
}

function get_default_access_token {
  local response=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" \
      -H "Metadata-Flavor: Google" 
    );

  if [[ -z $response ]]; then
    echo "Error: Could not get default access token"
    exit 1;
  fi

  SERVICE_ACCOUNT_TOKEN=$(echo $response | jq -r ".access_token")
}

function get_project_name {
  local response=$(curl -fs "https://cloudresourcemanager.googleapis.com/v1/projects/$1" \
    -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN")
  if [[ -z $response ]]; then
    echo "Error: Could not get project name"
    exit 1;
  fi

  CLOUD_PROJECT_NAME=$(echo $response | jq -r ".name")
}

function get_backend_service_id {
  local response=$(curl -fs "https://www.googleapis.com/compute/v1/projects/$1/global/backendServices/$2" \
    -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN")

  if [[ -z $response ]]; then
    echo "Error: Could not get id for backend service $2"
    exit 1;
  fi

  echo $response | jq -r ".id"
}

if [[ ! $ADMINUI_WEBAUTH_MANAGER =~ "IAPWebAuthManager" ]]; then
  exit 0;
fi;

if [[ ! -z $CLOUD_BACKEND_SERVICE_ID ]]; then
  exit 0
fi;

if [[ -z $CLOUD_PROJECT_NAME ]] && [[ -z $CLOUD_PROJECT_ID ]]; then
  echo "To retrieve backend service id, CLOUD_PROJECT_NAME or CLOUD_PROJECT_ID must be set."
  exit 1
fi;

if [[ -z $CLOUD_BACKEND_SERVICE_NAME ]]; then
  echo "CLOUD_BACKEND_SERVICE_NAME must be set if CLOUD_BACKEND_SERVICE_ID is not set."
  exit 1;
fi;

check_installed jq
check_installed curl

if [[ -z $SERVICE_ACCOUNT_TOKEN ]]; then
  get_default_access_token
fi

if [[ -z $CLOUD_PROJECT_NAME ]] && [[ ! -z $CLOUD_PROJECT_ID ]]; then
  get_project_name $CLOUD_PROJECT_ID
fi;

get_backend_service_id $CLOUD_PROJECT_NAME $CLOUD_BACKEND_SERVICE_NAME
