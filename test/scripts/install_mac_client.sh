BASEDIR=$(dirname "$0")
MAC_INSTALLER=$BASEDIR/../installers/*.pkg
LABEL_FILE=/etc/grr.labels.yaml

echo  "Mac installer requires sudo. You may be prompted."

echo "\nWriting label file into $LABEL_FILE"
cat << EOF |
Client.labels:
  - test
  - local
  - mac
EOF
sudo tee $LABEL_FILE

sudo installer -pkg $MAC_INSTALLER -target /

if [[ $? -gt 0 ]]; then
  echo "\nInstallation failed! Here's the installation log:"
  cat /var/log/grr_installer.txt
  exit 1;
fi;
