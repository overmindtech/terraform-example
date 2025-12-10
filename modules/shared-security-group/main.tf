# main.tf
# Shared Security Group Infrastructure

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

resource "random_id" "suffix" {
  count       = var.enabled ? 1 : 0
  byte_length = 4
}

locals {
  random_suffix = var.enabled ? random_id.suffix[0].hex : ""
  name_prefix   = "${var.name_prefix}-${local.random_suffix}"

  common_tags = merge(var.additional_tags, {
    Environment = "production"
    Project     = "platform-services"
    ManagedBy   = "terraform"
  })
}

data "aws_region" "current" {}

