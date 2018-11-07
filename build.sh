#!/bin/bash

REGION="eu-west-1"
REPONAME="new-pipeline"

aws cloudformation deploy --stack-name ${REPONAME} --template-file ${REPONAME}.json --region ${REGION} --capabilities CAPABILITY_NAMED_IAM \
    || exit 1

CLONEURL="$(aws codecommit get-repository --repository-name ${REPONAME} --query 'repositoryMetadata.cloneUrlSsh' --output text)"

git clone ${CLONEURL}

cd ${REPONAME}
cp -rn ../repobase/* ./
git add . && git commit -m "Repository base"
git push origin master
cd ..
rm -rf ${REPONAME}

echo "================================================"
echo "Now run 'git clone ${CLONEURL}'"
echo "================================================"
