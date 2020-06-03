variable "aws-region" {
  default = "eu-west-2"
}

variable "backend-min-size" {}
variable "backend-max-size" {
  default = 10
}

variable "subnet_ids" {
  type = "list"
}

variable "logging-docker-image" {
  default = "261219435789.dkr.ecr.eu-west-2.amazonaws.com/pttp-monitoring-service"
}

variable "vpc_id" {}



