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

#!/bin/sh

echo "CLOUD_BACKEND_SERVICE_ID: $CLOUD_BACKEND_SERVICE_ID"
echo "CLOUD_BACKEND_SERVICE_NAME: $CLOUD_BACKEND_SERVICE_NAME"
echo "CLOUD_PROJECT_NAME: $CLOUD_PROJECT_NAME"
echo "CLOUD_PROJECT_ID: $CLOUD_PROJECT_ID"

#Bootstraps the user, makes it admin, and starts the server
$GRR_VENV/bin/grr_config_updater \
    --secondary_configs /etc/grr/server.local.yaml \
    delete_user $ADMIN_USER

$GRR_VENV/bin/grr_config_updater \
    --secondary_configs /etc/grr/server.local.yaml \
    add_user \
    --admin \
    --password $ADMIN_PASSWORD $ADMIN_USER

$GRR_VENV/bin/grr_server \
    --component admin_ui \
    --secondary_configs /etc/grr/server.local.yaml 
