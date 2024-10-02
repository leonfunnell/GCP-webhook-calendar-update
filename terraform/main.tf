# main.tf
provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.GCP_REGION
}

resource "google_service_account" "cloud_function_sa" {
  account_id   = "cloud-function-sa"
  display_name = "Cloud Function Service Account"
}

resource "google_project_iam_member" "cloud_function_sa_roles" {
  for_each = toset([
    "roles/cloudfunctions.invoker",
    "roles/iam.serviceAccountUser",
    "roles/secretmanager.secretAccessor",
    "roles/calendar.admin"
  ])
  project = var.GCP_PROJECT_ID
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
  role    = each.value
}

resource "google_cloudfunctions_function" "webhook_function" {
  name        = "webhook-function"
  runtime     = "python39"
  entry_point = "main"
  source_archive_bucket = google_storage_bucket.function_source_bucket.name
  source_archive_object = google_storage_bucket_object.function_source_archive.name
  trigger_http = true
  service_account_email = google_service_account.cloud_function_sa.email
}

resource "google_api_gateway_api" "api_gateway" {
  api_id = "webhook-api"
}

resource "google_api_gateway_api_config" "api_config" {
  api      = google_api_gateway_api.api_gateway.api_id
  location = var.GCP_REGION
  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = file("openapi.yaml")
    }
  }
}

resource "google_api_gateway_gateway" "gateway" {
  api_config = google_api_gateway_api_config.api_config.id
  gateway_id = "webhook-gateway"
  location   = var.GCP_REGION
}

resource "google_secret_manager_secret" "google_appsheet_access_key" {
  secret_id = "google_appsheet_access_key"
}

resource "google_secret_manager_secret_version" "google_appsheet_access_key_version" {
  secret = google_secret_manager_secret.google_appsheet_access_key.id
  secret_data = var.GOOGLE_APPSHEET_ACCESS_KEY
}

# Repeat for other secrets...