#!/usr/bin/env bash
set -ex

ARCH=$(uname -m)

# install any rpm packages from the additional-packages/ directory
sudo yum localinstall -y /tmp/additional-packages/*."${ARCH}".rpm

################################################################################
### Kontain ########################################################################
###############################################################################

# Install KM Binaries
echo "install kontain binaries"
sudo mkdir -p /opt/kontain/bin
sudo cp /kontain_bin/km/km /opt/kontain/bin/km
sudo cp /kontain_bin/container-runtime/krun-label-trigger /opt/kontain/bin/krun-label-trigger
sudo cp /kontain_bin/cloud/k8s/deploy/shim/containerd-shim-krun-v2 /usr/bin/containerd-shim-krun-v2

cat << EOT | sudo tee /etc/docker/daemon.json
{
    "default-runtime": "krun",
    "runtimes": {
        "krun": {
            "path": "/opt/kontain/bin/krun-label-trigger"
        }
    }
}
EOT

# Remove install directory
# sudo rm -rf /kontain_bin
