Supposing a file `env.sh` exists with the following

```
export AWS_ACCOUNT=<your account>
export REGION=<region>
export TF_STATE_BUCKET=<your s3 bucket for s3 state>
export OAUTH_TOKEN=<github personal access token>
export GITHUB_OWNER=<github team>
export GITHUB_REPO=<github repo> 
```


Run

`source env.sh`

to set the variables required for other scripts



To create your s3 bucket if it doesn't already exist run

`./bootstrap.sh`
