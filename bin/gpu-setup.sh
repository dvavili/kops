#!/bin/bash

while true; do
  if [ -f /var/cache/kubernetes-install/nodeup_done ]; then
    echo "Nodeup processing done"
    break
  fi
  echo "Waiting for nodeup to finish"
  sleep 30
done

echo "======================================================================"
# Add apt repository for nvidia-drivers
echo "Add apt repository for nvidia-drivers"
add-apt-repository ppa:graphics-drivers/ppa -y

apt-get update -y

# Install nvidia-drivers
echo "Install nvidia-drivers"
apt install -y nvidia-384 nvidia-settings

nvidia-smi > drivers_setup_done

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
echo "Install nvidia-docker2 and awscli"
curl -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
tee /etc/apt/sources.list.d/nvidia-docker.list <<< \
"deb https://nvidia.github.io/libnvidia-container/ubuntu16.04/amd64 /
deb https://nvidia.github.io/nvidia-container-runtime/ubuntu16.04/amd64 /
deb https://nvidia.github.io/nvidia-docker/ubuntu16.04/amd64 /"
apt-get update -y
apt-get install -y nvidia-docker2
apt-get install -y awscli # Required for AWS configuration for ECR access

echo "======================================================================"
# Override docker default-runtime
echo "Override docker default-runtime"
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

sleep 10
pkill -SIGHUP kubelet

touch ./gpu_setup_done
