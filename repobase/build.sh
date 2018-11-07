#!/bin/bash

echo "Platform: ${PLATFORM}"
echo "Service: ${SERVICE}"
echo "StackType: ${STACK_TYPE}"
echo "CommitId: ${COMMIT_ID}"

aws s3 cp templates/* s3://${CFN_TEMPLATE_BUCKET}/${COMMIT_ID}/templates/


