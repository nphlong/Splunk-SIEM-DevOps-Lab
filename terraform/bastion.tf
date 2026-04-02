resource "aws_instance" "bastion_controller" {
  ami                    = data.aws_ami.latest_al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.vpn_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              # 1. Install Ansible
              dnf update -y
              dnf install -y ansible-core git python3-pip

              # 2. Provision the Master Private Key for Ansible
              mkdir -p /home/ec2-user/.ssh
              echo "${tls_private_key.main_key.private_key_pem}" > /home/ec2-user/.ssh/id_rsa
              chmod 400 /home/ec2-user/.ssh/id_rsa
              chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa

              # 3. Download OpenVPN script and setup
              dnf install -y openvpn iptables openssl ca-certificates curl tar bind-utils socat --allowerasing
              curl -L -o /home/ec2-user/openvpn-install.sh https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
              chmod +x /home/ec2-user/openvpn-install.sh
              chown ec2-user:ec2-user /home/ec2-user/openvpn-install.sh
              # Keep OpenVPN installer downloaded, but run interactively later over SSH.
              # The upstream script prompts for input and can hang cloud-init in user_data.
              EOF

  tags = { Name = "Splunk-Bastion-Controller" }
}