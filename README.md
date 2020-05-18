# Code Spike for PTTP CI / CD solution 

## Usage Instructions

To pull source code from Github, you will need to create an OAuth token to allow access.
Add this to the .tfvars file:

```shell script
    github_oauth_token = "abc123"
```

Run Terraform with the variables file:

```shell script
terraform apply -var-file=".tfvars"
```

### Note

This was a code spike and the final solution is likely to change in some way.

