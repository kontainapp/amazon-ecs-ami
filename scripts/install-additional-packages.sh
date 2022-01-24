#!/usr/bin/env bash
set -ex

ARCH=$(uname -m)

# install any rpm packages from the additional-packages/ directory
sudo yum localinstall -y /tmp/additional-packages/*."${ARCH}".rpm

uname -a
################################################################################
### Kontain ########################################################################
###############################################################################
echo "Pulling Kontain binary release"
curl -L -o kontain_bin.tar.gz  "https://github.com/kontainapp/km/releases/download/v0.9.4/kontain_bin.tar.gz"
sudo mkdir /kontain_bin
sudo tar -xvf kontain_bin.tar.gz -C /kontain_bin
rm kontain_bin.tar.gz

# Hack. Get kkm.run from s3 until we get it back in release. URL expires on 1/24/2021.
curl -L -o kkm.run  "https://muth-scratch.s3.amazonaws.com/kkm.run"
sudo mv kkm.run /kontain_bin/kkm.run
sudo chmod +x  /kontain_bin/kkm.run
# Back to mainline.

# Install kkm driver
echo "build and install KKM driver"
sudo /kontain_bin/kkm.run

# Install KM Binaries
sudo mkdir -p /opt/kontain/bin
sudo cp /kontain_bin/km/km /opt/kontain/bin/km
sudo cp /kontain_bin/container-runtime/krun /opt/kontain/bin/krun
sudo cp /kontain_bin/cloud/k8s/deploy/shim/containerd-shim-krun-v2 /usr/bin/containerd-shim-krun-v2
