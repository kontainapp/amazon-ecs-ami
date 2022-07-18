#!/usr/bin/env bash
set -ex

curl -L -o kontain_bin.tar.gz "https://muth-scratch.s3.amazonaws.com/kontain_bin.tar.gz"
sudo mkdir /kontain_bin
sudo tar -xvf kontain_bin.tar.gz -C /kontain_bin
rm kontain_bin.tar.gz

# Install KM Binaries
sudo mkdir -p /opt/kontain/bin
sudo cp /kontain_bin/km/km /opt/kontain/bin/km
sudo cp /kontain_bin/container-runtime/krun-label-trigger /opt/kontain/bin/krun-label-trigger

# Compile and install kkm driver
echo "build and install KKM driver"
sudo /kontain_bin/kkm.run
