#!/bin/bash
# Install nvidia-container-toolkit for Docker GPU access
# Run with: sudo bash /home/vision/.openclaw/workspace/install-chatterbox-deps.sh

set -e

echo "=== Installing nvidia-container-toolkit ==="

# Add NVIDIA repo
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update -qq
apt-get install -y nvidia-container-toolkit

# Configure Docker runtime
nvidia-ctk runtime configure --runtime=docker

# Restart Docker
systemctl restart docker

echo "=== Done! Testing GPU in Docker ==="
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

echo "=== nvidia-container-toolkit installed successfully ==="
