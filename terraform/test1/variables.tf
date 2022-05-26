variable "prefix" {
  type    = string
  default = "test1"
}

variable "location" {
  type    = string
  default = "westus2"
}

variable "docker_image" {
  type    = string
  default = "ghcr.io/yaegashi/dx2devops-redmine/redmica"
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}
