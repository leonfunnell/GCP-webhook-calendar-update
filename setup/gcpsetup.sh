#!/bin/bash
# This script will create a GCP project (or reuse an existing one) and enable the required APIs for the application.
# It will create an IAM service account in your GCP project that has permission to deploy all the required resources for the application.
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
# - (To use an existing project) You have an active GCP project and you've set the GCP_PROJECT_ID environment variable.
# - (To create a new project) You have set the GCP_PROJECT_NAME environment variable.  If you have a single billing account, we will attempt to find and assign it to the new project
# - If you have multiple active billing accounts, You must set the GCP_BILLING_ACCOUNT_ID environment variable
# - gcloud CLI has the required permissions to create service accounts and assign roles (roles/iam.serviceAccountAdmin, roles/iam.serviceAccountKeyAdmin, roles/iam.roleAdmin)
# - 

# create error handler
set -e
source ~/initprojectvars.sh
# parse command line arguments and set variables. Allow only one of --force or --reuse

# accept key:value pairs as arguments, including: GCP_PROJECT_ID, GCP_PROJECT_NAME, GCP_BILLING_ACCOUNT_ID, BUILD_SERVICE_ACCOUNT_NAME, BUILD_SERVICE_ACCOUNT_DISPLAY_NAME
while [ "$1" != "" ]; do
    case $1 in
        --GCP_PROJECT_ID=* )
            GCP_PROJECT_ID="${1#*=}"
            ;;
        --GCP_PROJECT_NAME=* )
            GCP_PROJECT_NAME="${1#*=}"
            ;;
        --GCP_BILLING_ACCOUNT_ID=* )
            GCP_BILLING_ACCOUNT_ID="${1#*=}"
            ;;
        --BUILD_SERVICE_ACCOUNT_NAME=* )
            BUILD_SERVICE_ACCOUNT_NAME="${1#*=}"
            ;;
        --BUILD_SERVICE_ACCOUNT_DISPLAY_NAME=* )
            BUILD_SERVICE_ACCOUNT_DISPLAY_NAME="${1#*=}"
            ;;
        --force )               if [ "$REUSE" == "true" ]; then
                                    echo "Cannot use both --force and --reuse options together."
                                    exit 1
                                fi
                                FORCE="true"
                                ACCOUNT_MODE="force"
                                echo "Using --force option. Existing service account will be deleted."
                                ;;
        --reuse )               if [ "$FORCE" == "true" ]; then
                                    echo "Cannot use both --force and --reuse options together."
                                    exit 1
                                fi
                                REUSE="true"
                                ACCOUNT_MODE="reuse"
                                echo "Using --reuse option. Existing service account will be reused."
                                ;;
        * )
            echo "Invalid argument: $1"
            exit 1
    esac
    shift
done
# output all known variables
echo "GCP_PROJECT_ID: $GCP_PROJECT_ID"
echo "GCP_PROJECT_NAME: $GCP_PROJECT_NAME"
echo "GCP_BILLING_ACCOUNT_ID: $GCP_BILLING_ACCOUNT_ID"
echo "BUILD_SERVICE_ACCOUNT_NAME: $BUILD_SERVICE_ACCOUNT_NAME"
echo "BUILD_SERVICE_ACCOUNT_DISPLAY_NAME: $BUILD_SERVICE_ACCOUNT_DISPLAY_NAME"
echo "FORCE: $FORCE"
echo "REUSE: $REUSE"
echo "ACCOUNT_MODE: $ACCOUNT_MODE"


# check if GCP_PROJECT_ID is set
if [ -z "$GCP_PROJECT_ID" ]
then
    # check if the GCP_PROJECT_NAME is set
    if [ -z "$GCP_PROJECT_NAME" ]
    then
        echo "Please set EITHER the GCP_PROJECT_NAME (for a new project) or GCP_PROJECT_ID (for an existing project) environment variable!"
        exit 1
    else
        PROJECT_NAME="$GCP_PROJECT_NAME"
        # check if the project already exists
        PROJECT_EXISTS=$(gcloud beta projects list --filter="name ='$PROJECT_NAME'" --format="value(projectId)")
        if [ -n "$PROJECT_EXISTS" ]
        then
            PROJECT_ID=$(gcloud beta projects list --filter="name ='$PROJECT_NAME'" --format="value(projectId)")
            echo "Project $PROJECT_NAME already exists with ID $PROJECT_ID"
        else
            # create the project in GCP
            echo "Creating a new project in GCP: $GCP_PROJECT_NAME"
            # create a string from our project name to use for the project ID, with all lowercase, hyphens for spaces, and a random number suffix
            PROJECT_ID=$(echo $PROJECT_NAME | tr '[:upper:]' '[:lower:]' | tr ' ' '-')-$(shuf -i 1000-9999 -n 1)
            gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"
            # set the project ID
            PROJECT_ID=$(gcloud projects describe $PROJECT_NAME --format="value(projectId)")
            export GCP_PROJECT_ID=$PROJECT_ID
        fi

    fi
else
    echo "Using existing project: $GCP_PROJECT_ID"
    PROJECT_ID=$GCP_PROJECT_ID
fi

