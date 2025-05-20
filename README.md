# Terraform GCP Static Website Deployment

This Terraform project deploys my resume hosted on Google Cloud Storage with a Cloud CDN-backed load balancer and a custom DNS record.

---

## Project Overview

- Creates a Google Cloud Storage bucket configured for static website hosting
- Uploads static assets (HTML, CSS, JS, images) to the bucket
- Makes these assets publicly accessible
- Sets up a global static IP and HTTP load balancer with CDN
- Creates a DNS A record pointing to the load balancer IP

---

## Prerequisites

- A Google Cloud Platform project with billing enabled
- Google Cloud SDK installed and authenticated
- Terraform installed (version 1.0+ recommended)
- Compute Engine API and Cloud DNS API enabled for your project
- A DNS managed zone created in Cloud DNS (e.g. `terraform-gcp` with DNS name `test.peterkigathi.cloud`)

---

## File Structure

├── main.tf               # Terraform configuration file
├── website/              # Static website assets (HTML, CSS, JS)
│   ├── index.html
│   ├── styles.css
│   └── script.js
├── .gitignore            # Git ignore file to exclude sensitive files
└── README.md             # This documentation file

