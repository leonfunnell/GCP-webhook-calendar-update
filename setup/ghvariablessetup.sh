#!/bin/bash
# This script will set the GitHub Actions environment secrets and variables required for the CI/CD pipeline.
source gcpsetup.sh
# Pre-requisites:
# check that gh is installed and in the PATH
if ! command -v gh &> /dev/null; then
    echo "gh CLI not found. Please install it from https://cli.github.com/"
    exit 1
fi
# check version of gh > 2.45.0.  Older versions don't support "gh variable set"
GH_VERSION=$(gh --version | head -n1 | cut -d ' ' -f 3)
MIN_GH_VERSION="2.45.0"
echo "gh CLI version is $GH_VERSION"
if [ "$(printf '%s\n' "$MIN_GH_VERSION" "$GH_VERSION" | sort -Vr | head -n1)" = "$MIN_GH_VERSION" ]; then
    echo "gh CLI version is less than $MIN_GH_VERSION. Please update to the latest version from https://cli.github.com/"
    exit 1
fi

# check that the user is authenticated with gh
if ! gh auth status; then
    echo "Please authenticate with GitHub using the 'gh auth login' command."
    exit 1
fi

if [ -z "$GITHUB_REPO" ]; then
    # pull from gh cli
    CURRENT_GITHUB_REPO=$(gh repo view --json nameWithOwner --template '{{.nameWithOwner}}')
    if [ -z "$CURRENT_GITHUB_REPO" ]; then
        echo "GITHUB_REPO was not set and we could not find an active repo. Please set the GITHUB_REPO environment variable!"
        exit 1
    else
        echo "GITHUB_REPO was not set. Using the repository: $CURRENT_GITHUB_REPO"
        GITHUB_REPO=$CURRENT_GITHUB_REPO
        export GITHUB_REPO
    fi
fi
REPO=$GITHUB_REPO

echo KEY_FILE_PATH=$KEY_FILE_PATH
echo BUILD_SERVICE_ACCOUNT_NAME=$BUILD_SERVICE_ACCOUNT_NAME
echo BUILD_SERVICE_ACCOUNT_DISPLAY_NAME=$BUILD_SERVICE_ACCOUNT_DISPLAY_NAME
echo BUILD_SERVICE_ACCOUNT_EMAIL=$BUILD_SERVICE_ACCOUNT_EMAIL
echo GCP_PROJECT_ID=$GCP_PROJECT_ID
echo GOOGLE_CREDENTIALS=$GOOGLE_CREDENTIALS
echo GOOGLE_DEFAULT_CALENDAR_ID=$GOOGLE_DEFAULT_CALENDAR_ID
echo GOOGLE_APPSHEET_APP_ID=$GOOGLE_APPSHEET_APP_ID
echo CALENDAR_SERVICE_ACCOUNT_NAME=$CALENDAR_SERVICE_ACCOUNT_NAME
echo CALENDAR_SERVICE_ACCOUNT_DISPLAY_NAME=$CALENDAR_SERVICE_ACCOUNT_DISPLAY_NAME
echo GOOGLE_APPSHEET_ACCESS_KEY=$GOOGLE_APPSHEET_ACCESS_KEY
echo HEADER_SOURCE_TO_PASS=$HEADER_SOURCE_TO_PASS
echo BUILD_SERVICE_ACCOUNT_EMAIL=$BUILD_SERVICE_ACCOUNT_EMAIL


if [ -z "$KEY_FILE_PATH" ]; then
    if [ -z "$BUILD_SERVICE_ACCOUNT_NAME" ]; then
        BUILD_SERVICE_ACCOUNT_NAME="build-sa"
        echo "BUILD_SERVICE_ACCOUNT_NAME is not set!"
        exit 1
    fi
    KEY_FILE_PATH="./${BUILD_SERVICE_ACCOUNT_NAME}-key.json"
fi

if [ -z "$GCP_PROJECT_ID" ]
then
    echo "Please set the GCP_PROJECT_ID environment variable!"
    exit 1
fi

# populate GOOGLE_CREDENTIALS from the key file if it is not set
if [ -z "$GOOGLE_CREDENTIALS" ]; then
  # if KEY_FILE_PATH variable exists, and also the file exists, then populate GOOGLE_CREDENTIALS
  if [ -f "$KEY_FILE_PATH" ]; then
    echo "Reading the key file $KEY_FILE_PATH for GOOGLE_CREDENTIALS"
    GOOGLE_CREDENTIALS=$(cat "$KEY_FILE_PATH")
    export GOOGLE_CREDENTIALS
  else
    echo "Error: Environment variable GOOGLE_CREDENTIALS is not set, and the key file $KEY_FILE_PATH does not exist."
    exit 1
  fi
else
  echo "GOOGLE_CREDENTIALS is already set."
fi

CALENDAR_SERVICE_ACCOUNT_EMAIL="${CALENDAR_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

VARIABLES=(
  "GCP_PROJECT_ID"
  "GCP_REGION"
  "GOOGLE_DEFAULT_CALENDAR_ID"
  "GOOGLE_APPSHEET_APP_ID"
  "CALENDAR_SERVICE_ACCOUNT_NAME"
  "CALENDAR_SERVICE_ACCOUNT_DISPLAY_NAME"
  "CALENDAR_SERVICE_ACCOUNT_EMAIL"
  "GOOGLE_APPSHEET_ACCESS_KEY"
)

SECRETS=(
  "GOOGLE_CREDENTIALS"
  "GOOGLE_APPSHEET_ACCESS_KEY"
  "HEADER_SOURCE_TO_PASS"
)

# Function to add a secret to the GitHub repository
add_secret() {
  local secret_name=$1
  local secret_value=$2
  echo "Adding secret: $secret_name"
  echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO"
}

# Function to add a variable to the GitHub repository
add_variable() {
  local var_name=$1
  local var_value=$2
  echo "Adding variable: $var_name"
  gh variable set "$var_name" --body "$var_value" --repo "$REPO"
}

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
