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
    sleep 20
done

echo "VM is ready."

sshpass -p "$VM_PASSWORD" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -J "$SSH_PROXY" \
    "$VM_USER@$VM_IP" <<EOF

export CORELLIUM_HOST="${CORELLIUM_HOST}"
export CORELLIUM_TOKEN="${CORELLIUM_TOKEN}api"

mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat > ~/.ssh/id_ed25519 <<KEY
$DEPLOY_KEY_GITHUB
KEY

chmod 600 ~/.ssh/id_ed25519

ssh-keyscan github.com >> ~/.ssh/known_hosts

ssh -T git@github.com || true

git clone git@github.com:sylavaya/ppc_test.git

cd ~/ppc_test/vlabs-SiL

./vlabs-SiL.sh select -n SK_S32K344

./vlabs-SiL.sh test logs test_voltage_off

cd ..

python3 test_mail.py

echo "Pipeline completed successfully."

EOF
