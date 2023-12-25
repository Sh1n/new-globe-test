variable "billing_account_id" {
  type        = string
  description = "The id of the associated billing account"
  nullable    = false
}
variable "org_id" {
  type        = string
  description = "The organization under which the project is created"
  nullable    = false
}
variable "project_id" {
  type        = string
  description = "The id of the created project."
  nullable    = false
}
variable "randomize_project_id" {
  type        = string
  description = "Set to true in order to attach a random string at the end of the project id, useful when testing."
  nullable    = false
  default     = false
}
variable "project_name" {
  type        = string
  description = "The name of the created project"
  nullable    = false
}
variable "region" {
  type        = string
  description = "The region to create the project in"
  default     = "europe-west1"
  nullable    = false
}
variable "zone" {
  type        = string
  description = "The zone to create the project in"
  default     = "europe-west1-b"
  nullable    = false
}
variable "location" {
  type        = string
  description = "The location to create the bucket in"
  default     = "EU"
  nullable    = false
}

variable "project_service_account_id" {
  type        = string
  description = "The account id of the main service account associated to the project"
  default     = "automation-iaac"
  nullable    = false
}

variable "project_service_account_name" {
  type        = string
  description = "The display name of the main service account associated to the project"
  default     = "Iaac Automation"
  nullable    = false
}

variable "environment" {
  type = string
  description = "Which environment this provisioning is running for ?"
  default = "dev"
  nullable = false
}


variable "datasets_configuration" {
  type = map(object({
    name = string
    location = string
    tables = list(object({
      name = string
      pattern = string
    }))
  }))
  description = "The configuration of the datasets to be shared between DL and DWH"
  default = {
    test_dataset: {
      name: "Test Dataset",
      location: "EU",
      tables: [
        # We assume all data are staged in the root of the DL, and that the filenames might contain some date reference
        # BQ does not support multiple asterisk in the pattern
        {
          name: "pupil_data",
          pattern: "PupilData*.csv"
        },
        {
          name: "pupil_attendance",
          pattern: "PupilAttendance*.csv"
        },
      ]
    }
  }
}