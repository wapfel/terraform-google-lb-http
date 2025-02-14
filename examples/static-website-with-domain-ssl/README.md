# HTTPS load balancer with Cloud Storage Backend example (Including DNS & SSL)

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/terraform-google-modules/terraform-google-lb-http&working_dir=examples/static-website-with-domain-ssl&page=shell&tutorial=README.md)

This example creates a static website using a public Google Cloud Storage bucket containing basic html website files and exposes it behind a Cloud HTTPS load balancer and Cloud CDN with HTTP-to-HTTPS redirection. Additionally, this module creates a public DNS zone for a provided domain and corresponding DNS records, and it creates a Google-managed certificate for SSL.

If you do not have your own domain and would like to test the static website fuctionality, please see the [static-website-with-no-domain](../static-website-with-no-domain) example.
​
You can tweak this example to enable other functionalities such as:
​
- configuring custom CDN caching policies
- securely serving static assets from multiple cloud storage buckets (requires a custom url map to be provided)
- securely serving static and dynamic assets from backend buckets and backend services

## Resources created

**Figure 1.** *diagram of terraform resources*

![architecture diagram](../../modules/backend_bucket/Diagrams/Static_Website_with_DNS_SSL.jpeg)
​
## Change to the example directory

```
[[ `basename $PWD` != static-website-with-domain-ssl ]] && cd examples/static-website-with-domain-ssl
```

## Install Terraform

1. Install Terraform if it is not already installed (visit [terraform.io](https://terraform.io) for other distributions):

## Set up the environment

1. Set the project, replace `YOUR_PROJECT` with your project ID:-

```
PROJECT=YOUR_PROJECT
```

```
gcloud config set project ${PROJECT}
```

2. Configure the environment for Terraform:

```
[[ $CLOUD_SHELL ]] || gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```
​
## Run on HTTP load balancer using SSL and an HTTP-to-HTTPs Redirect (secure)

This option provisions an ssl certificate and a redirect from http to https traffic for your website content.

1. Initialize:

    ```
    terraform init
    ```

2. Set your variables:

    ```
    export_TF_VAR_project=$PROJECT
    export_TF_VAR_project=domain
    ```

3. Deploy only the storage bucket, since it must be created before referencing it to the load balancer:

    ```
    terraform apply -target module.website-storage-buckets
    ```

4. Deploy the load balancer (your must provide your domain below to configure Cloud DNS and your SSL certificate):

    ```
    terraform apply
    ```

5. Update the name servers in your domain registry to point to the Cloud DNS zone's name servers provided in the output.

6. It may take some time for the load balancer and your SSL certificate to fully provision. Once completed, you can visit your site at https://yourdomain.com and https://www.yourdomain.com. http will redirect to https.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain | Zone domain | `string` | n/a | yes |
| project | The ID of the project to create the bucket in. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket-name | n/a |
| bucket-url | n/a |
| loadbalancer-ip | n/a |
| name-servers | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
​
