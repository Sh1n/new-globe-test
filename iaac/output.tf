# I use this technique to dump some variables used by the shell scripts of staging and dbt. 
# On production, these pipelines would be separated, thus this step would not exist
resource "local_file" "variables" {
    filename = "../output.vars"
    content = <<EOT
DATALAKE_BUCKET_NAME=${google_storage_bucket.data-lake.name}
DOCS_BUCKET_NAME=${google_storage_bucket.dbt-docs.name}
PROJECT_ID=${google_project.default.project_id}
STORAGE_GSA=${google_service_account.dl_staging_service_account.email}
DBT_GSA=${google_service_account.dwh_dbt_service_account.email}
DOCS_PUBLIC_URL=https://storage.googleapis.com/${google_storage_bucket.dbt-docs.name}/
EOT
}

resource "local_file" "storage_service_account" {
  filename = "../storage_service_account.json"
  content = base64decode(google_service_account_key.dl_staging_service_account.private_key)
}

resource "local_file" "dwh_service_account" {
  filename = "../dwh_service_account.json"
  content = base64decode(google_service_account_key.dwh_dbt_service_account.private_key)
}

output "docs_website_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.dbt-docs.name}/"
}