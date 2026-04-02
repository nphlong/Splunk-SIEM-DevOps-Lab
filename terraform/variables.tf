variable "splunk_admin_password" {
  description = "The admin password for all Splunk instances"
  type        = string
  sensitive   = true
  default     = "YourSecurePassword123!" # Change this to your actual password
}

variable "splunk_ami_id" {
  description = "Optional override for Splunk Enterprise AMI ID (recommended if marketplace lookup fails)"
  type        = string
  default     = ""
}