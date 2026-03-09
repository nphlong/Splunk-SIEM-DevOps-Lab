variable "splunk_password" {
  type        = string
  description = "Admin password for Splunk"
}

variable "splunk_image" {
  type    = string
  default = "splunk/splunk:latest"
}
