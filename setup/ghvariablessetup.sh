#!/bin/bash
# This script will set the GitHub Actions environment secrets and variables required for the CI/CD pipeline.

# Pre-requisites:
# check that gh is installed and in the PATH
if ! command -v gh &> /dev/null; then
    echo "gh CLI not found. Please install it from https://cli.github.com/"
    exit 1
fi

# check that the user is authenticated with gh
if ! gh auth status; then
    echo "Please authenticate with GitHub using the gh CLI."
    exit 1
fi

if [ -z "$GITHUB_REPO" ]; then
    # pull from gh cli
    GITHUB_REPO=$(gh repo view --json nameWithOwner --template '{{.nameWithOwner}}')
    if [ -z "$GITHUB_REPO" ]; then
        echo "Please set the GITHUB_REPO environment variable!"
        exit 1
    else
        echo "GITHUB_REPO was not set!"
        echo "Using the repository: $GITHUB_REPO"
        export GITHUB_REPO
    fi
fi
REPO=$GITHUB_REPO

if [ -z "$KEY_FILE_PATH" ]; then
    if [ -z "$BUILD_SERVICE_ACCOUNT_NAME" ]; then
        echo "BUILD_SERVICE_ACCOUNT_NAME is not set!"
        exit 1
    fi
    KEY_FILE_PATH="./${BUILD_SERVICE_ACCOUNT_NAME}-key.json"
fi

if [ -z "$GCP_PROJECT_ID" ]
then
    echo "Please set the GCP_PROJECT_ID environment variable!"
    exit 1
else

fi

VARIABLES=(
  "GCP_PROJECT_ID"
  "GCP_REGION"
  "GCP_SERVICE_ACCOUNT"
  "GOOGLE_DEFAULT_CALENDAR_ID"
  "GOOGLE_APPSHEET_APP_ID"
  "GCP_GOOGLE_CALENDAR_SERVICE_ACCOUNT_EMAIL"
  "HEADER_SOURCE_TO_PASS"
  "GOOGLE_APPSHEET_ACCESS_KEY"
)

# populate GOOGLE_CREDENTIALS from the key file
if [ -z "$GOOGLE_CREDENTIALS" ]; then
  GOOGLE_CREDENTIALS=$(cat "$KEY_FILE_PATH")
  export GOOGLE_CREDENTIALS
fi

SECRETS=(
  "GOOGLE_CREDENTIALS"
  "GOOGLE_APPSHEET_ACCESS_KEY"
  "HEADER_SOURCE_TO_PASS"
)

# Add secrets to the GitHub repository
for secret_name in "${SECRETS[@]}"; do
  secret_value=$(printenv "$secret_name")
  if [ -z "$secret_value" ]; then
    echo "Error: Environment variable $secret_name is not set."
    exit 1
  fi
  add_secret "$secret_name" "$secret_value"
done


# Add variables to the GitHub repository
for var_name in "${VARIABLES[@]}"; do
  var_value=$(printenv "$var_name")
  if [ -z "$var_value" ]; then
    echo "Error: Environment variable $var_name is not set."
    exit 1
  fi
  add_variable "$var_name" "$var_value"
done

echo "All secrets and variables have been added to the repository: $REPO"
