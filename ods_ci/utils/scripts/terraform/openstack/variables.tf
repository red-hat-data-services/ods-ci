variable "cloud_name" {
  type = string
  description = "value"
}

variable "vm_name" {
  type = string
  description = "value"
}

variable "vm_user" {
  type = string
  description = "value"
  default = "centos"
}

variable "vm_private_key" {
  type = string
  description = "value"
  default = ""
}

variable "image_name" {
  type = string
  description = "value"
  default = "CentOS-Stream-8-x86_64-GenericCloud"
}

variable "flavor_name" {
  type = string
  description = "value"
  default = "m1.medium"
}

variable "key_pair" {
  type = string
  description = "value"
}

variable "network_name" {
  type = string
  description = "value"
}
