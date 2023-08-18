* Create AWS account

* Configure AWS cli to access account
    - `aws configure sso`; [docs](https://docs.aws.amazon.com/signin/latest/userguide/command-line-sign-in.html)

* Setup S3 and DynamoDB for remote state storage [docs](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-remote)
    - follow comments on the `terraform{}` block to bootstrap this in a new account

* Configure OIDC access for github actions [docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
