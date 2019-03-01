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

