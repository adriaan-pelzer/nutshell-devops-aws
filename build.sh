#!/bin/bash

REGION="eu-west-1"

aws cloudformation deploy --stack-name deploy --template-file deploy.json --region ${REGION} --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
    Platform="root" \
    Service="deploy"
