<p align="center">
  <picture width="260px" align="center">
      <source media="(prefers-color-scheme: dark)" srcset="https://assets-global.website-files.com/6241e92445c21f9c1245a940/6582c2b96d741b023f1afabf_ov-lite-icon-p-500.png">
      <img alt="Overmind" src="https://assets-global.website-files.com/6241e92445c21f9c1245a940/6582c2b96d741b023f1afabf_ov-lite-icon-p-500.png" width="260px" align="center">
    </picture>
  <h1 align="center">Overmind Impact Analysis with GitHub Actions</h1>
  <p align="center">
     <a href="https://overmind.tech">https://overmind.tech</a> 
    <br/>
    For the first time you don't have to wait for the worst when you push a change. Discover and detect the risks you can't see. Overmind gives you the insight of a post-mortem without the fallout of broken infra.
  </p>
</p>
<br/>

<p align="center">
  <a href="https://discord.com/invite/5UKsqAkPWG" rel="nofollow"><img src="https://img.shields.io/discord/1088753599951151154?label=Discord&logo=discord&logoColor=white" alt="Discord Server"></a>
</p>

<p align="center">
  <a href="https://vimeo.com/903381683">🎥 Watch a demo</a> | <a href="https://overmind.tech/how-it-work">📖 How it works</a> | <a href="https://app.overmind.tech/api/auth/signup">🚀 Sign up</a> | <a href="https://www.linkedin.com/company/overmindtech/">🙌 Follow us</a>
</p>

<br/>

This example repo shows how to run terraform on GitHub Actions and automatically submit each PR's changes to [Overmind](https://overmind.tech), reporting back the blast radius as a comment on the PR. You can see that in action in [this PR](https://github.com/overmindtech/terraform-example/pull/57).

<br/>

![Example Overmind report showing the expected changes and timeline for the example PR](https://github.com/overmindtech/terraform-example/blob/6d7240aec15b0992901fabe56be25c789b636cbb/assets/overmind%20risk%20.gif)

<br>

Please note: You are unable to view the change in Overmind as it is a change tied to our personal account.

# Forking this repo

If you would like to use this repo as an example. Follow these steps:

1. Fork the repo
1. Comment out the S3 section:

```hcl
terraform {
  # backend "s3" {
  #   bucket         = "replaceme-with-a-unique-bucket-name"
  #   dynamodb_table = "overmind-tf-example-state"
  #   key            = "terraform-example.tfstate"

  #   region = "eu-west-2"
  # }
}
```

1. Replace all instances of `replaceme-with-a-unique-bucket-name` in `terraform.tf` with a unique bucket name for your environment
1. Replace `repo:overmindtech/terraform-example:*` with `repo:[YOUR USERNAME]/terraform-example:*`, replacing `[YOUR USERNAME]` with your Github username
1. Run `terraform init`
1. Run `terraform plan` to see what resources need to be set up
1. Run `terraform apply`. This will set up the resources required for storing state and locks
1. Un-comment the `backend "s3"` section from `terraform.tf` and run `terraform init -migrate-state`. This will migrate your state from your local device to S3
1. Run `terraform plan` which should show no changes

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
