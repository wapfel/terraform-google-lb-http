# HTTPS load balancer with Cloud Storage Backend example (Domain not required)

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/terraform-google-modules/terraform-google-lb-http&working_dir=examples/static-website-with-no-domain&page=shell&tutorial=README.md)

This example creates a static website using a public Google Cloud Storage bucket containing basic html website files and exposes it behind a Cloud HTTPS load balancer and Cloud CDN. It is accessible via a global IP only. If you have your own domain and would like to use SSL, please see the [static-website-with-domain-ssl](../static-website-with-domain-ssl) example.
​
You can tweak this example to enable other functionalities such as:
​
- configuring custom CDN caching policies
- serving static assets from multiple cloud storage buckets (requires a custom url map to be provided)
- serving static and dynamic assets from backend buckets and backend services

## Resources created

**Figure 1.** *diagram of terraform resources*

![architecture diagram](../../modules/backend_bucket/Diagrams/Static_Website_IP_Only.jpeg)
​
## Change to the example directory

```
[[ `basename $PWD` != static-website-with-no-domain ]] && cd examples/static-website-with-no-domain
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
## Run on HTTP load balancer (unencrypted, not recommended for production)

This option provisions an HTTP forwarding rule (insecure) and is not recommended
for production use.

1. Initialize:

    ```
    terraform init
    ```

2. Set your variables:

    ```
    export TF_VAR_project=$PROJECT
    ```

3. Deploy only the storage bucket, since it must be created before referencing it to the load balancer:

    ```
    terraform apply -target module.website-storage-buckets
    ```

4. Deploy the load balancer:

    ```
    terraform apply
    ```

5. It may take a few minutes for the load balancer to provision. Once completed, you can visit the output IP address of the load balancer to view the site.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | The ID of the project to create the bucket in. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket-name | n/a |
| bucket-url | n/a |
| loadbalancer-ip | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
​
