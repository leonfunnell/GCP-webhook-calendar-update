provider "google" {
  project     = var.GCP_PROJECT_ID
  region      = var.GCP_REGION
}

provider "google-beta" {
  project     = var.GCP_PROJECT_ID
  region      = var.GCP_REGION
}

resource "google_service_account" "my_calendar_sa" {
  account_id   = var.CALENDAR_SERVICE_ACCOUNT_NAME
  display_name = "Calendar Service Account"
}

resource "google_secret_manager_secret" "my_calendar_secret" {
  secret_id = var.CALENDAR_SECRET_NAME
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "my_calendar_secret_version" {
  secret      = google_secret_manager_secret.my_calendar_secret.id
  secret_data = google_service_account_key.my_calendar_sa_key.private_key
}

resource "google_service_account_key" "my_calendar_sa_key" {
  service_account_id = google_service_account.my_calendar_sa.name
}

resource "google_project_iam_member" "function_invoker_role" {
  project = var.GCP_PROJECT_ID
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.my_calendar_sa.email}"
}

resource "google_project_iam_member" "calendar_admin_role" {
  project = var.GCP_PROJECT_ID
  role    = "roles/calendar.admin"
  member  = "serviceAccount:${google_service_account.my_calendar_sa.email}"
}

resource "google_cloudfunctions_function" "webhook_function" {
  name        = "webhook-function"
  runtime     = "python39"
  entry_point = "main"
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.function_source.name
  trigger_http = true
  environment_variables = {
    GOOGLE_DEFAULT_CALENDAR_ID = var.GOOGLE_DEFAULT_CALENDAR_ID
    HEADER_SOURCE_TO_PASS = var.HEADER_SOURCE_TO_PASS
    GCP_SERVICE_ACCOUNT_SECRET = google_secret_manager_secret_version.my_calendar_secret_version.secret_data
  }
}

resource "google_storage_bucket" "function_source" {
  name     = "${var.GCP_PROJECT_ID}-function-source"
  location = var.GCP_REGION
}

resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_source.name
  source = "${path.module}/../functions/function-source.zip"
}

resource "google_api_gateway_api" "api_gateway" {
  provider = google-beta
  api_id   = "webhook-api"
}

resource "google_api_gateway_api_config" "api_config" {
  provider  = google-beta
  api       = google_api_gateway_api.api_gateway.api_id
  openapi_documents {
    document {
      path     = "${path.module}/openapi.yaml"
      contents = filebase64("${path.module}/openapi.yaml")
    }
  }
}

resource "google_api_gateway_gateway" "gateway" {
  provider  = google-beta
  api_config = google_api_gateway_api_config.api_config.id
  gateway_id = "webhook-gateway"
  region     = var.GCP_REGION
}

# Variable Declarations
variable "GCP_PROJECT_ID" {
  description = "The GCP project ID"
  type        = string
}

variable "GCP_REGION" {
  description = "The GCP region"
  type        = string
}

variable "GOOGLE_CREDENTIALS" {
  description = "The GCP credentials JSON object"
  type        = string
  sensitive   = true
}

variable "GOOGLE_DEFAULT_CALENDAR_ID" {
  description = "The default Google Calendar ID"
  type        = string
}

variable "HEADER_SOURCE_TO_PASS" {
  description = "The header source to pass"
  type        = string
}

variable "CALENDAR_SERVICE_ACCOUNT_NAME" {
  description = "The name of the calendar service account"
  type        = string
}

variable "CALENDAR_SECRET_NAME" {
  description = "The name of the calendar secret"
  type        = string
}