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
  depends_on = [ google_project.default ]
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