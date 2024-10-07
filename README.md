GCP Webhook-based Application
=============================

This project sets up a webhook-based application using GitHub Actions, Terraform, and Google Cloud Platform.

It's designed to be fully automated, all you need is an existing GitHub and GCP account, an existing set of Google Calendars you want to sync with a JSON structure, and ideally a JSON emitter source.  I use an app I created in Google AppSheet.

Setup
-----

Prerequisists:
- You have a valid GCP account with admin role
- You have gcloud CLI installed and authenticated in BASH
- You have gh and git installed
- gh is authenticated with your github repo

1. Fork this repository into your own Github account
2. Run the following (to create a build account in GCP):
```cd /setup
chmod +x gcpsetup.sh
./gcpsetup.sh
```
3. (Option 1) Run the following to populate your GitHub Actions secrets and variables.

3. (Option 2)  Set the following GitHub Actions secrets:
    *   GOOGLE_CREDENTIALS  (account with deploy credentials)
    *   GCP\_PROJECT\_ID
    *   GCP\_REGION
    *   GCP\_SERVICE\_ACCOUNT
    *   GOOGLE\_DEFAULT\_CALENDAR\_ID
    *   GOOGLE\_APPSHEET\_APP\_ID
    *   GCP\_GOOGLE\_CALENDAR\_SERVICE\_ACCOUNT\_EMAIL
    *   HEADER\_SOURCE\_TO\_PASS
    *   GOOGLE\_APPSHEET\_ACCESS\_KEY
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