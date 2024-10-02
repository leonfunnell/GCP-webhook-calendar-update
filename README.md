  Webhook-based Application with GCP and GitHub Actions

Webhook-based Application with GCP and GitHub Actions
=====================================================

This project sets up a webhook-based application using Google Cloud Platform (GCP) and GitHub Actions. The application accepts a JSON payload from Google Appsheet and interacts with Google Calendar.

Prerequisites
-------------

*   [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
*   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
*   [GitHub Account](https://github.com/)
*   [Google Cloud Account](https://cloud.google.com/)

Setup
-----

1.  **Clone the repository**:
    
        git clone https://github.com/yourusername/your-repo.git
        cd your-repo
    
2.  **Set up environment variables**:
    
    Create a `.env` file in the root directory and add the following:
    
        GCP_PROJECT_ID=your-gcp-project-id
        GCP_REGION=your-gcp-region
        GOOGLE_DEFAULT_CALENDAR_ID=your-default-calendar-id
        GOOGLE_APPSHEET_APP_ID=your-appsheet-app-id
        GCP_GOOGLE_CALENDAR_SERVICE_ACCOUNT_EMAIL=your-service-account-email
        HEADER_SOURCE_TO_PASS=your-header-source
    
3.  **Set up secrets in GitHub**:
    
    Go to your GitHub repository settings and add the following secrets:
    
    *   GOOGLE\_APPSHEET\_ACCESS\_KEY
    *   GCP\_SA\_KEY
    *   GCP\_SERVICE\_ACCOUNT\_SECRET
    *   GCP\_WORKLOAD\_IDENTITY\_PROVIDER

Deployment
----------

1.  **Initialize Terraform**:
    
        terraform init
    
2.  **Apply Terraform configuration**:
    
        terraform apply -auto-approve
    
3.  **Deploy using GitHub Actions**:
    
    Push your changes to the `main` branch. GitHub Actions will automatically deploy the infrastructure and the Cloud Function.
    

Usage
-----

1.  **Webhook Endpoint**:
    
    The webhook endpoint is defined in the `openapi.yaml` file:
    
        openapi: 3.0.0
        info:
          title: Webhook API
          version: 1.0.0
        paths:
          /:
            post:
              summary: Webhook endpoint
              operationId: webhook
              requestBody:
                required: true
                content:
                  application/json:
                    schema:
                      type: object
              responses:
                '200':
                  description: Success
                '401':
                  description: Unauthorized
    
2.  **Send a JSON payload**:
    
    Send a POST request to the deployed endpoint with the required JSON payload.
    

Contributing
------------

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature-branch`).
3.  Commit your changes (`git commit -am 'Add new feature'`).
4.  Push to the branch (`git push origin feature-branch`).
5.  Create a new Pull Request.

License
-------

This project is licensed under the MIT License.