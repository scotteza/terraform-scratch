terraform {
  required_version = "> 0.12.0"

  backend "s3" {
    bucket     = "pttp-terraform-remote-state"
    key        = "terraform/v1/state"
    region     = "eu-west-2"
  }
}

provider "tls" {
  version = "> 2.1"
}

provider "null" {
  version = "~> 2.1"
}

provider "aws" {
  version = "~> 2.52"
}

provider "local" {
  version = "~> 1.4"
}

data "aws_caller_identity" "current" {}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.16.0"

  namespace = "pttp"
  stage     = terraform.workspace
  name      = "pttp"
  delimiter = "-"

  tags = {
    "business-unit" = "MOJ"
    "application"   = "PTTP",
    "is-production" = "false",
    "owner"         = "pttp@madetech.com"

    "region"           = data.aws_region.current_region.id
    "environment-name" = terraform.workspace
    "source-code"      = "tbc"
  }
}

data "aws_region" "current_region" {}

module "dynamic_subnets" {
  source             = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  namespace          = "pttp"
  stage              = "dev"
  name               = "pttp"
  availability_zones = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  vpc_id             = module.vpc.vpc_id
  igw_id             = module.vpc.igw_id
  cidr_block         = "10.0.0.0/16"
  map_public_ip_on_launch = false
}

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=master"
  namespace  = "pttp"
  stage      = "dev"
  name       = "pttp"
  cidr_block = "10.0.0.0/16"
}

module "build" {
  source = "./modules/pipeline"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.dynamic_subnets.public_subnet_ids
  github_oauth_token = var.github_oauth_token
}