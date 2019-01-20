Supposing a file `env.sh` exists with the following

```
export TF_STATE_BUCKET=<your s3 bucket for s3 state>
export TF_STATE_REGION=<the region of your bucket> 
```


Run

`source env.sh`

to set the variables required for other scripts



To create your s3 bucket if it doesn't already exist run

`./bootstrap.sh`


To create all terraform resources under directory `./component` configured with variables in the file `./component/environment.vars`, run

`./apply.sh component environment`


To delete all terraform resources under directory `./component` configured with variables in the file `./component/environment.vars`, run

`./destory.sh component environment`

