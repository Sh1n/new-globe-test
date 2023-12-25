# new-globe-test

## Provision the platform
* Install terraform if you do not have it already
```
brew install tfenv
tfenv use 1.6.6
```
* Install GCloud CLI: follow https://cloud.google.com/sdk/docs/install?hl=it
* Find the billing account id, it should come in the form XXX-YYYYY-ZZZZ
* Evaluate the file iaac/terraform.tfvars:
```
billing_account_id = "<billing account>"
org_id = "<your org id>"
project_id = "new-globe-test"
randomize_project_id = true
project_name = "new-globe-test"
```
* Provision the platform by issuing the following commands:
```
cd iaac
terraform init
terraform apply
```

## Stage data
Stage data to the data lake for ingestion, move the files to the data folder in this project. For privacy reason PupilAttendance.csv and PupilData.csv are not included (and ignored by this git project)

* Stage data by issuing the following commands:
```
cd data
./stage_data.sh
```

## DBT
Install DBT core with:
```
python3 -m venv dbt-env
source dbt-env/bin/activate
python -m pip install dbt-bigquery
```