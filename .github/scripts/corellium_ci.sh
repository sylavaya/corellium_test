#!/bin/bash

set -euo pipefail

echo "Waiting for the VM to become reachable..."

until sshpass -p "$VM_PASSWORD" ssh \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -J "$SSH_PROXY" \
    "$VM_USER@$VM_IP" \
    "echo ready" >/dev/null 2>&1
do
    echo "VM not ready yet..."
    sleep 10
done

echo "VM is ready."

sshpass -p "$VM_PASSWORD" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -J "$SSH_PROXY" \
    "$VM_USER@$VM_IP" <<'EOF'
echo "Hello World!"
hostname
uname -a
EOF
