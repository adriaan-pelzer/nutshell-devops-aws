# BOOTSTRAP

## Create the following:

### admin user
```
    username: root
    default password: root
```
After this user has been created, [configure this user and your machine for ssh git access](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html).

### Cloudformation Template Bucket
```
    new-pipeline-cloudformation-template-bucket
```
This is a repository for all reuseable cloudformation templates. Every time you update this (by pushing the **new_pipeline** repository), all templates in the **templates** folder will be uploaded to this bucket, namespaced by the latest git commit hash.
```
    ***git_commit_hash_time_0***
      `-- templates
        +-- template0.json
        +-- template1.json
        `-- template2.json
    ***git_commit_hash_time_1***
      `-- templates
        +-- template0.json
        +-- template1.json
        +-- template2.json
        `-- template3.json
``` 
This is done so that all templates referenced by a pipeline will not be changed unless the pipeline itself is deployed to.

### CodeCommit Repository
```
    new-pipeline
```
Check this repository out on your local machine. Every time you push a tag to this repository, it will create a brand new code pipeline for you, based on information you pass in the tag.
The tagging conevention is **platform**-**service**-**stack_type**.
* platform: A namespace that groups several services (or stacks) together.
* service: The name of this service (or stack).
* stack_type: The type of stack to build. This maps directly to a cloudformation template named **stack_name**.json
