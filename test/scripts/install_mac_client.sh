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
