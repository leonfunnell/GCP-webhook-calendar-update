GCP Webhook-based Application
=============================

This project sets up a serverless API that recieves a JSON structure and creates/updates/deletes Google Calendar entries.  It's all deployed using GitHub Actions, Terraform, and Google Cloud Platform.

It's designed to be fully automated, all you need is an existing GitHub and GCP account, an existing set of Google Calendars you want to sync with a JSON structure, and ideally a JSON emitter source.  I use an app I created in Google AppSheet.

Most of the code was created using GitHub Co-Pilot (based on ChatGPT 4o).  The AI intents used are in the AI Intents folder for your reference.  Be aware that this resulted in a somewhat broken project (as is usually the case when using AI) so I had to re-write a sizeable amount of it manually afterwards.  ChatGPT made a lot of halucinations about how to use various Terraform and GitHub Actions commands.

I do make heavy use of the Co-Pilot auto-complete function in VSCode - it's an absolute game-changer.  If you've not tried it, I highly recommend you do!

## It will do the following:
- **Create a service account in GCP*** with the appropriate permissions to deploy all the resources, using a BASH script you run on your local terminal
- **Run deploy.yml in GitHub Actions**, which pulls repository variables and secrets from GitHub.  These can be defined by running the script or manually entering them in "settings/Secrets and Variables/Actions".  You can either define them at the Repository level or Environment level (such as Dev, QA, Prod)
- **Run Two terraform templates.**  
    - **The first (backend.tf)** is generated dynamically in GitHub Actions to connect to our TF_STATE_BUCKET.  We do this dynamically as it's not possible to use a variable for the bucket name for the gcs provider. GitHub actions uses ephemeral runners, and any state files stored on the filesystem of the runner are lost.  This way we can keep track of the state of our GCP resources across runs. 
    - **The second (main.tf)** creates all the GCP resources:
        - A service account to run our Python code in Cloud Functions with permissions to read secrets and manage Google Calendar entries
        - Storage for secrets to connect to GCP, Google Calendar, Google Appsheet, etc in Google Secrets Manager
        - A Bucket to store the Python code
        - An API Gateway instance to recieve our webhook/JSON payload and send it to the cloud function
        - The Cloud Function with the Python code
- 

# Setup
-----

