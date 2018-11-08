#!/bin/bash

echo "creating new template set"
aws s3 cp templates/* s3://${CFN_TEMPLATE_BUCKET}/${COMMIT_ID}/templates/ || exit 1

echo "running cloudformation deployment"
/bin/bash ./cfn-deploy.sh || exit 1

REPONAME="${PLATFORM}-${SERVICE}"
CLONEURL="$(aws codecommit get-repository --repository-name ${REPONAME} --query 'repositoryMetadata.cloneUrlSsh' --output text)"

if [ "$?" == "0" ]; then
    echo "==================================================="
    echo "Now run 'git clone ${CLONEURL}',"
    echo "and push the contents of repobase to the repository"
    echo "==================================================="
else
    echo "Cannot get repository url"
    exit 1
fi
