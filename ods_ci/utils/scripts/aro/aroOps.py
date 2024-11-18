import sys
from time import sleep
import re
import os

from ods_ci.utils.scripts.logger import log
from ods_ci.utils.scripts.util import execute_command
import subprocess


# Get the available Azure/ARO versions
def get_aro_version(version) -> str | None:

    char_to_count = "."

    if version.count(char_to_count) == 1:
        version = version + "."

    get_versions_cmd=(f"az aro get-versions -l eastus | grep {version}")
    final_list = []

    ret = execute_command(get_versions_cmd)

    version_string = re.sub("[\"\']", "", ret)
    version_string = version_string.lstrip(' ').replace("\n","").replace(",","")
    version_list = version_string.split()

    for my_string in version_list:
        if version in my_string:
            final_list.append(my_string)

    if len(final_list) > 0:
        return final_list[-1]
    else:
        log.error("INVALID OCP VERSION FOR ARO CLUSTER: ", version)
        log.error("Versions available:")
        execute_command("az aro get-versions -l eastus")
        print("Exiting...")
        sys.exit(1)
    

# ARO cli login
def aro_cli_login(aro_client_id, aro_tenant_id, aro_secret_pwd):

    aro_cli_login_cmd=(f"az login --service-principal -u {aro_client_id} -p {aro_secret_pwd} --tenant {aro_tenant_id}")

    ret = execute_command(aro_cli_login_cmd)
    if "ERROR" in ret:
        log.error("LOGIN UNSUCCESSFUL")
        log.error("Invalid tenant id, client it and/or secret")
        sys.exit(1)
    else:
        print("LOGIN SUCCESSFUL")


# Execute Terraform to create the cluster
def execute_terraform(cluster_name, subscription_id, version):
    print(">>>>> Here is the cluster name again: ", cluster_name)
    print(">>>>> Here is the version: ", version)
    execute_command(f"terraform init && terraform plan -out tf.plan -var=subscription_id={subscription_id} -var=cluster_name={cluster_name} -var=aro_version={version} && terraform apply tf.plan")


# Get information (api url, console url, cluster version, provisioning state, location) from the cluster
def get_aro_cluster_info(my_cluster_name):
    api_server_profile_url = get_cluster_info_field_value(my_cluster_name, "apiserverProfile.url")
    console_profile_url = get_cluster_info_field_value(my_cluster_name, "consoleProfile.url")
    cluster_profile_version =  get_cluster_info_field_value(my_cluster_name, "clusterProfile.version")
    provisioning_state = get_cluster_info_field_value(my_cluster_name, "provisioningState")
    cluster_location =  get_cluster_info_field_value(my_cluster_name, "location") 

    if provisioning_state == "Succeeded":
        print("cluster is up and running")
    else:
        print("Provisioning state: ", provisioning_state)
        print("The cluster is not in a healthy state. Please manually delete all resources from the Azure portal")
        sys.exit(1)

    print("Cluster name: ", my_cluster_name)
    print("Provisioning status: ", provisioning_state)
    print("Cluster location: ", cluster_location)
    print("Version: ", cluster_profile_version)
    print("Console URL: ", console_profile_url)
    print("API URL: ", api_server_profile_url)


# Log into the ARO cluster
def aro_cluster_login(my_cluster_name):
    resource_group = my_cluster_name + "-rg"
    print("Obtain cluster credentials...")
    api_server_profile_url = get_cluster_info_field_value(my_cluster_name, "apiserverProfile.url")

    aro_cluster_pwd = execute_command(f"az aro list-credentials --name {my_cluster_name} --resource-group {resource_group} -o tsv --query kubeadminPassword")

    print("Login to the cluster...")

    output = subprocess.getoutput(f"oc login -u kubeadmin -p {aro_cluster_pwd} {api_server_profile_url} --insecure-skip-tls-verify=true 2>&1")
    print(output)
    if "Login successful" in output:
        execute_command("oc get nodes")
        execute_command("oc get co; oc get clusterversion")
    else:
        print("unable to log into cluster")
        print("get the cluster credentials with the command:")
        print("az aro list-credentials --name <cluster name> --resource-group <resource group> -o tsv --query kubeadminPassword")
        sys.exit(1)


# Delete the ARO cluster
def aro_cluster_delete(cluster_name):
    resource_group = cluster_name + "-rg"
    provisioning_state = get_cluster_info_field_value(cluster_name, "provisioningState")
    
    time_count = 0
    if provisioning_state == "Succeeded":
        print("Deleting cluster: ", cluster_name)
        execute_command(f"az aro delete --name {cluster_name} --resource-group {resource_group} --yes -y --no-wait")
        delete_provisioning_state = get_cluster_info_field_value(cluster_name, "provisioningState")
        while delete_provisioning_state == "Deleting" and time_count < 3600:
            print(delete_provisioning_state)
            sleep(60)
            time_count += 60
            delete_provisioning_state = get_cluster_info_field_value(cluster_name, "provisioningState")
        if "ERROR: (ResourceNotFound)" in delete_provisioning_state:
            print("Cluster has been successfully deleted")
        elif time_count >= 3600:
            print("Time exceeded for cluster deletion. Please delete the cluster manually")
            print("Exiting...")
            sys.exit(1)

    else:
        print("Cannot find cluster. Check for the cluster and delete manually if present.")
        print("Exiting...")
        sys.exit(1)


 # Get the value of a field from the cluster info json   
def get_cluster_info_field_value(my_cluster_name, cluster_info_field):
    resource_group = my_cluster_name + "-rg"

    my_command_output = execute_command(f"az aro show --name {my_cluster_name} --resource-group {resource_group} | jq '.{cluster_info_field}'")
    my_command_output = re.sub("[\"\']", "", my_command_output)

    return my_command_output.strip()


# Check for an existing cluster with the same name
def check_for_existing_cluster(cluster_name):
    provisioning_state = get_cluster_info_field_value(cluster_name, "provisioningState")

    if ("ERROR: (ResourceNotFound)" in provisioning_state) or ("ERROR: (ResourceGroupNotFound)" in provisioning_state):
        print(f"cluster does not exist. Proceeding with provisioning cluster {cluster_name}")
        return None
    else:
        print(f"ERROR: cluster {cluster_name} exists.")
        print("Exiting...")
        sys.exit(1)