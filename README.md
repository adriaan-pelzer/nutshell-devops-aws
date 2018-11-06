# BOOTSTRAP

## Create the following:

### CodeCommit Repository
```
    bootstrap
```

Store this repo in bootstrap

### S3 Bucket
```
    cfn.[YOUR_DOMAIN_NAME]
```

Update cfn-deploy.sh and set:
```
    DOMAIN="[YOUR_DOMAIN_NAME]"
```

Push this to the repository

run:

```
    ./cfn-deploy.sh deploy.json
```
