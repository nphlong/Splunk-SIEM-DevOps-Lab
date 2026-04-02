param(
  [string]$ProjectRoot = "..",
  [string]$RemoteAnsibleDir = "/home/ec2-user/ansible",
  [switch]$RunPlaybook
)

$ErrorActionPreference = "Stop"

function Require-Command {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' was not found in PATH."
  }
}

Require-Command "terraform"
Require-Command "ssh"
Require-Command "scp"

$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$TerraformDir = Join-Path $ProjectRoot "terraform"
$AnsibleDir = Join-Path $ProjectRoot "ansible"
$InventoryPath = Join-Path $AnsibleDir "inventory.ini"
$KeyPath = Join-Path $ProjectRoot "shared_keys\splunk-lab-key.pem"

if (-not (Test-Path $TerraformDir)) { throw "Terraform directory not found: $TerraformDir" }
if (-not (Test-Path $AnsibleDir)) { throw "Ansible directory not found: $AnsibleDir" }
if (-not (Test-Path $KeyPath)) { throw "SSH key not found: $KeyPath (run terraform apply first)." }

# Windows OpenSSH may reject keys with inherited ACLs; lock down read access.
icacls $KeyPath /inheritance:r | Out-Null
icacls $KeyPath /grant:r "${env:USERNAME}:R" | Out-Null

$tfOutputRaw = terraform -chdir="$TerraformDir" output -json
$tfOutput = $tfOutputRaw | ConvertFrom-Json

if (-not $tfOutput.bastion_public_ip.value) {
  throw "Missing Terraform output: bastion_public_ip"
}
if (-not $tfOutput.all_splunk_private_ips.value) {
  throw "Missing Terraform output: all_splunk_private_ips"
}

$BastionIp = [string]$tfOutput.bastion_public_ip.value
$NodeIps = @($tfOutput.all_splunk_private_ips.value)

if ($NodeIps.Count -lt 7) {
  throw "Expected 7 Splunk node IPs, found $($NodeIps.Count)."
}

$inventory = @"
[manager]
splunk-manager ansible_host=$($NodeIps[6])  # Node 6

[indexers]
idx01 ansible_host=$($NodeIps[3])           # Node 3
idx02 ansible_host=$($NodeIps[4])           # Node 4
idx03 ansible_host=$($NodeIps[5])           # Node 5

[searchheads]
sh01 ansible_host=$($NodeIps[0])            # Node 0
sh02 ansible_host=$($NodeIps[1])            # Node 1
sh03 ansible_host=$($NodeIps[2])            # Node 2

[splunk_cluster:children]
manager
indexers
searchheads

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
"@

$inventory | Set-Content -Path $InventoryPath -Encoding ascii
Write-Host "Updated inventory: $InventoryPath"

$sshOpts = @(
  "-i", $KeyPath,
  "-o", "StrictHostKeyChecking=no",
  "-o", "UserKnownHostsFile=/dev/null"
)

ssh @sshOpts "ec2-user@$BastionIp" "rm -rf $RemoteAnsibleDir && mkdir -p $RemoteAnsibleDir"
scp @sshOpts -r "$AnsibleDir\*" "ec2-user@${BastionIp}:$RemoteAnsibleDir/"

Write-Host "Copied ansible folder to bastion: ec2-user@${BastionIp}:$RemoteAnsibleDir"
Write-Host "Run on bastion: cd $RemoteAnsibleDir && ansible-playbook -i inventory.ini site.yml"

if ($RunPlaybook) {
  ssh @sshOpts "ec2-user@$BastionIp" "cd $RemoteAnsibleDir && ansible-playbook -i inventory.ini site.yml"
}
