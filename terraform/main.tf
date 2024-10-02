# terraform/main.tf
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  credentials = file(var.gcp_sa_key)
}

resource "google_service_account" "calendar_sa" {
  account_id   = "calendar-sa"
  display_name = "Calendar Service Account"
}

resource "google_secret_manager_secret" "calendar_sa_secret" {
  secret_id = "GCP_GOOGLE_CALENDAR_SERVICE_ACCOUNT_SECRET"
  replication {
	automatic = true
  }
}

resource "google_secret_manager_secret_version" "calendar_sa_secret_version" {
  secret      = google_secret_manager_secret.calendar_sa_secret.id
  secret_data = google_service_account_key.calendar_sa_key.private_key
}

resource "google_service_account_key" "calendar_sa_key" {
  service_account_id = google_service_account.calendar_sa.name
}

resource "google_cloudfunctions_function" "webhook_function" {
  name        = "webhook-function"
  runtime     = "python39"
  entry_point = "main"
  source_archive_bucket = google_storage_bucket.function_source.bucket
  source_archive_object = google_storage_bucket_object.function_source.name
  trigger_http = true
  environment_variables = {
	GOOGLE_DEFAULT_CALENDAR_ID = var.google_default_calendar_id
	HEADER_SOURCE_TO_PASS = var.header_source_to_pass
	GCP_SERVICE_ACCOUNT_SECRET = google_secret_manager_secret_version.calendar_sa_secret_version.secret_data
  }
}

resource "google_storage_bucket" "function_source" {
  name     = "${var.gcp_project_id}-function-source"
  location = var.gcp_region
}

resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_source.name
  source = "functions/function-source.zip"
}

resource "google_api_gateway_api" "api_gateway" {
  api_id = "webhook-api"
}

resource "google_api_gateway_api_config" "api_config" {
  api      = google_api_gateway_api.api_gateway.api_id
  location = var.gcp_region
  openapi_documents {
	document {
	  path     = "terraform/openapi.yaml"
	  contents = file("terraform/openapi.yaml")
	}
  }
}

resource "google_api_gateway_gateway" "gateway" {
  api      = google_api_gateway_api.api_gateway.api_id
  location = var.gcp_region
  gateway_id = "webhook-gateway"
}