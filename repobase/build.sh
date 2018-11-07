#!/bin/bash

echo "creating new template set"
aws s3 cp templates/* s3://${CFN_TEMPLATE_BUCKET}/${COMMIT_ID}/templates/

echo "running cloudformation deployment"
/bin/bash ./cfn-deploy.sh
