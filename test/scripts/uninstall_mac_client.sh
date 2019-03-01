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

echo "Killing running grr processes"
sudo pkill grr

echo "\nRemoving label file"
sudo rm /etc/grr.labels.yaml

echo "\nRemoving binaries"
sudo rm -rf /usr/local/lib/grr

echo "\nRemoving server config file"
sudo rm /etc/grr.local.yaml

echo "\nRemoving installer log"
sudo rm /var/log/grr_installer.txt

echo "\nRemoving launch daemon"
sudo rm -rf /Library/LaunchDaemons/com.google.code.grr.plist

