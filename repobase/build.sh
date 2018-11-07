#!/bin/bash

echo "creating new template set"
aws s3 cp templates/* s3://${CFN_TEMPLATE_BUCKET}/${COMMIT_ID}/templates/

echo "running cloudformation deployment"
/bin/bash ./cfn-deploy.sh

echo "populate repo"
REPONAME="${PLATFORM}-${SERVICE}-repository"
CLONEURL="$(aws codecommit get-repository --repository-name ${REPONAME} --query 'repositoryMetadata.cloneUrlSsh' --output text)"

if [ "$?" == "0" ]; then
    git clone ${CLONEURL}

    cd ${REPONAME}
    #cp -rn ../repobase/* ./
    cp -r ../repobase/* ./
    git add . && git commit -m "Repository base"
    git push origin master
    cd ..
    rm -rf ${REPONAME}

    echo "================================================"
    echo "Now run 'git clone ${CLONEURL}'"
    echo "================================================"
else
    echo "Cannot get repository url"
    exit 1
fi
