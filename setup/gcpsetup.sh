#!/bin/bash
# This script will create an IAM service account in your GCP project that has permission to deploy all the required resources for the application.
# It will output a JSON file that can be used for authentication in the CI/CD pipeline.
# Permissions include:
# - Storage Admin
# - IAM User Admin
# - API Gateways Admin
# - Cloud Functions Admin
# - Secret Manager Admin
# The accouunt will be deleted after all the resources are deployed.

# Pre-requisites:
# - gcloud CLI is installed and configured
# - You have an active GCP project and you've set the GCP_PROJECT_ID environment variable.  If you haven't set it, it will default to the current project in the gcloud config.
# - gcloud CLI has the required permissions to create service accounts and assign roles (roles/iam.serviceAccountAdmin, roles/iam.serviceAccountKeyAdmin, roles/iam.roleAdmin)
# - 


# Variables
if [ -z "$GCP_PROJECT_ID" ]
then
    # use gcloud to get the project ID
    PROJECT_ID=$(gcloud config get-value project)
    if [ -z "$PROJECT_ID" ]
    then
        echo "Please set the GCP_PROJECT_ID environment variable!"
        exit 1
    else
        echo "GCP_PROJECT_ID was not set!"
        echo "Using the project: $PROJECT_ID"
        export GCP_PROJECT_ID=$PROJECT_ID
    fi
fi

if [ -z "$BUILD_SERVICE_ACCOUNT_NAME" ]
then
    # use a default service account name
    SERVICE_ACCOUNT_NAME="build-sa"
    export BUILD_SERVICE_ACCOUNT_NAME=$SERVICE_ACCOUNT_NAME
else
    SERVICE_ACCOUNT_NAME="$BUILD_SERVICE_ACCOUNT_NAME"
fi

if [ -z "$BUILD_SERVICE_ACCOUNT_DISPLAY_NAME" ]
then
    # use a default service account display name
    SERVICE_ACCOUNT_DISPLAY_NAME="Build Service Account"
    export BUILD_SERVICE_ACCOUNT_DISPLAY_NAME=$SERVICE_ACCOUNT_DISPLAY_NAME
else    
    SERVICE_ACCOUNT_DISPLAY_NAME="$BUILD_SERVICE_ACCOUNT_DISPLAY_NAME"
fi

# Create a temporary directory to store the key file
TMPDIR=$(mktemp -d -t)
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE_PATH="$TMPDIR/${SERVICE_ACCOUNT_NAME}-key.json"

# check if service account exists, abort if it does
if gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL --project $PROJECT_ID &> /dev/null
then
    echo "Service account $SERVICE_ACCOUNT_NAME already exists. Please delete it before running this script, or run with --force to recreate it."
    exit 1
fi

# if running with --force, delete the service account
if [ "$1" == "--force" ]
then
    echo "Deleting service account: $SERVICE_ACCOUNT_NAME"
    gcloud iam service-accounts delete $SERVICE_ACCOUNT_EMAIL --project $PROJECT_ID --quiet
fi

echo "Creating service account: $SERVICE_ACCOUNT_NAME, with display name: $SERVICE_ACCOUNT_DISPLAY_NAME"

# Create the service account
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
    --display-name "$SERVICE_ACCOUNT_DISPLAY_NAME" \
    --project $PROJECT_ID

# Assign roles to the service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role "roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role "roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role "roles/secretmanager.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role "roles/apigateway.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role "roles/cloudfunctions.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role "roles/resourcemanager.projectIamAdmin"

# Export a key for the service account in JSON format
gcloud iam service-accounts keys create $KEY_FILE_PATH \
    --iam-account $SERVICE_ACCOUNT_EMAIL \
    --project $PROJECT_ID

# Output the service account email and key file path
echo "Service account created: $SERVICE_ACCOUNT_EMAIL"
echo "Key file created: $KEY_FILE_PATH"
export GOOGLE_CREDENTIALS_FILE=$KEY_FILE_PATH