## Prerequisists:
- You have a valid GCP account and project with admin role
- You have gcloud CLI installed and authenticated in BASH.  Type:
```
gcloud auth login
```
- You have gh > 2.45 installed (required for gh variables)
- gh is authenticated with your github repo.  Type:
```
gh auth login
```
- You need to provide the following:
    - GCP_PROJECT_ID (an existing project ID) - If you neglect to provide this, we will use the PROJECT_ID associated with the gcloud CLI 
    - --or--
    - GCP_PROJECT_NAME - the name for your new GCP project.  It will create your project and enable the required APIs    
    - GCP_REGION (GCP region code such as us-east1, europe-west2, see https://gist.github.com/rpkim/084046e02fd8c452ba6ddef3a61d5d59)
    - HEADER_SOURCE_TO_PASS - A key/value pair delimited by colon (:) which will be used to prevent unathenticated calls to your webhook address.  

- Optional variables
    - Build account name (the name of an IAM user that will get created by gcpsetup.sh.  It will be given permission to create the required resources in GCP).  If you neglect to provide this, a name with a random suffix will be generated.
    - TF_STATE_BUCKET - the name for a bucket to store the Terraform state file(s).  If you neglect to provide this, the bucket will be created using your GCP_PROJECT_ID and a random identifier
    - GOOGLE_DEFAULT_CALENDAR_ID - The ID of your central calendar for bookings entries.  We will use the default for your Google account if you don't provide this
    - CALENDAR_SERVICE_ACCOUNT_NAME - The name you wish to use for the service account that will have permissions to run your Cloud Function, and to read, create, update, delete calendar entries.  We will generate this if you don't specify it
    - 
# Instructions
1. Fork this repository into your own Github account
2. Run the following (to create a build account in GCP and output a JSON credentials file on your local filesystem):
```
cd /setup
export GCP_PROJECT_ID=<your GCP Project ID>
export BUILD_SERVICE_ACCOUNT_NAME=<Build service account name, like build-sa>
export BUILD_SERVICE_ACCOUNT_DISPLAY_NAME=<Build account display name, like "Account for building our resources">
chmod +x gcpsetup.sh
./gcpsetup.sh 
```
3. (Option 1) Run the following to populate your GitHub Actions secrets and variables from the BASH environment variables:
```
# set the following variables:
GITHUB_REPO=<your-username/your-repo>
GOOGLE_CREDENTIALS_FILE=<build service account name>.json
GCP_PROJECT_ID=<GCP Project ID>
GCP_REGION=<GCP Region Code>
GCP_CALENDAR_SERVICE_ACCOUNT_DISPLAY_NAME=<the display name you'd like to use for your function service account>
GCP_CALENDAR_SERVICE_ACCOUNT_NAME=<the ID you'd like to use for your function service account>
GCP_CALENDAR_SERVICE_ACCOUNT_EMAIL=SERVICE_ACCOUNT_EMAIL="${GCP_CALENDAR_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
GOOGLE_DEFAULT_CALENDAR_ID=<the calendar ID for your default calendar, usually your GMAIL address>
GOOGLE_APPSHEET_APP_ID=<Appsheet ID>
GOOGLE_APPSHEET_ACCESS_KEY=<the secret access key from Google Appsheet>

./ghvariablessetup.sh
```

3. (Option 2):
  Set the following GitHub Actions secrets:
    *   GOOGLE_CREDENTIALS (contents of <build service account name> json file)
    *   GOOGLE\_APPSHEET\_ACCESS\_KEY
  And set the following GitHub Actions variables:
    *   GCP\_PROJECT\_ID
    *   GCP\_REGION
    *   GCP\_CALENDAR_SERVICE\_ACCOUNT (account name for your function service account)
    *   GOOGLE\_DEFAULT\_CALENDAR\_ID
    *   GOOGLE\_APPSHEET\_APP\_ID
    *   HEADER\_SOURCE\_TO\_PASS

4.  Push changes to the `main` branch to trigger the GitHub Actions workflow.

Terraform Configuration
-----------------------

The Terraform configuration sets up the following resources in GCP:

*   Service Account for Google Calendar
*   Secrets in GCP Secrets Manager
*   Python Cloud Function
*   API Gateway

Python Cloud Function
---------------------

The Python Cloud Function handles webhook requests and interacts with the Google Calendar API.

Sample JSON Structure
---------------------
```
\[
    {
        "Row ID": "ZVy7\_iWwPu4HmuSqhhP4id",
        "ID": "cf9342de",
        "name": "Jon Doe",
        "status": "Confirmed",
        "pick up date": "16/10/2024",
        "return date": "23/10/2024",
        "duration": "7",
        "box": "Thule 460l Motion 800 XT",
        "price/day": "£8.00",
        "Extra item": "",
        "extra price": "",
        "fitting charge": "£0.00",
        "price": "£56.00",
        "Deposit": "£200.00",
        "bars needed": "Raised rails",
        "car": "Audi A6 AllRoad 2015",
        "contact": "online form",
        "phone": "+447796123456",
        "confirmed": "",
        "comment": "",
        "bar daily price": "£1.00",
        "box daily price": "£7.00",
        "Category": "Green",
        "SMS Notify": "Y",
        "Blank": "",
        "Entry": "10/09/2024 17:38:17",
        "Last Change": "02/10/2024 11:13:55",
        "Registration": "AB15JKL",
        "Make": "",
        "Model": "",
        "Type": "",
        "Trim": "",
        "Email Notify": "Y",
        "Email Address": "john\_doe@email.com",
        "Collection Agreed": "Y",
        "Collection Appointment": "16/10/2024 20:30:00",
        "CollectCalendarID": "e4j6evpsd3cjvlgd7rq44avjtk",
        "Return Agreed": "Y",
        "Return Appointment": "23/10/2024 12:30:00",
        "ReturnCalendarID": "7d48jmjol7dp7ig870st1nqgg",
        "BoxCalID": "",
        "SMS Enabled": "Y",
        "Email enabled": "Y",

    }
\]```