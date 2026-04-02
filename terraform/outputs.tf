output "bastion_public_ip" {
  value = aws_instance.bastion_controller.public_ip
}

output "manager_private_ip" {
  value = aws_instance.splunk_nodes[6].private_ip
}

output "searchhead_private_ips" {
  value = slice(aws_instance.splunk_nodes[*].private_ip, 0, 3)
}

output "indexer_private_ips" {
  value = slice(aws_instance.splunk_nodes[*].private_ip, 3, 6)
}

output "all_splunk_private_ips" {
  value = aws_instance.splunk_nodes[*].private_ip
}