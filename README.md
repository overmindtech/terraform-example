# Overmind Impact Analysis with GitHub Actions

This example repo shows how to run terraform on GitHub Actions and automatically submit each PR's changes to [Overmind](https://overmind.tech), reporting back the blast radius as a comment on the PR. You can see that in action in [this PR](https://github.com/overmindtech/terraform-example/pull/5).

# Developer Notes

Some notes to get started with replicating this on your own setup.

* Create AWS account

* Configure AWS cli to access account
    - `aws configure sso`; [docs](https://docs.aws.amazon.com/signin/latest/userguide/command-line-sign-in.html)

* Setup the `AWS_PROFILE` environment variable to point at your local profile.
    - Note that because of [this issue in terraform](https://github.com/hashicorp/terraform/issues/32465), the created `~/.aws/config` needs to be adjusted (see especially [this comment](https://github.com/hashicorp/terraform/issues/32465#issuecomment-1566744199) for details)
    - If you use VSCode Dev Containers, `.devcontainer/devcontainer.json` has guidance on how to permanently configure `AWS_PROFILE` and import your user's AWS config

* Setup S3 and DynamoDB for remote state storage [docs](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-remote)
    - follow the comments on the `terraform{}` block to bootstrap this in a new account

* Configure OIDC access for github actions [docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

* Supply the ARN of the created role (terraform output `terraform_deploy_role`) as `TERRAFORM_DEPLOY_ROLE` and an Overmind API as `OVM_API_KEY` through the "Actions secrets and variables" page in the repo settings.
