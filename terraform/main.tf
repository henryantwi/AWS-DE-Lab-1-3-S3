terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.44"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  account_id      = data.aws_caller_identity.current.account_id
  data_lake_name  = "data-lake-prod-${local.account_id}"
  log_bucket_name = "data-lake-prod-${local.account_id}-access-logs"

  tag_vars = {
    project     = var.project
    lab         = var.lab
    environment = var.environment
    owner       = var.owner
    purpose     = var.purpose
    cost_center = var.cost_center
  }
}

module "logging_bucket" {
  source = "./modules/logging_bucket"

  bucket_name = local.log_bucket_name
  project     = local.tag_vars.project
  lab         = local.tag_vars.lab
  environment = local.tag_vars.environment
  owner       = local.tag_vars.owner
  purpose     = local.tag_vars.purpose
  cost_center = local.tag_vars.cost_center
}

module "data_lake_bucket" {
  source = "./modules/data_lake_bucket"

  bucket_name       = local.data_lake_name
  logging_bucket_id = module.logging_bucket.bucket_id
  project           = local.tag_vars.project
  lab               = local.tag_vars.lab
  environment       = local.tag_vars.environment
  owner             = local.tag_vars.owner
  purpose           = local.tag_vars.purpose
  cost_center       = local.tag_vars.cost_center
}

module "zone_markers" {
  source = "./modules/zone_markers"

  bucket_id = module.data_lake_bucket.bucket_id
}
