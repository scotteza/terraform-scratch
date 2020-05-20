terraform {
  required_version = "> 0.12.0"

  backend "s3" {
    bucket     = "pttp-terraform-remote-state"
    key        = "terraform/v1/state"
    region     = "eu-west-2"
  }
}

data "aws_region" "current_region" {}

module "dynamic_subnets" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  namespace               = "pttp"
  stage                   = "dev"
  name                    = "pttp"
  availability_zones      = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  vpc_id                  = module.vpc.vpc_id
  igw_id                  = module.vpc.igw_id
  cidr_block              = "10.0.0.0/16"
  map_public_ip_on_launch = false
  nat_gateway_enabled     = false
}

module "vpc" {
  source               = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=master"
  namespace            = "pttp"
  stage                = "dev"
  name                 = "pttp"
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = false
  enable_dns_support   = false
}

module "build" {
  source = "./modules/pipeline"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.dynamic_subnets.public_subnet_ids
  github_oauth_token = var.github_oauth_token
}