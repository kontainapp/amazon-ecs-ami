#!/usr/bin/env bash
s
readonly storage="/tmp"

INSTALL_DIR="/opt/kontain/bin"

sudo tar -xf ${storage}/kontain_bin.tar.gz  -C ${storage}

# Compile and install kkm driver
echo "build and install KKM driver"
sudo ${storage}/kkm.run

# Install KM Binaries
sudo mkdir -p ${INSTALL_DIR}
sudo cp ${storage}/km/km ${INSTALL_DIR}/km
sudo cp ${storage}/container-runtime/krun-label-trigger ${INSTALL_DIR}/krun-label-trigger
sudo cp ${storage}/cloud/k8s/deploy/shim/containerd-shim-krun-v2 /usr/bin/containerd-shim-krun-v2