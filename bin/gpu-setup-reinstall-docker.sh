#!/bin/bash

while true; do
  if [ -f /var/cache/kubernetes-install/nodeup_done ]; then
    echo "Nodeup processing done"
    break
  fi
  echo "Waiting for nodeup to finish"
  sleep 30
done

# Add apt repository for nvidia-drivers
echo "Add apt repository for nvidia-drivers"
add-apt-repository ppa:graphics-drivers/ppa -y

apt-get update -y

# Install nvidia-drivers
echo "Install nvidia-drivers"
apt install -y nvidia-384 nvidia-settings

echo "======================================================================"
# Remove previous docker versions
echo "Remove previous docker versions"
apt-get purge -y docker docker-ce docker.io docker-engine
rm -rf /var/lib/docker

echo "======================================================================"
# Add docker and related apt repositories
echo "Add docker and related apt repositories"
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add Docker’s official GPG key
echo "Add Docker’s official GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add docker apt repository
echo "Add docker apt repository"
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

echo "======================================================================"
# Install nvidia-docker2
echo "Install nvidia-docker2"
curl -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
tee /etc/apt/sources.list.d/nvidia-docker.list <<< \
"deb https://nvidia.github.io/libnvidia-container/ubuntu16.04/amd64 /
deb https://nvidia.github.io/nvidia-container-runtime/ubuntu16.04/amd64 /
deb https://nvidia.github.io/nvidia-docker/ubuntu16.04/amd64 /"
apt-get update -y
apt-get install -y nvidia-docker2

echo "======================================================================"

# Install new docker version
echo "Install new docker version"
apt-get install -y docker-ce=17.09.0~ce-0~ubuntu

echo "======================================================================"
sleep 60
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

echo "Restarting dockerd"
pkill -SIGHUP dockerd
