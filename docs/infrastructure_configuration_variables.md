# Infrastructure Configuration Variables

The infrastructure configuration variables are used to configure the infrastructure for the cluster. These variables are located in  infrastructure_configuration.yaml file. 

| Variable | Description | Default | Provider |
| -------- | ----------- | ------- | -------- |
| `provider` | The provider to use for the infrastructure. | `AWS` | `all` |
| `hive_cluster_name` | The name of the cluster. | `rhods{provider}` | `all` |
| `hive_claim_name` | The name of the claim. | `rhods{provider}claim` | `all` |
| `image_set` | The image set name to use for the cluster. | `rhods-openshift` | `all` |
| `aws_region` | The AWS region to use for the cluster. | `us-east-1` | `aws` |
| `worker_node_instance_type` | The instance type to use for the worker nodes. | `m5.xlarge` | `all` |
| `worker_node_replicas` | The number of worker nodes to create. | `2` | `all` |
| `master_node_instance_type` | The AWS instance type to use for the master nodes. | `m5.xlarge` | `all` |
| `master_node_replicas` | The number of master nodes to create. | `3` | `all` |
| `aws_region` | The AWS region to use for the cluster. | `us-east-1` | `aws` |
| `pull_secret` | The pull secret to use for the cluster. | `""` | `all` |
| `ssh_key` | The SSH key to use for the cluster. | `""` | `all` |
| `AWS_ACCESS_KEY_ID` | The AWS access key ID. | `""` | `aws` |
| `AWS_SECRET_ACCESS_KEY` | The AWS secret access key. | `""` | `aws` |
| `release_image` | The OpenShift image to use for the cluster. | `"quay.io/openshift-release-dev/ocp-release:4.10.42-x86_64"` | `all` |
| `gcp_region` | The GCP region to use for the cluster. | `us-central1` | `gcp` |
| `gcp_project_id` | The GCP project ID to use for the cluster. | `""` | `gcp` |
| `gcp_region` | The GCP region to use for the cluster. | `us-central1` | `gcp` |
| `gcp_service_account_type` | The GCP service account type to use for the cluster. | `""` | `gcp` |
| `gcp_project_id` | The GCP project ID to use for the cluster. | `""` | `gcp` |
| `gcp_private_key_id` | The GCP private key ID to use for the cluster. | `""` | `gcp` |
| `gcp_private_key` | The GCP private key to use for the cluster. | `""` | `gcp` |
| `gcp_client_email` | The GCP client email to use for the cluster. | `""` | `gcp` |
| `gcp_client_id` | The GCP client ID to use for the cluster. | `""` | `gcp` |
| `gcp_auth_uri` | The GCP auth URI to use for the cluster. | `""` | `gcp` |
| `gcp_token_uri` | The GCP token URI to use for the cluster. | `""` | `gcp` |
| `gcp_auth_provider_x509_cert_url` | The GCP auth provider x509 cert URL to use for the cluster. | `""` | `gcp` |
| `gcp_client_x509_cert_url` | The GCP client x509 cert URL to use for the cluster. | `""` | `gcp` |
| registry_pull_secret | The registry pull secret to use for the cluster. | `""` | `all` |
| registryCA | The registry CA to use for the cluster. | `""` | `all` |