# grr-gce
Automatic creation of GRR infrastructure using GCP GCE, Container-Optimized OS, and Terraform.
This module will:

* Create instance groups with global load balancers for each GRR component
* Generate certificates for the internal GRR PKI
* Set up GCE networking
* Set up CloudSQL
* Set up DNS records within your managed zone
* Hook in Identity Aware Proxy
* Generate new client installers and upload them to your GCS bucket

We also provide a docker-compose lab for local testing. 


# Prerequisites

## Deployment
* Google Cloud Platform credentials [configured](https://cloud.google.com/docs/authentication/) for use with Terraform
* SSL certificate and private key in PEM format
* Google managed [DNS zone](https://cloud.google.com/dns/docs/)
* Configured [IAP Client](https://cloud.google.com/iap/docs/enabling-compute-howto)

## Testing
* Docker
* OpenSSL

# Configuration
## Terraform
### General

#### Variables

| Name | Description | Required | Default |
| - | - | - | - |
|`gce_project` | GCP project name | Yes | 
|`gce_project_id` | GCP project id | Yes | 
|`gce_region` | GCE region where `gce_project` is located | Yes |
|`dns_zone_name` | Name of Google managed DNS zone where DNS records should be created | Yes |
|`dns_zone_fqdn`| FQDN of `dns_zone_name` zone | Yes |
|`dns_default_ttl` | Default TTL for DNS records in seconds | No | 300 |
|`database_version` | Version of MySQL that CloudSQL supports | No | `MySQL_5_7` | 
|`database_tier` | Database deployment tier | No | `db-n1-standard-4` |

#### Outputs
| Name | Description |
| - | - |
|`grr_db_ip` | IPv4 address of the MySQL instance created |
|`grr_db_user` | Username for provisioned grr database user |
|`grr_db_user_password` | Password generated for the provisioned grr database user |


### Frontend

#### Variables
| Name | Description | Required | Default |
| - | - | - | - |
|`grr_frontend_image` | Base docker image to use for the GRR frontend component created by the process detailed in this README | Yes |
|`grr_frontend_image_tag` | Image tag to pull for the image specified by `grr_frontend_image` | Yes |
|`grr_frontend_address` | Hostname/address that GRR clients will reach out to. Needs to match DNS record | Yes | 
|`frontend_cn` | CN to use for frontend PKI certificate | Yes | 
|`grr_ca_cn` | CN to use for internal PKI CA certificate | Yes |
|`grr_ca_country` | Country to use for internal PKI CA Certificate | Yes |
|`grr_ca_org` | Organization to use for internal PKI CA Certificate | Yes |
|`client_installers_bucket_name` | Name of GCS bucket that where generated GRR client installers will be uploaded | Yes |
|`storage_access_logs_bucket_name` | Name of GCS bucket where access logs for `client_installers_bucket_name` will be stored | Yes |
|`gcs_bucket_location` |  Location of GCS buckets to be created | No | `US` |
|`client_installers_bucket_root` | Root directory where GRR client installers should be uploaded within `client_installers_bucket_name` | No | `installers`
|`grr_frontend_port` | Port that GRR clients will connnect to. Needs to be an [accepted TCP port](https://cloud.google.com/load-balancing/docs/tcp/).  | No | 443 |
|`grr_frontend_monitoring_port` | Port for localized monitoring stats server. Needs to be an [accepted TCP port](https://cloud.google.com/load-balancing/docs/tcp/). | No | 5222 |
|`grr_frontend_network_tag` | Firewall network tag to open oprts for GRR frontend | No | `grr-frontend` | 
|`grr_frontend_target_size` | Number of GRR frontend instances that should always be running" | No | 3 |
|`grr_frontend_machine_type` | GCE Machine type to spawn for frontend instance group | No | `n1-standard-1` |
|`grr_frontend_rsa_key_length` | Not used | No | 2048 |

#### Outputs 

| Name | Description |
| - | - |
| `client_fingerprint` | Fingerprint given to generated client installer for this specific frontend configuration | 
| `frontend_lb_address` | IPv4 address of global load balancer for frontend group |
| `frontend_fqdn` | FQDN for the DNS record pointing at the `frontend_lb_address` |


### AdminUI

#### Variables
| Name | Description | Required | Default |
| - | - | - | - |
|`grr_adminui_image` | Base docker image to use for the GRR adminui component created by the process detailed in this README| Yes |
|`grr_adminui_image_tag` | Image tag to pull for the image specified by `grr_adminui_image` | Yes |
|`grr_adminui_iap_client_id` | OAuth2 Client id for the IAP client credential | Yes |
|`grr_adminui_iap_client_secret` | OAuth2 Client secret for the IAP client credential | Yes |
|`grr_adminui_external_hostame` | Hostname that users will access the GRR UI from, which matches DNS record | Yes |
|`grr_adminui_ssl_cert_path` | Filepath to the SSL cert in PEM format to be installed on the UI HTTPS Load Balancer | Yes |
|`grr_adminui_ssl_cert_private_key` | Private key for the SSL cert specified in `grr_adminui_ssl_cert_path` in PEM format. **Do not store this in plain text!** | Yes |
|`grr_adminui_port` | Port that clients will connect to. Needs to be an [accepted TCP port](https://cloud.google.com/load-balancing/docs/tcp/).| No | 443 |
|`grr_adminui_monitoring_port` | Port for localized monitoring stats server. Needs to be an [accepted TCP port](https://cloud.google.com/load-balancing/docs/tcp/). | No | 5222 |
|`grr_adminui_network_tag` | Firewall network tag to open oprts for GRR frontend | No | `grr-adminui` | 
|`grr_adminui_target_size` | Number of GRR adminui instances that should always be running" | No | 2 |
|`grr_adminui_machine_type` | GCE Machine type to spawn for adminui instance group | No | `n1-standard-1` |

#### Outputs
| Name | Description |
| - | - |
|`lb_address` | IPv4 address of global load balancer for adminui group |
|`grr_user` | Username of generated root grr user |
|`grr_password` | Password of generated root grr user |


### Worker

#### Variables

| Name | Description | Required | Default |
| - | - | - | - |
|`grr_worker_image` | Base docker image to use for the GRR worker component created by the process detailed in this README | Yes |
|`grr_worker_image_tag` | Image tag to pull for the image specified by `grr_worker_image` | Yes |
|`grr_worker_target_size` | Number of GRR adminui instances that should always be running" | No | 5 |
|`grr_worker_machine_type` | GCE Machine type to spawn for adminui instance group | No | `n1-standard-1` |
|`grr_worker_monitoring_port` | Port for localized monitoring stats server. Needs to be an [accepted TCP port](https://cloud.google.com/load-balancing/docs/tcp/). | No | 5222 |

## User Management

This module utilizes Google's [Identity Aware Proxy](https://cloud.google.com/iap/docs/enabling-compute-howto), which allows you to lock down access to an application by using Google identities. After your GRR cluster is created, you must grant the appropriate IAM permissions for each principle you would like to grant access to the UI. 

## SSH Management
This module enables OSLogin, which allows you to manage SSH access and root privledges using Google identities and IAM. SSH is to these instance is locked down by default. Consult the [documentation](https://cloud.google.com/compute/docs/instances/managing-instance-access#configure_users) to learn how to manage access.

## Docker Image Creation
This module was tested with a snapshot of `grrdocker/grr:latest`, which was at version `v3.2.4.7`. The current dockerfiles use `latest` as a base, which is constantly being updated and may introduce breaking changes. We intend to pin this base image when `v3.2.4.7` is pinned on for the `grrdocker/grr` [Docker Hub repository](https://hub.docker.com/r/grrdocker/grr/). 

To create an image suitable for deployment:

1. Change the `image` keys in the `docker-compose.yaml` definition to the full qualified image name that you intend to roll out for deployment. This needs to be for a repository that your GCE instances have access to.
1. Run `docker-compose build`
1. Run `docker push <image>` for each of the newly built images
1. Update the `grr_<adminui|worker|frontend>_image` and `grr_<adminui|worker|frontend>_image_tag` terraform variables as necessary
1. Run a `terraform plan`, confirm correctness, and `terraform apply`

# Local testing
## Local lab
We provide a `docker-compose.yaml`, which orchestrates the creation of a local MySQL instance, GRR components, and appropriate bind mounts for placing newly generated client installers.

1. Run `docker-compose up`
1. Access the AdminUI at `http://localhost:8443`
1. Username and password is `root:root`

Client installers will be generated and placed in `test/installers`. Utility scripts are provided in `test/scripts` for:

* Local macOS client installation/uninstallation
* Testing certificate rotation
