#!/bin/bash
set -e

BASE_FOLDER=$(dirname "$0")
CONFIG_VARS_FILE=$BASE_FOLDER/../output.vars
STORAGE_GSA_KEY_FILE=$BASE_FOLDER/../storage_service_account.json

if [ ! -f $CONFIG_VARS_FILE ]
then
    echo "File does not exists, run IAAC provisioning first" >/dev/stderr
    exit 1
fi

source $CONFIG_VARS_FILE
if [ -z ${DATALAKE_BUCKET_NAME+x} ];
then 
    echo "Variable DATALAKE_BUCKET_NAME does not exists or is empty, check IAAC provisioning first" >/dev/stderr
    exit 1
fi

if [ -z ${PROJECT_ID+x} ];
then 
    echo "Variable PROJECT_ID does not exists or is empty, check IAAC provisioning first" >/dev/stderr
    exit 1
fi

if [ -z ${STORAGE_GSA+x} ];
then 
    echo "Variable STORAGE_GSA does not exists or is empty, check IAAC provisioning first" >/dev/stderr
    exit 1
fi

echo "Staging data..."
echo "Uploading to $DATALAKE_BUCKET_NAME"


gcloud auth activate-service-account $STORAGE_GSA --project=$PROJECT_ID --key-file=$STORAGE_GSA_KEY_FILE
CLOUDSDK_CORE_ACCOUNT=$STORAGE_GSA gcloud storage cp $BASE_FOLDER/*.csv gs://$DATALAKE_BUCKET_NAME/