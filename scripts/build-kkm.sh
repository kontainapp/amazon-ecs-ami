#!/usr/bin/env bash

readonly storage="/tmp"

INSTALL_DIR="/opt/kontain"
sudo mkdir -p ${INSTALL_DIR}

sudo tar -xf ${storage}/kontain_bin.tar.gz -C ${INSTALL_DIR}

# Compile and install kkm driver
echo "build and install KKM driver"
sudo chmod +x ${INSTALL_DIR}/bin/kkm.run
sudo ${INSTALL_DIR}/bin/kkm.run

# Install KM Binaries
sudo cp ${INSTALL_DIR}/shim/containerd-shim-krun-v2 /usr/bin/containerd-shim-krun-v2
