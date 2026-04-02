# 1. Generate the cryptographic key pair
resource "tls_private_key" "main_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Register the Public Key with AWS (Used by all 8 instances)
resource "aws_key_pair" "generated_key" {
  key_name   = "splunk-lab-key"
  public_key = tls_private_key.main_key.public_key_openssh
}

# 3. Save the Private Key to your Windows machine
resource "local_file" "ssh_key" {
  content         = tls_private_key.main_key.private_key_pem
  filename        = "../shared_keys/splunk-lab-key.pem"
  file_permission = "0400"
}