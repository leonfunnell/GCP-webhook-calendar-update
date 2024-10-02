GCP Webhook-based Application
=============================

This project sets up a webhook-based application using GitHub Actions, Terraform, and Google Cloud Platform.

Setup
-----

1.  Fork this repository.
2.  Set the following GitHub Actions secrets:
    *   GCP\_PROJECT\_ID
    *   GCP\_REGION
    *   GCP\_SERVICE\_ACCOUNT
    *   GOOGLE\_DEFAULT\_CALENDAR\_ID
    *   GOOGLE\_APPSHEET\_APP\_ID
    *   GCP\_GOOGLE\_CALENDAR\_SERVICE\_ACCOUNT\_EMAIL
    *   HEADER\_SOURCE\_TO\_PASS
    *   GOOGLE\_APPSHEET\_ACCESS\_KEY
    *   GCP\_SA\_KEY
3.  Push changes to the `main` branch to trigger the GitHub Actions workflow.

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

\[
    {
        "Row ID": "ZVy7\_iWwPu4HmuSqhhP4id",
        "ID": "cf9342de",
        "name": "Leon Funnell",
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
        "bars needed": "Flush rails",
        "car": "Audi A6 Allroad 2015",
        "contact": "online form",
        "phone": "+447786385814",
        "confirmed": "",
        "comment": "",
        "bar daily price": "£1.00",
        "box daily price": "£7.00",
        "Category": "Green",
        "SMS Notify": "Y",
        "Blank": "",
        "Entry": "10/09/2024 17:38:17",
        "Last Change": "02/10/2024 11:13:55",
        "Registration": "LV15URN",
        "Make": "",
        "Model": "",
        "Type": "",
        "Trim": "",
        "Email Notify": "Y",
        "Email Address": "leon\_funnell@hotmail.com",
        "Collection Agreed": "Y",
        "Collection Appointment": "16/10/2024 20:30:00",
        "CollectCalendarID": "e4j6evp0j3cjvlm97rq44avjtk",
        "Return Agreed": "Y",
        "Return Appointment": "23/10/2024 12:30:00",
        "ReturnCalendarID": "7d48jmjol7dp7ig870sta2nqgg",
        "BoxCalID": "",
        "SMS Enabled": "Y",
        "Email enabled": "Y",
        "\_\_IMTHEADERS\_\_": \[
            {
                "name": "connection",
                "value": "upgrade"
            },
            {
                "name": "x-real-ip",
                "value": "162.158.49.11"
            },
            {
                "name": "x-request-id",
                "value": "12c1ea1a2093e36518d9ffcb5dbc19fa"
            },
            {
                "name": "content-length",
                "value": "1070"
            },
            {
                "name": "accept-encoding",
                "value": "gzip, br"
            },
            {
                "name": "cf-ray",
                "value": "8cc3ecc7ac0fbf57-DUB"
            },
            {
                "name": "cf-visitor",
                "value": "{\\"scheme\\":\\"https\\"}"
            },
            {
                "name": "content-type",
                "value": "application/json"
            },
            {
                "name": "x-webhook-source",
                "value": "roofbox-webhook-router"
            },
            {
                "name": "user-agent",
                "value": "Make/production"
            },
            {
                "name": "x-datadog-trace-id",
                "value": "1509422687963197338"
            },
            {
                "name": "x-datadog-parent-id",
                "value": "1509422687963197338"
            },
            {
                "name": "x-datadog-sampling-priority",
                "value": "0"
            },
            {
                "name": "x-datadog-tags",
                "value": "\_dd.p.tid=66fd1cfc00000000"
            },
            {
                "name": "traceparent",
                "value": "00-66fd1cfc0000000014f28beffbf62f9a-14f28beffbf62f9a-00"
            },
            {
                "name": "tracestate",
                "value": "dd=t.tid:66fd1cfc00000000;t.dm:1;s:0"
            },
            {
                "name": "cf-connecting-ip",
                "value": "54.78.149.203"
            },
            {
                "name": "cdn-loop",
                "value": "cloudflare; loops=1"
            },
            {
                "name": "cf-ipcountry",
                "value": "IE"
            }
        \],
        "\_\_IMTMETHOD\_\_": "POST"
    }
\]