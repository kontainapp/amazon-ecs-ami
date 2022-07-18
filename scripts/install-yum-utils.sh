#!/usr/bin/env bash
set -ex

# install yum-utils which contains needs-restarting to check if a reboot is necessary after update
sudo yum install -y yum-utils
sudo yum update -y

# check if it needs rebooting while yum not running
# ensure that cloud-init runs again after reboot by removing the instance record created
sudo rm -rf /var/lib/cloud/instances/
sudo reboot
