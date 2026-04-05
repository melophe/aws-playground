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

module "github" {
  source       = "./modules/github"
  project_name = var.project_name
  tags         = local.tags
}

module "codebuild" {
  source       = "./modules/codebuild"
  project_name = var.project_name
  aws_region   = var.aws_region
  tags         = local.tags
}

# module "codedeploy" {}
# module "codepipeline" {}
