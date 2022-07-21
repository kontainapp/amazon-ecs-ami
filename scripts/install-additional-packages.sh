#!/usr/bin/env bash
set -ex

ARCH=$(uname -m)


# install any rpm packages from the additional-packages/ directory
sudo yum localinstall -y /tmp/additional-packages/*."${ARCH}".rpm

################################################################################
### Kontain ########################################################################
###############################################################################

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
