#!/bin/bash
set -e

BASE_FOLDER=$(dirname "$0")
CONFIG_VARS_FILE=$BASE_FOLDER/../output.vars
DBT_GSA_KEY_FILE=$BASE_FOLDER/../dwh_service_account.json

# Configure the dataset here since the IAAC supports multiple of those
BQ_DATASET="exercise_dataset"
BQ_LOCATION="EU"

if [ ! -f $CONFIG_VARS_FILE ]
then
    echo "File does not exists, run IAAC provisioning first" >/dev/stderr
    exit 1
fi

source $CONFIG_VARS_FILE
if [ -z ${DOCS_BUCKET_NAME+x} ];
then 
    echo "Variable DOCS_BUCKET_NAME does not exists or is empty, check IAAC provisioning first" >/dev/stderr
    exit 1
fi

if [ -z ${PROJECT_ID+x} ];
then 
    echo "Variable PROJECT_ID does not exists or is empty, check IAAC provisioning first" >/dev/stderr
    exit 1
fi

if [ -z ${DBT_GSA+x} ];
then 
    echo "Variable DBT_GSA does not exists or is empty, check IAAC provisioning first" >/dev/stderr
    exit 1
fi

echo "Generating documentation"
BQ_GSA_KEY_FILE=$DBT_GSA_KEY_FILE \
DBT_PROFILES_DIR=$BASE_FOLDER \
BQ_DATASET=$BQ_DATASET \
BQ_LOCATION=$BQ_LOCATION \
PROJECT_ID=$PROJECT_ID dbt docs generate

echo "Uploading documentation..."
echo "Uploading to $DOCS_BUCKET_NAME"


gcloud auth activate-service-account $DBT_GSA --project=$PROJECT_ID --key-file=$DBT_GSA_KEY_FILE
# We assume that the content of the target and compiled files are available to everyone
CLOUDSDK_CORE_ACCOUNT=$DBT_GSA gcloud storage cp $BASE_FOLDER/target/* gs://$DOCS_BUCKET_NAME/