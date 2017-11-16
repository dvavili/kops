#!/bin/bash

echo "Sleeping for 300s"
sleep 300
echo "Resuming nvidia-docker-setup.sh"

# Add apt repository for nvidia-drivers
echo "Add apt repository for nvidia-drivers"
add-apt-repository ppa:graphics-drivers/ppa -y

apt-get update -y

# Install nvidia-drivers
echo "Install nvidia-drivers"
apt install -y nvidia-384 nvidia-settings

# Install nvidia-docker2
curl -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
tee /etc/apt/sources.list.d/nvidia-docker.list <<< \
"deb https://nvidia.github.io/libnvidia-container/ubuntu16.04/amd64 /
deb https://nvidia.github.io/nvidia-container-runtime/ubuntu16.04/amd64 /
deb https://nvidia.github.io/nvidia-docker/ubuntu16.04/amd64 /"
apt-get update -y

# docker override
echo "docker override"
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF

echo "Install nvidia-docker2"
apt-get install -y nvidia-docker2

echo "Restarting dockerd"
pkill -SIGHUP dockerd
