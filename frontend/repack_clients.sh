#/bin/bash
set -e

true_regex="^(true|True|TRUE)$"
: "${CLIENT_INSTALLER_ROOT:=installers}"

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

function check_if_clients_exist() {
  echo "Checking if clients with specified id already exist."
  objects=$(curl -fs https://www.googleapis.com/storage/v1/b/$CLIENT_INSTALLER_BUCKET/o?prefix=$CLIENT_INSTALLER_ROOT \
    -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN")

  has_items=$(echo "$objects" | grep "items" | wc -l)

  if [[ $has_items -gt 0 ]]; then
    matching=$(echo $objects | jq ".items[].name" | grep $CLIENT_INSTALLER_FINGERPRINT | wc -l)

    if [[ $matching -gt 0 ]]; then
      echo "Clients with fingerprint $CLIENT_INSTALLER_FINGERPRINT already exist in gs://$CLIENT_INSTALLER_BUCKET/$CLIENT_INSTALLER_ROOT"
      echo "Skipping client upload."
      exit 0
    fi
  else 
    echo "gs://$CLIENT_INSTALLER_BUCKET/$CLIENT_INSTALLER_ROOT does not exist or has no objects."
  fi
}

function repack_clients() {
  echo "Repacking clients."

  # https://github.com/google/grr/issues/646 
  $GRR_VENV/bin/grr_config_updater \
    --secondary_configs /etc/grr/server.local.yaml \
    -p Client.executable_signing_public_key="$(cat $FRONTEND_PUBLIC_SIGNING_KEY_PATH)" \
    -p CA.certificate="$(cat $CA_CERT_PATH)" \
    -p Client.server_urls="http://$CLIENT_PACKING_FRONTEND_HOST:$FRONTEND_SERVER_PORT/" \
    repack_clients
}

function upload_gcs_object() {
  printf "\nUploading file $1 to gs://$CLIENT_INSTALLER_BUCKET/$CLIENT_INSTALLER_ROOT/$2\n"

  curl -fX POST --data-binary @"$1" \
    -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN" \
    "https://www.googleapis.com/upload/storage/v1/b/$CLIENT_INSTALLER_BUCKET/o?uploadType=media&name=$CLIENT_INSTALLER_ROOT%2F$2" \
    > /dev/null
}

function delete_gcs_object() {
  printf "\nDeleting gs://$CLIENT_INSTALLER_BUCKET/$CLIENT_INSTALLER_ROOT/$1\n"

  curl -sX DELETE \
    -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN" \
    "https://www.googleapis.com/storage/v1/b/$CLIENT_INSTALLER_BUCKET/o/$CLIENT_INSTALLER_ROOT%2F$1" \
    > /dev/null
}

function upload_clients() {
  pushd ${GRR_INSTALLERS_DIR:-/usr/share/grr-server/executables/installers} > /dev/null

  # Find and upload all installers and update their 
  # latest "pointer" copy. This is so clients can always
  # grab the latest installer without having to change 
  # configuration logic

  installers=$(find . -regextype sed -regex ".*/\(grr\|GRR\)_.*\.\(deb\|rpm\|pkg\|exe\)" -printf "%f\n")
  regex="^([a-zA-Z]*)_[0-9\.]*_([a-z0-9]*)_.*\.(.*)$"

  for installer in $installers
  do
    if [[ $installer =~ $regex ]]; then
      name="${BASH_REMATCH[1]}"
      arch="${BASH_REMATCH[2]}"
      ext="${BASH_REMATCH[3]}"

      # Upload the installer
      upload_gcs_object $installer $installer

      # Update the latest "pointer" copy
      upload_gcs_object $installer "$name-latest-$arch.$ext"
    fi
  done

  popd > /dev/null
}

check_installed jq
check_installed curl

if [[ $NO_CLIENT_REPACK =~ $true_regex ]]; then
  echo "NO_CLIENT_REPACK=$NO_CLIENT_REPACK. Skipping client repacking."
  exit 0
fi;

if [[ -z $SERVICE_ACCOUNT_TOKEN ]]  && [[ ! $NO_CLIENT_UPLOAD =~ $true_regex ]]; then
  echo "Access token not provided. Proceeding as GCE default service account."
  get_default_access_token
fi

if [[ ! $FORCE_CLIENT_UPLOAD =~ $true_regex ]] && [[ ! $NO_CLIENT_UPLOAD =~ $true_regex ]]; then
  check_if_clients_exist

  # Upload a dummy file to let other frontends know that 
  # repacking is in progress
  echo "Uploading lock file."
  upload_gcs_object /dev/null $CLIENT_INSTALLER_FINGERPRINT.lock
  lock_file_uploaded=true
fi

repack_clients

if [[ $FORCE_CLIENT_UPLOAD =~ $true_regex ]] || [[ ! $NO_CLIENT_UPLOAD =~ $true_regex ]]; then
  upload_clients
fi

if [[ $lock_file_uploaded == true ]]; then
  echo "Deleting lock file"
  delete_gcs_object $CLIENT_INSTALLER_FINGERPRINT.lock
fi
