terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  tags         = local.tags
}

# module "github" {}
# module "codebuild" {}
# module "codedeploy" {}
# module "codepipeline" {}