# Find the billing account ID
if [ -z "$GCP_BILLING_ACCOUNT_ID" ]
then
    # retrieve active billing accounts
    BILLING_ACCOUNTS=$(gcloud beta billing accounts list --filter=open=true --format="value(ACCOUNT_ID)")
    # count the number of rows in the output
    NUM_BILLING_ACCOUNTS=$(echo $BILLING_ACCOUNTS | wc -l)
    # if there is only one billing account, use it
    if [ $NUM_BILLING_ACCOUNTS -eq 1 ]
    then
        BILLING_ACCOUNT_ID=$BILLING_ACCOUNTS
        export GCP_BILLING_ACCOUNT_ID=$BILLING_ACCOUNT_ID
    else
        echo "Multiple billing accounts found. Please set the GCP_BILLING_ACCOUNT_ID environment variable to the desired billing account ID."
        exit 1
    fi
else
    BILLING_ACCOUNT_ID=$GCP_BILLING_ACCOUNT_ID
fi
echo "Using billing account ID: $BILLING_ACCOUNT_ID"

# set the project in gcloud
echo "Setting the project in gcloud to $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

# enable billing for our project, using the billing account ID we found
gcloud beta billing projects link $PROJECT_ID --billing-account $BILLING_ACCOUNT_ID

# enable the required APIs (requires billing to be enabled)
gcloud services enable \
    cloudfunctions.googleapis.com \
    secretmanager.googleapis.com \
    apigateway.googleapis.com \
    storage-component.googleapis.com  \
    compute.googleapis.com --billing-account $BILLING_ACCOUNT_ID

# check if BUILD_SERVICE_ACCOUNT_NAME is set
if [ -z "$BUILD_SERVICE_ACCOUNT_NAME" ]
then
    # use a default service account name
    SERVICE_ACCOUNT_NAME="build-sa"
    export BUILD_SERVICE_ACCOUNT_NAME=$SERVICE_ACCOUNT_NAME
else
    SERVICE_ACCOUNT_NAME="$BUILD_SERVICE_ACCOUNT_NAME"
fi

# check if BUILD_SERVICE_ACCOUNT_DISPLAY_NAME is set
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
    SERVICE_ACCOUNT_EXISTS="true"
fi

# if running with --force and service account exists, delete the service account
if [ "$SERVICE_ACCOUNT_EXISTS" == "true" ] 
then 
    if [ "$ACCOUNT_MODE" == "force" ]
    then
        echo "removing existing roles from service account: $SERVICE_ACCOUNT_NAME"
        gcloud projects remove-iam-policy-binding $PROJECT_ID \
            --member "serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
            --role "roles/iam.serviceAccountAdmin" \
            --role "roles/storage.admin" \
            --role "roles/secretmanager.admin" \
            --role "roles/apigateway.admin" \
            --role "roles/cloudfunctions.admin" \
            --role "roles/resourcemanager.projectIamAdmin" \
            --quiet
        echo "Deleting service account: $SERVICE_ACCOUNT_NAME"
        gcloud iam service-accounts delete $SERVICE_ACCOUNT_EMAIL --project $PROJECT_ID --quiet
        SERVICE_ACCOUNT_EXISTS="false"
    elif [ "$ACCOUNT_MODE" == "reuse" ]
    then
        echo "Reusing existing service account: $SERVICE_ACCOUNT_EMAIL"
    fi
else
    # Create the service account
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name "$SERVICE_ACCOUNT_DISPLAY_NAME" \
        --project $PROJECT_ID
fi

# Assign roles to the service account
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member "serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
            --role "roles/iam.serviceAccountAdmin" \
            --role "roles/storage.admin" \
            --role "roles/secretmanager.admin" \
            --role "roles/apigateway.admin" \
            --role "roles/cloudfunctions.admin" \
            --role "roles/resourcemanager.projectIamAdmin" \
            --quiet
# Export a key for the service account in JSON format
gcloud iam service-accounts keys create $KEY_FILE_PATH \
    --iam-account $SERVICE_ACCOUNT_EMAIL \
    --project $PROJECT_ID

# Output the service account email and key file path
if [ "$SERVICE_ACCOUNT_EXISTS" == "true" ]
then
    echo "Service account updated: $SERVICE_ACCOUNT_EMAIL"
else
    echo "Service account created: $SERVICE_ACCOUNT_EMAIL"
fi.
echo "Key file created: $KEY_FILE_PATH"
export GOOGLE_CREDENTIALS_FILE=$KEY_FILE_PATH
export BUILD_SERVICE_ACCOUNT_EMAIL=$SERVICE_ACCOUNT_EMAIL
export BUILD_SERVICE_ACCOUNT_DISPLAY_NAME=$SERVICE_ACCOUNT_DISPLAY_NAME
export BUILD_SERVICE_ACCOUNT_NAME=$SERVICE_ACCOUNT_NAME
echo "BUILD_SERVICE_ACCOUNT_DISPLAY_NAME: $BUILD_SERVICE_ACCOUNT_DISPLAY_NAME"
echo "BUILD_SERVICE_ACCOUNT_NAME: $BUILD_SERVICE_ACCOUNT_NAME"
echo "BUILD_SERVICE_ACCOUNT_EMAIL: $BUILD_SERVICE_ACCOUNT_EMAIL"
echo "GOOGLE_CREDENTIALS_FILE: $GOOGLE_CREDENTIALS_FILE"