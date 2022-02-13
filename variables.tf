variable "region" {
  description = "Provider region"
  default     = "us-east-1"
}

variable "tags" {
  description = "Default of tagging."
  default = {
    Creator     = "terraform"
    Environment = "dev"
  }
}

variable "access_ip" {
  description = "Public address, where the at will be accessed from"
  default = [
    "34.245.121.186/32"
  ]
}