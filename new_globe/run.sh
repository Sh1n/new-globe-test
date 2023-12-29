#!/bin/bash
set -e

BASE_FOLDER=$(dirname "$0")
CONFIG_VARS_FILE=$BASE_FOLDER/../output.vars
DWH_GSA_KEY_FILE=$BASE_FOLDER/../dwh_service_account.json
COMMAND=${@:-run}

# Configure the dataset here since the IAAC supports multiple of those
BQ_DATASET="exercise_dataset"
BQ_LOCATION="EU"

if [ ! -f $CONFIG_VARS_FILE ]
then
    echo "File does not exists, run IAAC provisioning first" >/dev/stderr
    exit 1
fi

source $CONFIG_VARS_FILE
BQ_GSA_KEY_FILE=$DWH_GSA_KEY_FILE \
DBT_PROFILES_DIR=$BASE_FOLDER \
BQ_DATASET=$BQ_DATASET \
BQ_LOCATION=$BQ_LOCATION \
PROJECT_ID=$PROJECT_ID dbt $COMMAND