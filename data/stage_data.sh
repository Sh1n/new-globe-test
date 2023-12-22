#!/bin/bash

BASE_FOLDER=$(dirname "$0")
echo "Staging data..."
echo "$BASE_FOLDER"
echo "Files to stage:"
ls $BASE_FOLDER/*.csv
echo "Uploading to"

# gcloud storage cp $BASE_FOLDER/*.csv gs://DESTINATION_BUCKET_NAME/