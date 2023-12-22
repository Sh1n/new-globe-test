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
