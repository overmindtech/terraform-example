# Same backend as 00_setup/ — both directories share state so that
# running `terraform plan` here produces a diff against the setup baseline.
terraform {
  backend "s3" {
    bucket         = "overmind-scale-test-tfstate"
    key            = "investigator-live-query/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "overmind-scale-test-tfstate-lock"
  }
}
