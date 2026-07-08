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
export VM_PASSWORD="${VM_PASSWORD}"

echo "$VM_PASSWORD" | sudo -S -v

mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat > ~/.ssh/id_ed25519 <<KEY
$DEPLOY_KEY_GITHUB
KEY

chmod 600 ~/.ssh/id_ed25519

ssh-keyscan github.com >> ~/.ssh/known_hosts

# ssh -T git@github.com || true

rm -rf ppc_test

git clone git@github.com:sylavaya/ppc_test.git

cd ~/ppc_test/vlabs-SiL

./vlabs-SiL.sh setup

./vlabs-SiL.sh select -n S32K344_VAYAVYA_LABS_PPC

./vlabs-SiL.sh test logs test_power_off

cd ..

python3 test_mail.py

echo "Pipeline completed successfully."

EOF
