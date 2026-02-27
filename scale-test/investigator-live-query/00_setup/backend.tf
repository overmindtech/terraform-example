terraform {
  backend "s3" {
    bucket         = "overmind-scale-test-tfstate"
    key            = "investigator-live-query/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "overmind-scale-test-tfstate-lock"
  }
}
