# I use this technique to dump some variables used by the shell scripts of staging and dbt. 
# On production, these pipelines would be separated, thus this step would not exist
resource "local_file" "variables" {
    filename = "../output.vars"
    content = <<EOT
DATALAKE_BUCKET_NAME=${google_storage_bucket.data-lake.name}
EOT
}