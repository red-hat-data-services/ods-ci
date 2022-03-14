# Provision Openshift Dedicated Cluster in AWS
Script to install Openshift Dediated (OSD) on AWS with the aid of Openshift Cluster Manager CLI tool ([ocm-cli](https://github.com/openshift-online/ocm-cli.git))

# Prerequisites
- Python 3.x
- Install ocm cli
- access_key and secret_access_key for the AWS account user *ocdCcsAdmin*

Follow the below instructions to install ocm cli, if already installed skip to [Instructions](#Instructions) section

# Install OCM command line tool
Openshift Cluster Manager command line tool can be directly build from the source page.
_Please refer the GitHub
[releases page](https://github.com/openshift-online/ocm-cli/releases) page for the latest release version available, using outdated ocm cli might cause error_. 

```
$ mkdir -p ~/bin
$ curl -Lo ~/bin/ocm https://github.com/openshift-online/ocm-cli/releases/download/<<updateme>>/ocm-linux-amd64
$ chmod +x ~/bin/ocm
```
Replace the value *updateme* on the above command to the targetted release version

For example, To install version 0.1.62

```
$ mkdir -p ~/bin
$ curl -Lo ~/bin/ocm https://github.com/openshift-online/ocm-cli/releases/download/v0.1.62/ocm-linux-amd64
$ chmod +x ~/bin/ocm
```

# Usage
```
$ python ocm.py -h
usage: ocm.py [-h] {ocm_login,create_cluster,delete_cluster,delete_idp,get_osd_cluster_info,update_osd_cluster_info,install_rhods_addon,install_gpu_addon,add_machine_pool,uninstall_rhods_addon,create_idp} ...

Script to generate test config file

optional arguments:
  -h, --help            show this help message and exit

Available sub commands:
  {ocm_login,create_cluster,delete_cluster,delete_idp,get_osd_cluster_info,update_osd_cluster_info,install_rhods_addon,install_gpu_addon,add_machine_pool,uninstall_rhods_addon,create_idp}
                        sub-command help
    ocm_login           Login to OCM using token
    create_cluster      Create managed OpenShift Dedicated v4 clusters via OCM.
    delete_cluster      Delete managed OpenShift Dedicated v4 clusters via OCM.
    delete_idp          Delete a specific identity provider for a cluster.
    get_osd_cluster_info
                        Gets the cluster information
    update_osd_cluster_info
                        Updates the cluster information
    install_rhods_addon
                        Install rhods addon cluster.
    install_gpu_addon   Install gpu addon cluster.
    add_machine_pool    Adds machine pool to given cluster via OCM.
    uninstall_rhods_addon
                        Uninstall rhods addon cluster.
    create_idp          Add an Identity providers to determine how users log into the cluster.
```
ocm.py script uses ocm cli to provision and destroy cluster along with other functionalities like creating identity providers(IDP) to access the cluster, installing/uninstalling add-ons and retreiving the cluster info

# Instructions
Clone the [ODS-CI](https://github.com/red-hat-data-services/ods-ci.git) repository
    
``` git clone https://github.com/red-hat-data-services/ods-ci.git```
    
Navigate to ocm directory
    
``` cd ods-ci/utils/scripts/ocm```
    
### Login to OCM
Before creating a cluster, user should login to OCM using access tokens.
Retrieve the access token from [here](https://console.redhat.com/openshift/token/show) and login to ocm by running the below script
    
``` python ocm.py ocm_login --token "<token_here>"  --url=staging```
    
Replace the field <token_here>.

*Note:* Argument --url=staging sets the targeted environment for OSD to deploy. _url=staging_ deploys a cluster in [staging](https://qaprodauth.cloud.redhat.com/) environment. If the argument removed, cluster would get deployed in [production](https://console.redhat.com/) environment

### Create Cluster
To deploy a OSD cluster on AWS

``` python ocm.py create_cluster --aws-account-id <account_id> --aws-accesskey-id <access_key> --aws-secret-accesskey <secret_accesskey> --cluster-name <cluster_name>```
    
Replace the fields <account_id>, <access_key>, <secret_accesskey> and <cluster_name>.

*Note:* AWS account access_key and secret_accesskey for the user ocdCcsAdmin should be used to create a cluster, please refer [here](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html) to get more details about AWS identity and Access Management.

### Install RHODS addon
    
```python3 ocm.py install_rhods_addon --cluster-name <clustername>```
    
Replace the field <clustername> to the cluster name deployed

### Create IDP
    
```python3 ocm.py create_idp --type htpasswd --cluster <cluster_name>  --htpasswd-cluster-password <password>```
    
Identity providers should be created in order to access the cluster created. The above command creates IDP type of htpasswd with the default IDP name htpasswd-cluster-admin and User name htpasswd-cluster-admin-user
