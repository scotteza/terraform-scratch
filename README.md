# PTTP CI / CD 

This repository holds the Terraform code to create a [https://aws.amazon.com/codebuild/](CodeBuild) / [https://aws.amazon.com/codepipeline/](CodePipeline) service in AWS.

## How to use this repo

The source code in this repository is provided only as a reference.
Please speak to someone on the PTTP team to get a pipeline set up for you.

This pipeline will be integrated with a Github repository, and build your project according to your [https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html](buildspec) files.

### Linting

If you are doing static code analysis as part of your build, please create a `buildspec.lint.yml` file, and place it in the root of your project.

example:

```yaml
version: 0.2

phases:
  install:
    commands:
      - make lint
```

### Testing

To run automated tests, create a  `buildspec.test.yml` file, and place it in the root of your project.

example:
```yaml
version: 0.2

phases:
  install:
    commands:
      - make test
```

### Deployment

For deployments, create a `buildspec.yml` file.

example:
```yaml
version: 0.2

#env:
#  variables:
#    key: "value"
#    key: "value"

phases:
  install:
    commands:
      - pip install boto3
      - wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
      - unzip terraform_0.12.24_linux_amd64.zip
      - mv terraform /bin
      - terraform init
  build:
    commands:
      - terraform apply --auto-approve
```

## To create your own Pipeline

For experimenting with AWS CodePipeline / CodeBuild, you can execute the Terrafom in this repository.

An OAuth token is required to pull your source code from Github.

Create an access token for your repository and add it to a .tfvars file.

```shell script
github_oauth_token = "abc123"
```

Run Terraform with the variables file:

```shell script
terraform apply -var-file=".tfvars"
```

