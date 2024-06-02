variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}
variable "server_type" {
  type        = string
  description = "Instance type"
  default     = "t2.large"
}

variable "public_server_count" {
  type        = number
  description = "Instance name"
  default     = 1
}

variable "include_ipv4" {
  type    = bool
  default = true
}
