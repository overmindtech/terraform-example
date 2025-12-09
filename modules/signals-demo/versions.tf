terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Note: Provider configuration is inherited from the root when called as a module.
# When running standalone, configure the provider in a separate provider.tf file
# or pass it via command line/terraform.tfvars
