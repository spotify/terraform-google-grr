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
