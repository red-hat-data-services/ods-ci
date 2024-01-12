# Provision vm in openstack
Script to manage instances in openstack using terraform.
Currently the script handles provisioning and deleting vm instances.

## Prerequisites
Python 3.x
Install terraform in cli
pip3 install python-terraform

## How to Run:
1. Change directory to the terraform/openstack directory.

```
# cd ods-ci/utils/scripts/terraform/openstack
```

2. Now run the script.

## Usage

```
# python3 provision.py -h
usage: provision.py [-h] {create_instance,delete_instance,set_config} ...

Script to manage instances in Openstack

optional arguments:
  -h, --help            show this help message and exit

Available sub commands:
  {create_instance,delete_instance,set_config}
                        sub-command help
    create_instance     Creates an instance in OpenStack
    delete_instance     Deletes an instance in OpenStack
    set_config          Sets config for using Openstack with terraform

# python3 provision.py create_instance -h
usage: provision.py create_instance [-h] --cloud_name CLOUD_NAME --vm_name
                                    VM_NAME --vm_user VM_USER --vm_private_key
                                    VM_PRIVATE_KEY --key_pair KEY_PAIR
                                    --network_name NETWORK_NAME
                                    [--flavor-name] [--image-name]

required arguments:
  --cloud_name CLOUD_NAME
                        Cloud provider name (default: None)
  --vm_name VM_NAME     vm name (default: None)
  --vm_user VM_USER     vm instance username (default: None)
  --vm_private_key VM_PRIVATE_KEY
                        vm instance private key to login with (default: None)
  --key_pair KEY_PAIR   The public key of an OpenSSH key pair to be used for
                        access to created instances (default: None)
  --network_name NETWORK_NAME
                        Network Name (default: None)

optional arguments:
  -h, --help            show this help message and exit
  --flavor-name         Flavour name (default: m1.medium)
  --image-name          Image name to create an instance (default:
                        CentOS-8-x86_64-GenericCloud-released-latest)
# python3 provision.py delete_instance -h
usage: provision.py delete_instance [-h] --cloud_name CLOUD_NAME --vm_name
                                    VM_NAME --key_pair KEY_PAIR --network_name
                                    NETWORK_NAME [--flavor-name]
                                    [--image-name]

required arguments:
  --cloud_name CLOUD_NAME
                        Cloud provider name (default: None)
  --vm_name VM_NAME     vm name (default: None)
  --key_pair KEY_PAIR   The public key of an OpenSSH key pair to be used for
                        access to created instances (default: None)
  --network_name NETWORK_NAME
                        Network Name (default: None)

optional arguments:
  -h, --help            show this help message and exit
  --flavor-name         Flavour name (default: m1.medium)
  --image-name          Image name to create an instance (default:
                        CentOS-8-x86_64-GenericCloud-released-latest)

# python3 provision.py set_config -h
usage: provision.py set_config [-h] --cloud_name CLOUD_NAME --auth_url
                               AUTH_URL --username USERNAME --password
                               PASSWORD --project_id PROJECT_ID --project_name
                               PROJECT_NAME --user_domain_name
                               USER_DOMAIN_NAME --region_name REGION_NAME
                               --interface INTERFACE --identity_api_version
                               IDENTITY_API_VERSION

required arguments:
  --cloud_name CLOUD_NAME
                        Cloud provider name (default: None)
  --auth_url AUTH_URL   The identity authentication URL (default: None)
  --username USERNAME   The Username to login with (default: None)
  --password PASSWORD   The Password to login with (default: None)
  --project_id PROJECT_ID
                        The project ID to login with (default: None)
  --project_name PROJECT_NAME
                        The project name to login with (default: None)
  --user_domain_name USER_DOMAIN_NAME
                        The domain name where the user is located (default:
                        None)
  --region_name REGION_NAME
                        The region of the OpenStack cloud to use (default:
                        None)
  --interface INTERFACE
                        Interface Name (default: None)
  --identity_api_version IDENTITY_API_VERSION
                        Identity API verson to use (default: None)

optional arguments:
  -h, --help            show this help message and exit
```

## Example:
To create a vm instance:
```
 # python3 provision.py create_instance --cloud_name <cloud_name> --vm_name <vm_name> --vm_user <vm_user> --vm_private_key <vm's ssh public or private key> --key_pair <key pair name> --network_name <network_name> --flavor-name <flavour name to create vm>
```

To delete a vm instance:
```
 # python3 provision.py delete_instance --cloud_name <cloud_name> --vm_name <vm_name> --key_pair <key pair name> --network_name <network name>
```

To set config file for using Openstack with terraform:
```
 # python3 provision.py set_config --cloud_name <cloud_name> --auth_url <openstack auth url> --username <openstack username> --password <openstack password> --project_id <project id> --project_name <project name> --user_domain_name <openstack domain name> --region_name <openstack region> --interface <interface> --identity_api_version <api version number>

```
