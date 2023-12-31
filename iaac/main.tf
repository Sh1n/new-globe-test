provider "google-beta" {
  alias  = "gcloud-user"
  region = var.region
  zone   = var.zone
}
data "google_billing_account" "account" {
  provider        = google-beta.gcloud-user
  billing_account = var.billing_account_id
}
data "google_client_config" "gcloud-user" {
  provider = google-beta.gcloud-user
}
data "google_client_openid_userinfo" "gcloud-user" {
  provider = google-beta.gcloud-user
}

resource "random_id" "project" {
  byte_length = 4
}


# ====================================================== #
#   Section 1: Set up project
# ====================================================== #

resource "google_project" "default" {
  provider        = google-beta.gcloud-user
  project_id      = var.randomize_project_id ? "${substr(var.project_id, 0, 21)}-${random_id.project.hex}" : var.project_id
  name            = var.project_name
  billing_account = data.google_billing_account.account.id
  org_id          = var.org_id
}

# ====================================================== #
#   Section 2: Set up data lake
# ====================================================== #
resource "google_storage_bucket" "data-lake" {
  depends_on = [ 
    google_project.default
  ]
  project = google_project.default.project_id
  name = var.randomize_project_id ? "${substr("data-lake-bucket", 0, 21)}-${random_id.project.hex}" : "data-lake-bucket"
  location      = var.location
  force_destroy = true
  uniform_bucket_level_access = true
  # I like to set different policy retention to the objects in order to optimize costs. These are just examples of policies:
  # Days:             [-inf], -361    | [-360, -91]   |   [-90, -31]  | [-30, 0]
  # StorageClass:     ARCHIVE         | COLDLINE      |   NEARLINE    | Standard
  lifecycle_rule {
    condition {
      age = 31 # Days
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 91 # Days
    }
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 361 # Days
    }
    action {
      type = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }
}
# I like to create scoped service account for read/write to the data lake
resource "google_service_account" "dl_staging_service_account" {
  project = google_project.default.project_id
  account_id   = "data-lake-ingestion-${lower(var.environment)}"
  display_name = "Data Lake Ingestion"
}
resource "google_service_account_key" "dl_staging_service_account" {
  service_account_id = google_service_account.dl_staging_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
# For the sake of simplicity we create a (not so) basic ACL
resource "google_storage_bucket_iam_member" "bucket_A" {
  bucket = google_storage_bucket.data-lake.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.dl_staging_service_account.email}"
  depends_on = [
    google_storage_bucket.data-lake,
    google_service_account.dl_staging_service_account
  ]
}


# ====================================================== #
#   Section 3: Set up DWH
# ====================================================== #
resource "google_project_service" "project" {
  project = google_project.default.project_id
  service = "bigquery.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }
}

locals {
  

  # Do not alter after this. Is used to transform a human readable config into a terraform one!
  bg_tables = flatten([
    for ds_key, ds_config in var.datasets_configuration : [
      for table in ds_config.tables : {
        table_id: table.name,
        dataset_id: ds_key,
        pattern: table.pattern
      }
    ]
  ])
}

resource "google_bigquery_dataset" "dataset" {
  for_each = var.datasets_configuration
  project = google_project.default.project_id
  dataset_id                  = each.key
  friendly_name               = each.value.name
  location                    = each.value.location
  default_table_expiration_ms = 3600000 * 24 * 365 # 1 year
  

  labels = {
    env = var.environment
  }
}

resource "google_bigquery_table" "default" {
  for_each = {for i,v in local.bg_tables: i => v}
  project = google_project.default.project_id
  dataset_id = google_bigquery_dataset.dataset[each.value.dataset_id].dataset_id
  table_id   = each.value.table_id
  deletion_protection         = false
  external_data_configuration {
    autodetect    = true
    source_format = "CSV"
    source_uris = ["gs://${google_storage_bucket.data-lake.name}/${each.value.pattern}"]
  }
}

resource "google_service_account" "dwh_dbt_service_account" {
  project = google_project.default.project_id
  account_id   = "dwh-dbt-${lower(var.environment)}"
  display_name = "DWH DBT ${upper(var.environment)}"
}
resource "google_service_account_key" "dwh_dbt_service_account" {
  service_account_id = google_service_account.dwh_dbt_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_bigquery_dataset_iam_member" "editor" {
  for_each = var.datasets_configuration
  project = google_project.default.project_id
  dataset_id = google_bigquery_dataset.dataset[each.key].dataset_id
  role       = "roles/bigquery.admin"
  member = "serviceAccount:${google_service_account.dwh_dbt_service_account.email}"
  depends_on = [
    google_bigquery_dataset.dataset,
    google_service_account.dwh_dbt_service_account
  ]
}

# DBT might require to create bigquery jobs not associated to the dataset itself
# for this reason we do force the role at project level too.
resource "google_project_iam_member" "editor" {
  for_each = var.datasets_configuration
  project = google_project.default.project_id
  role       = "roles/bigquery.user"
  member = "serviceAccount:${google_service_account.dwh_dbt_service_account.email}"
  depends_on = [
    google_service_account.dwh_dbt_service_account
  ]
}

# Since the dbt source layer reads directly from the files, we do also need to associate the Storage Object Viewer role to
# the running service account
resource "google_storage_bucket_iam_member" "dbt_bucket_access" {
  bucket = google_storage_bucket.data-lake.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.dwh_dbt_service_account.email}"
  depends_on = [
    google_storage_bucket.data-lake,
    google_service_account.dwh_dbt_service_account
  ]
}


# ====================================================== #
#   Section 3: Set up bucket for DBT docs publishing
# ====================================================== #
resource "google_storage_bucket" "dbt-docs" {
  depends_on = [ 
    google_project.default
  ]
  project = google_project.default.project_id
  name = var.randomize_project_id ? "${substr("dbt-docs-bucket", 0, 21)}-${random_id.project.hex}" : "dbt-docs-bucket"
  location      = var.location
  force_destroy = true
  storage_class = "STANDARD"

  website {
    main_page_suffix = "index.html"
  }
}

# We assume the bucket can be accessed by everyone.
resource "google_storage_bucket_iam_member" "public_rule" {
  bucket = google_storage_bucket.dbt-docs.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
  depends_on = [
    google_storage_bucket.dbt-docs,
    google_service_account.dwh_dbt_service_account
  ]
}

resource "google_storage_bucket_iam_member" "dbt_docs_bucket_access" {
  bucket = google_storage_bucket.dbt-docs.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.dwh_dbt_service_account.email}"
  depends_on = [
    google_storage_bucket.dbt-docs,
    google_service_account.dwh_dbt_service_account
  ]
}