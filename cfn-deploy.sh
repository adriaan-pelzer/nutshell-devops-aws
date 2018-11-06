#!/bin/sh

TEMPLATE_FILE="${1}"
REGION="eu-west-1"

declare -A parameters=()

parameters[Platform]="test"
parameters[Service]="demo"

declare -A tags=()

tags[Platform]="${parameters[Platform]}"
tags[Service]="${parameters[Service]}"

function build_parameter_string() {
    FIRST=1
    for PARAMETER in ${@}; do
        if [ -z "${parameters[$PARAMETER]}" ]; then
            echo "Please define Parameter '${PARAMETER}'"
            exit 1
        fi
        if [ "${FIRST}" == "1" ]; then
            FIRST=0
            printf "ParameterKey=$PARAMETER,ParameterValue=${parameters[$PARAMETER]}"
        else
            printf " ParameterKey=$PARAMETER,ParameterValue=${parameters[$PARAMETER]}"
        fi
    done
}

function build_tag_string() {
    FIRST=1
    for TAG in "${!tags[@]}"; do
        if [ "${FIRST}" == "1" ]; then
            FIRST=0
            printf "Key=$TAG,Value=${parameters[$TAG]}"
        else
            printf " Key=$TAG,Value=${parameters[$TAG]}"
        fi
    done
}

function build_capability_string() {
    FIRST=1
    for CAPABILITY in ${@}; do
        if [ "${CAPABILITY}" != "None" ]; then
            if [ "${FIRST}" == "1" ]; then
                FIRST=0
                printf "${CAPABILITY}"
            else
                printf " ${CAPABILITY}"
            fi
        fi
    done
}

function build_stack_parms() {
    STACKNAME="${1}"
    TEMPLATEURL="${2}"
    PARAMETERSTRING="${3}"
    CAPABILITYSTRING="${4}"
    TAGSTRING="${5}"

    printf "%sregion ${REGION} --stack-name ${STACKNAME} --template-url ${TEMPLATEURL}" '--'

    if [ -n "${PARAMETERSTRING}" ]; then
        printf " %sparameters ${PARAMETERSTRING}" '--'
    fi

    if [ -n "${CAPABILITYSTRING}" ]; then
        printf " %scapabilities ${CAPABILITYSTRING}" '--'
    fi

    if [ -n "${TAGSTRING}" ]; then
        printf " %stags ${TAGSTRING}" '--'
    fi
}

function build_changeset_parms() {
    STACKNAME="${1}"
    TEMPLATEURL="${2}"
    CHANGESETNAME="${3}"
    PARAMETERSTRING="${4}"
    CAPABILITYSTRING="${5}"
    TAGSTRING="${6}"

    build_stack_parms "${STACKNAME}" "${TEMPLATEURL}" "${PARAMETERSTRING}" "${CAPABILITYSTRING}" "${TAGSTRING}"
    printf " %schange-set-name ${CHANGESETNAME}" '--'
}

if [ -z "${TEMPLATE_FILE}" ]; then
    echo "Please specify a template file in s3"
    exit 1
fi

#TODO remove
aws s3 cp ${TEMPLATE_FILE} s3://cfn.adriaanpelzer.com/templates/${TEMPLATE_FILE}
###

TEMPLATEURL="https://s3-${REGION}.amazonaws.com/cfn.adriaanpelzer.com/templates/${TEMPLATE_FILE}"

echo "Validating template ..."
AWSVALIDATE="aws cloudformation validate-template --template-url ${TEMPLATEURL} --region ${REGION}"
if [ "$?" != "0" ]; then
    echo "*** validation failed"
    exit 1
fi
echo "    validation succeeded"

PARAMETERS="$(${AWSVALIDATE} --query "Parameters[*].ParameterKey" --output text | sed -e 'y/\t/ /')"
CAPABILITIES="$(${AWSVALIDATE} --query "Capabilities[*]" --output text | sed -e 'y/\t/ /')"

