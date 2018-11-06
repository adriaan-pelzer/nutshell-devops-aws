#!/bin/bash

PLATFORM="${1}"
SERVICE="${2}"
TEMPLATE="${3}"
REGION="eu-west-1"

if [ -z "${PLATFORM}" ]; then
    echo "Please specify a platform name (1st argument)"
    exit 1
fi

if [ -z "${SERVICE}" ]; then
    echo "Please specify a service name (2nd argument)"
    exit 1
fi

if [ -z "${TEMPLATE}" ]; then
    echo "Please specify a workflow template name (3rd argument)"
    exit 1
fi

aws cloudformation deploy --stack-name deploy --template-file ${TEMPLATE}.json --region ${REGION} --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
    Platform="${PLATFORM}" \
    Service="${SERVICE}"
