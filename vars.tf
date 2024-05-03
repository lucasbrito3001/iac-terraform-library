variable "project_id" {
  type = string
}

variable "services_machine_type" {
  type    = string
  default = "n2-standard-2"
}

variable "services_machine_image" {
  type    = string
  default = "debian-cloud/debian-11"
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "zone" {
  type    = string
  default = "us-east1-b"
}