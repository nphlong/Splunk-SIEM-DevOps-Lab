#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-..}"
REMOTE_ANSIBLE_DIR="${REMOTE_ANSIBLE_DIR:-/home/ec2-user/ansible}"
RUN_PLAYBOOK="${RUN_PLAYBOOK:-false}"

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Required command '$name' not found in PATH." >&2
    exit 1
  fi
}

require_command terraform
require_command ssh
require_command scp
require_command python3

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
INVENTORY_PATH="$ANSIBLE_DIR/inventory.ini"
KEY_PATH="$PROJECT_ROOT/shared_keys/splunk-lab-key.pem"

[[ -d "$TERRAFORM_DIR" ]] || { echo "Terraform directory not found: $TERRAFORM_DIR" >&2; exit 1; }
[[ -d "$ANSIBLE_DIR" ]] || { echo "Ansible directory not found: $ANSIBLE_DIR" >&2; exit 1; }
[[ -f "$KEY_PATH" ]] || { echo "SSH key not found: $KEY_PATH (run terraform apply first)." >&2; exit 1; }

chmod 400 "$KEY_PATH"

TF_JSON="$(terraform -chdir="$TERRAFORM_DIR" output -json)"

mapfile -t OUTPUTS < <(python3 - <<'PY' "$TF_JSON"
import json
import sys

data = json.loads(sys.argv[1])

try:
    bastion = data["bastion_public_ip"]["value"]
    nodes = data["all_splunk_private_ips"]["value"]
except KeyError as exc:
    print(f"Missing Terraform output: {exc}", file=sys.stderr)
    sys.exit(1)

if len(nodes) < 7:
    print(f"Expected 7 Splunk node IPs, found {len(nodes)}", file=sys.stderr)
    sys.exit(1)

print(bastion)
for node in nodes:
    print(node)
PY
)

BASTION_IP="${OUTPUTS[0]}"
NODE_IPS=("${OUTPUTS[@]:1}")

cat >"$INVENTORY_PATH" <<EOF
[manager]
splunk-manager ansible_host=${NODE_IPS[6]}  # Node 6

[indexers]
idx01 ansible_host=${NODE_IPS[3]}           # Node 3
idx02 ansible_host=${NODE_IPS[4]}           # Node 4
idx03 ansible_host=${NODE_IPS[5]}           # Node 5

[searchheads]
sh01 ansible_host=${NODE_IPS[0]}            # Node 0
sh02 ansible_host=${NODE_IPS[1]}            # Node 1
sh03 ansible_host=${NODE_IPS[2]}            # Node 2

[splunk_cluster:children]
manager
indexers
searchheads

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

echo "Updated inventory: $INVENTORY_PATH"

SSH_OPTS=(
  -i "$KEY_PATH"
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
)

ssh "${SSH_OPTS[@]}" "ec2-user@$BASTION_IP" "rm -rf $REMOTE_ANSIBLE_DIR && mkdir -p $REMOTE_ANSIBLE_DIR"
scp "${SSH_OPTS[@]}" -r "$ANSIBLE_DIR/"* "ec2-user@$BASTION_IP:$REMOTE_ANSIBLE_DIR/"

echo "Copied ansible folder to bastion: ec2-user@$BASTION_IP:$REMOTE_ANSIBLE_DIR"
echo "Run on bastion: cd $REMOTE_ANSIBLE_DIR && ansible-playbook -i inventory.ini site.yml"

if [[ "$RUN_PLAYBOOK" == "true" ]]; then
  ssh "${SSH_OPTS[@]}" "ec2-user@$BASTION_IP" "cd $REMOTE_ANSIBLE_DIR && ansible-playbook -i inventory.ini site.yml"
fi