STACKNAME="${parameters[Platform]}-${parameters[Service]}-stack"
CHANGESETNAME="changeset-$(git log -n 1 | grep commit | awk '{ print $2 }')"
PARAMETERSTRING="$(build_parameter_string ${PARAMETERS})"
CAPABILITYSTRING="$(build_capability_string ${CAPABILITIES})"
TAGSTRING="$(build_tag_string)"

AWSCREATECS="aws cloudformation create-change-set"
AWSCREATEST="aws cloudformation create-stack"

echo "Creating changeset ${CHANGESETNAME} ..."
STACKID="$(${AWSCREATECS} $(build_changeset_parms "${STACKNAME}" "${TEMPLATEURL}" "${CHANGESETNAME}" "${PARAMETERSTRING}" "${CAPABILITYSTRING}" "${TAGSTRING}") --query 'StackId' --output text)"

if [ "$?" != "0" ]; then
    echo "*** changeset failed"
    echo "(maybe the stack does not exist yet)"
    echo "Creating stack ${STACKNAME} ..."
    STACKID="$(${AWSCREATEST} $(build_stack_parms "${STACKNAME}" "${TEMPLATEURL}" "${PARAMETERSTRING}" "${CAPABILITYSTRING}" "${TAGSTRING}") --query "StackId" --output text)"
    if [ "$?" != "0" ]; then
        echo "*** cannot create stack"
        exit 1
    fi
fi
echo "    changeset created"

CHANGESETID="$(${AWSCREATECS} $(build_changeset_parms "${STACKNAME}" "${TEMPLATEURL}" "${CHANGESETNAME}" "${PARAMETERSTRING}" "${CAPABILITYSTRING}" "${TAGSTRING}") --query 'Id' --output text)"

echo "Checking changeset status ..."
CHANGESETSTATUS="INIT"

while [[ ${CHANGESETSTATUS} != *_COMPLETE ]] && [[ ${CHANGESETSTATUS} != *FAILED ]]; do
    NEWCHANGESETSTATUS="$(aws cloudformation describe-change-set --change-set-name ${CHANGESETNAME} --region ${REGION} --stack-name ${STACKNAME} --query "Status" --output text)"
    if [ "$?" != "0" ]; then
        echo "*** changeset status call failed"
        exit 1
    fi
    if [ "${CHANGSETSTATUS}" != "${NEWCHANGESETSTATUS}" ]; then
        echo "    ${NEWCHANGESETSTATUS}"
    fi
    CHANGESETSTATUS="${NEWCHANGESETSTATUS}"
    sleep 1
done

if [ "${CHANGESETSTATUS}" == "FAILED" ]; then
    echo "*** changeset failed"
    aws cloudformation describe-change-set --change-set-name ${CHANGESETNAME} --region ${REGION} --stack-name ${STACKNAME} --query "StatusReason" --output text
    exit 1
fi

echo "    changeset succeeded"

echo "Execute changeset ..."
aws cloudformation execute-change-set --change-set-name ${CHANGESETNAME} --region ${REGION} --stack-name ${STACKNAME}
if [ "$?" != "0" ]; then
    echo "*** changeset execution failed"
    exit 1
fi

STATE="INIT"

while [[ ${STATE} != *_COMPLETE ]] && [[ ${STATE} != *_FAILED ]]; do
    NEWSTATE="$(aws cloudformation describe-stacks --stack-name ${STACKNAME} --region ${REGION} --query 'Stacks[*].StackStatus' --output text)"
    if [ "${NEWSTATE}" != "${STATE}" ]; then
        echo "    ${NEWSTATE}"
    fi
    STATE="${NEWSTATE}"
    sleep 1
done

if [ "${STATE}" == *"_FAILED" ]; then
    echo "*** changeset execution failed"
    exit 1
fi

if [ "${STATE}" == "ROLLBACK"* ]; then
    echo "    changeset execution rolled back"
    exit 1
fi

echo "    changeset execution succeeded"

