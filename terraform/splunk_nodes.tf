# resource "aws_instance" "splunk_nodes" {
#   count = 7
#   ami   = data.aws_ami.latest_al2023.id

#   # Manager (index 6) gets t3.small, others get t3.micro
#   instance_type = (count.index == 6 ? "t3.small" : "t3.micro")

#   subnet_id              = aws_subnet.private.id
#   key_name               = aws_key_pair.generated_key.key_name
#   vpc_security_group_ids = [aws_security_group.splunk_internal.id]

#   tags = {
#     Name = count.index == 6 ? "Splunk-Manager" : "Splunk-Node-${count.index}"
#   }
# }

# Look up the official Splunk Enterprise AMI
data "aws_ami" "splunk_enterprise" {
  count       = var.splunk_ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["679593333241"] # Official Splunk AWS Marketplace Owner ID

  filter {
    name   = "name"
    values = ["*Splunk*Enterprise*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "splunk_nodes" {
  count         = 7 
  ami           = var.splunk_ami_id != "" ? var.splunk_ami_id : data.aws_ami.splunk_enterprise[0].id 
  
  # Using t3.medium for the Manager to handle the AMI overhead
  instance_type = (count.index == 6 ? "t3.medium" : "t3.small") 
  
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.splunk_internal.id]

  # This script runs on first boot to bypass the "changeme" default password
  user_data = <<-EOF
              #!/bin/bash
              # Wait for Splunk to initialize
              until [ -f /opt/splunk/bin/splunk ]; do sleep 5; done
              
              # Change default password from 'changeme' to your variable
              /opt/splunk/bin/splunk edit user admin -password "${var.splunk_admin_password}" -role admin -auth admin:changeme
              EOF

  tags = { 
    Name = count.index == 6 ? "Splunk-Manager" : "Splunk-Node-${count.index}" 
  }
}