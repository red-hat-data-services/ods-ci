import os
import argparse
import re
import subprocess
import shutil
import yaml
import sys
import jinja2
import time

dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path+"/../")
from util import (clone_config_repo, read_yaml,
                  oc_login, execute_command)

"""
Class for Openshift Cluster Manager
"""


class OpenshiftClusterManager():
    def __init__(self, args):

        # Initialize instance variables
        self.aws_account_id = args.aws_account_id
        self.aws_access_key_id = args.aws_access_key_id
        self.aws_secret_access_key = args.aws_secret_access_key
        self.login_token = args.login_token
        self.testing_platform = args.testing_platform
        self.cluster_name = args.cluster_name
        self.aws_region = args.aws_region
        self.aws_instance_type = args.aws_instance_type
        self.num_compute_nodes = args.num_compute_nodes
        self.skip_cluster_creation = args.skip_cluster_creation
        self.skip_rhods_installation = args.skip_rhods_installation
        self.ocm_cli_binary_url = args.ocm_cli_binary_url
        self.create_cluster_admin_user = args.create_cluster_admin_user
        self.create_ldap_idp = args.create_ldap_idp
        self.num_users_to_create_per_group = args.num_users_to_create_per_group

        self.idp_type = "htpasswd"
        self.idp_name = "htpasswd-cluster-admin"
        self.htpasswd_cluster_admin = args.htpasswd_cluster_admin
        self.htpasswd_cluster_password = args.htpasswd_cluster_password
        self.ldap_url = args.ldap_url
        self.ldap_bind_dn = args.ldap_bind_dn
        self.ldap_bind_password = args.ldap_bind_password

    def _is_ocmcli_installed(self):
        """Checks if ocm cli is installed"""
        cmd = "ocm version"
        ret = execute_command(cmd)
        if ret is None:
            print ("ocm cli not installed.")
            return False
        print ("ocm cli already installed...")
        return True

    def ocm_cli_install(self):
        """Installs ocm cli if not installed"""
        if not self._is_ocmcli_installed():
            print ("Installing ocm cli...")
            cmd = "sudo curl -Lo /bin/ocm {}".format(self.ocm_cli_binary_url)
            ret = execute_command(cmd)
            if ret is None:
                print("Failed to download ocm cli binary")
                sys.exit(1)

            cmd = "sudo chmod +x /bin/ocm"
            ret = execute_command(cmd)
            if ret is None:
                print("Failed to give execute permission to ocm cli binary")
                sys.exit(1)

    def ocm_describe(self, filter=""):
        """Describes cluster and returns cluster info"""
        cmd = "ocm describe cluster {}".format(self.cluster_name)
        if filter != "":
            cmd += " " + filter
        ret = execute_command(cmd)
        if ret is None:
            print ("ocm describe for cluster "
                   "{} failed".format(self.cluster_name))
            return None
        return ret

    def is_osd_cluster_exists(self):
        """Checks if cluster exists"""
        ret = self.ocm_describe()
        if ret is None:
            print ("ocm cluster with name "
                   "{} not exists!".format(self.cluster_name))
            return False
        print ("ocm cluster with name {} exists!".format(self.cluster_name))
        return True

    def osd_cluster_create(self):
        """Creates OSD cluster"""

        cmd = ("ocm create cluster --aws-account-id {} "
               "--aws-access-key-id {} --aws-secret-access-key {} "
               "--ccs --region {} --compute-nodes {} "
               "--compute-machine-type {} "
               "{}".format(self.aws_account_id,
                           self.aws_access_key_id,
                           self.aws_secret_access_key,
                           self.aws_region, self.num_compute_nodes,
                           self.aws_instance_type, self.cluster_name))
        ret = execute_command(cmd)
        if ret is None:
            print ("Failed to create osd cluster {}".format(self.cluster_name))
            sys.exit(1)

    def get_osd_cluster_id(self):
        """Gets osd cluster ID"""

        cluster_name = self.ocm_describe(filter="--json | jq -r '.id'")
        if cluster_name is None:
            print ("Unable to retrieve cluster ID for "
                   "cluster name {}. EXITING".format(self.cluster_name))
            sys.exit(1)
        return cluster_name.strip("\n")

    def get_osd_cluster_state(self):
        """Gets osd cluster state"""

        cluster_state = self.ocm_describe(filter="--json | jq -r '.state'")
        if cluster_state is None:
            print ("Unable to retrieve cluster state for "
                   "cluster name {}. EXITING".format(self.cluster_name))
            sys.exit(1)
        return cluster_state.strip("\n")

    def get_osd_cluster_console_url(self):
        """Gets osd cluster console url"""

        filter_str = "--json | jq -r '.console.url'"
        cluster_console_url = self.ocm_describe(filter=filter_str)
        if cluster_console_url is None:
            print ("Unable to retrieve cluster console url "
                   "for cluster name {}. EXITING".format(self.cluster_name))
            sys.exit(1)
        return cluster_console_url.strip("\n")

    def get_osd_cluster_info(self, config_file="osd_config_file.yaml"):
        """Gets osd cluster information and stores in config file"""

        cluster_info = {}
        console_url = self.get_osd_cluster_console_url()
        cluster_info['OCP_CONSOLE_URL'] = console_url
        odh_dashboard_url = console_url.replace('console-openshift-console',
                                                'rhods-dashboard-redhat-ods-applications')
        cluster_info['ODH_DASHBOARD_URL'] = odh_dashboard_url
        # TODO: Avoid this hard coding and call
        # create identity provider method once its ready
        cluster_info['TEST_USER'] = {}
        cluster_info['TEST_USER']['AUTH_TYPE'] = "ldap-provider-qe"
        cluster_info['TEST_USER']['USERNAME'] = "ldap-admin1"
        cluster_info['TEST_USER']['PASSWORD'] = "rhodsPW#1"
        cluster_info['OCP_ADMIN_USER'] = {}
        cluster_info['OCP_ADMIN_USER']['AUTH_TYPE'] = self.idp_name
        cluster_info['OCP_ADMIN_USER']['USERNAME'] = self.htpasswd_cluster_admin
        cluster_info['OCP_ADMIN_USER']['PASSWORD'] = self.htpasswd_cluster_password
        osd_cluster_info = {}
        osd_cluster_info[self.cluster_name] = cluster_info
        with open(config_file, 'w') as file:
            yaml.dump(osd_cluster_info, file)

    def wait_for_osd_cluster_to_be_ready(self, timeout=7200):
        """Waits for cluster to be in ready state"""

        cluster_state = self.get_osd_cluster_state()
        count = 0
        check_flag = False
        while(count <= timeout):
            cluster_state = self.get_osd_cluster_state()
            if cluster_state == "ready":
                print ("{} is in ready state".format(self.cluster_name))
                check_flag = True
                break
            elif cluster_state == "error":
                print ("{} is in error state. Hence "
                       "exiting!!".format(self.cluster_name))
                sys.exit(1)

            time.sleep(60)
            count += 60
        if not check_flag:
            print ("{} not in ready state even after 2 hours."
                   " EXITING".format(self.cluster_name))
            sys.exit(1)

    def _render_template(self, template_file, output_file, replace_vars):
        """Helper module to render jinja template"""

        try:
            templateLoader = jinja2.FileSystemLoader(
                searchpath=os.path.abspath(
                    os.path.dirname(__file__)) + "/templates")
            templateEnv = jinja2.Environment(loader=templateLoader)
            template = templateEnv.get_template(template_file)
            outputText = template.render(replace_vars)
            with open(output_file, 'w') as fh:
                fh.write(outputText)
        except:
            print ("Failed to render template and create json "
                   "file {}".format(output_file))
            sys.exit(1)

    def is_addon_installed(self, addon_name="managed-odh"):
        """Check if given addon is installed"""

        addon_state = self.get_addon_state(addon_name)
        if addon_state == "not installed":
            print ("Addon {} not installed in cluster "
                   "{}".format(addon_name, self.cluster_name))
            return False
        print ("Addon {} is installed in cluster"
               " {}".format(addon_name, self.cluster_name))
        return True

    def get_addon_state(self, addon_name="managed-odh"):
        """Gets given addon's state"""

        cmd = ("ocm list addons --cluster {} --columns id,state | grep "
               "{} ".format(self.cluster_name, addon_name))
        ret = execute_command(cmd)
        if ret is None:
            print ("Failed to get {} addon state for cluster "
                   "{}".format(addon_name, self.cluster_name))
            return None
        match = re.search(addon_name+'\s*(.*)', ret)
        if match is None:
            print ("regex failed in get_addon_state")
            return None
        return match.group(1).strip()

    def wait_for_addon_installation_to_complete(self, addon_name="managed-odh",
                                                timeout=3600):
        """Waits for addon installation to get complete"""

        addon_state = self.get_addon_state(addon_name)
        count = 0
        check_flag = False
        while(count <= timeout):
            addon_state = self.get_addon_state(addon_name)
            if addon_state == "ready":
                print ("addon {} is in installed state".format(addon_name))
                check_flag = True
                break

            time.sleep(60)
            count += 60
        if not check_flag:
            print ("addon {} not in installed state even after "
                   "30minutes. EXITING".format(addon_name))
            sys.exit(1)

    def list_idps(self):
        """Lists IDPs for the cluster"""

        cmd = ("ocm list idps --cluster {} --columns name"
               .format(self.cluster_name))
        ret = execute_command(cmd)
        if ret is None:
            return []
        if ret != []:
            ret = ret.split('\n')[1:-1]
        return ret

    def is_idp_exists(self, idp_name):
        """Checks if given idp exists in cluster"""
        ret = self.list_idps()
        if idp_name in ret:
            print ("IDP with idp name {} exists!".format(idp_name))
            return True
        return False

    def install_rhods(self):
        """Installs RHODS addon"""
        replace_vars = {
                       "CLUSTER_ID": self.cluster_name,
                       "ADDON_NAME": "managed-odh"
                       }
        template_file = "install_addon.jinja"
        output_file = "install_rhods.json"
        self._render_template(template_file, output_file, replace_vars)

        cluster_id = self.get_osd_cluster_id()
        cmd = ("ocm post /api/clusters_mgmt/v1/clusters/{}/addons "
               "--body={}".format(cluster_id, output_file))
        ret = execute_command(cmd)
        if ret is None:
            print("Failed to install rhods addon on cluster "
                  "{}".format(self.cluster_name))
            sys.exit(1)

    def create_idp(self, type="htpasswd"):
        """Creates Identity Provider"""

        if type == "htpasswd":
            cmd = ("ocm create idp -c {} -t {} -n {} --username {} "
                   "--password {}".format(self.cluster_name,
                                          self.idp_type,
                                          self.idp_name,
                                          self.htpasswd_cluster_admin,
                                          self.htpasswd_cluster_password))
            ret = execute_command(cmd)
            if ret is None:
                print("Failed to add identity provider of "
                      "type {}".format(self.idp_type))
        elif (type == "ldap"):
            ldap_yaml_file = (os.path.abspath(
                os.path.dirname(__file__)) +
                "/../../../configs/templates/ldap/ldap.yaml")
            cmd = "oc apply -f {}".format(ldap_yaml_file)
            ret = execute_command(cmd)
            if ret is None:
                print("Failed to deploy openldap application")
                sys.exit(1)

            replace_vars = {
                           "LDAP_URL": self.ldap_url,
                           "LDAP_BIND_DN": self.ldap_bind_dn,
                           "LDAP_BIND_PASSWORD": self.ldap_bind_password
                           }
            template_file = "create_ldap_idp.jinja"
            output_file = "create_ldap_idp.json"
            self._render_template(template_file, output_file, replace_vars)

            cluster_id = self.get_osd_cluster_id()
            cmd = ("ocm post /api/clusters_mgmt/v1/"
                   "clusters/{}/identity_providers "
                   "--body={}".format(cluster_id, output_file))
            ret = execute_command(cmd)
            if ret is None:
                print("Failed to add ldap identity provider")

    def delete_idp(self, idp_name):
        """Deletes Identity Provider"""

        cmd = ("ocm delete idp -c {} {}".format(self.cluster_name,
                                                idp_name))
        ret = execute_command(cmd)
        if ret is None:
            print("Failed to delete identity provider of "
                  "type {}".format(idp_name))

    def add_user_to_group(self, user="", group="cluster-admins"):
        """Adds user to given group"""

        if user == "":
            user = self.htpasswd_cluster_admin

        if ((group == "rhods-admins") or
           (group == "rhods-users") or
           (group == "rhods-noaccess")):
            cmd = "oc adm groups add-users {} {}".format(group, user)
        else:
            cmd = ("ocm create user {} --cluster {} "
                   "--group={}".format(user,
                                       self.cluster_name, group))
        ret = execute_command(cmd)
        if ret is None:
            print("Failed to add user {} to group "
                  "{}".format(user, group))

    def create_group(self, group_name):
        """Creates new group"""

        cmd = "oc adm groups new {}".format(group_name)
        ret = execute_command(cmd)
        if ret is None:
            print("Failed to add group "
                  "{}".format(group_name))

    def add_users_to_rhods_group(self):
        """Add users to rhods group"""

        # Adds user ldap-admin1..ldap-adminN
        for i in range(1, int(self.num_users_to_create_per_group)+1):
            self.add_user_to_group(user="ldap-admin"+str(i),
                                   group="rhods-admins")

        # Adds user ldap-user1..ldap-userN
        for i in range(1, int(self.num_users_to_create_per_group)+1):
            self.add_user_to_group(user="ldap-user"+str(i),
                                   group="rhods-users")

	# Adds special users
        # "(", ")", "|", "<", ">" not working in OSD
        # "+" and ";" disabled for now
        for char in [".", "^", "$", "*", "?", "[", "]", "{", "}", "@"]:
            self.add_user_to_group(user="ldap-special"+char,
                                   group="rhods-users")

        self.create_group("rhods-noaccess")
        # Adds user ldap-noaccess1..ldap-noaccessN
        for i in range(1, int(self.num_users_to_create_per_group)+1):
            self.add_user_to_group(user="ldap-noaccess"+str(i),
                                   group="rhods-noaccess")

        # Logging users/groups details after adding
        # given user to group

        cmd = "oc get users"
        users_list = execute_command(cmd)
        print ("Users present in cluster: {}".format(users_list))

        cmd = "oc get groups"
        groups_list = execute_command(cmd)
        print ("Groups present in cluster: {}".format(groups_list))

    def setup_osd_cluster(self):
        """Sets up the osd cluster"""

        if not bool(self.skip_cluster_creation):
            if not self.is_osd_cluster_exists():
                self.osd_cluster_create()
                self.wait_for_osd_cluster_to_be_ready()
        else:
            print ("cluster create step got skipped!!")
        if not bool(self.skip_rhods_installation):
            if not self.is_addon_installed():
                self.install_rhods()
                self.wait_for_addon_installation_to_complete()
        else:
            print ("managed-ods addon installation got skipped!!")
        if bool(self.create_cluster_admin_user):
            self.create_idp()
            self.add_user_to_group()

        if ((not bool(self.skip_cluster_creation)) or
           (not bool(self.skip_rhods_installation)) or
           (bool(self.create_cluster_admin_user))):

            # Waiting 5 minutes to ensure all the cluster services are
            # up even after cluster is in ready state
            time.sleep(300)

        print ("Get osd cluster {} Info".format(self.cluster_name))
        self.get_osd_cluster_info()

    def login(self):
        """ Login to OCM using ocm cli"""

        cmd = "ocm login --token=\"{}\" ".format(self.login_token)
        if self.testing_platform == "stage":
            cmd += "--url=staging"

        ret = execute_command(cmd)
        if ret is None:
            print("Failed to login to aws openshift platform using token")
            sys.exit(1)

    def delete_cluster(self):
        """ Delete OSD Cluster"""

        cluster_id = self.get_osd_cluster_id()
        cmd = "ocm delete cluster {}".format(cluster_id)

        ret = execute_command(cmd)
        if ret is None:
            print("Failed to delete osd cluster {}".format(self.cluster_name))
            sys.exit(1)

    def wait_for_osd_cluster_to_get_deleted(self, timeout=3600):
        """Waits for cluster to get deleted"""

        cluster_exists = self.is_osd_cluster_exists()
        count = 0
        check_flag = False
        while(count <= timeout):
            cluster_exists = self.is_osd_cluster_exists()
            if not cluster_exists:
                print ("{} is deleted".format(self.cluster_name))
                check_flag = True
                break

            time.sleep(60)
            count += 60
        if not check_flag:
            print ("{} not deleted even after an hour."
                   " EXITING".format(self.cluster_name))
            sys.exit(1)

def parse_args():
    """Parse CLI arguments"""

    ocm_cli_binary_url = ("https://github.com/openshift-online/ocm-cli/"
                          "releases/download/v0.1.55/ocm-linux-amd64")
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='Script to generate test config file')
    parser.add_argument("-i", "--awsaccountid",
                        help="aws account id",
                        action="store", dest="aws_account_id",
                        required=True)
    parser.add_argument("-a", "--awsaccesskeyid",
                        help="aws access key id",
                        action="store", dest="aws_access_key_id",
                        required=True)
    parser.add_argument("-k", "--awssecretaccesskey",
                        help="aws secret access key",
                        action="store", dest="aws_secret_access_key",
                        required=True)
    parser.add_argument("-l", "--logintoken",
                        help="openshift token for login",
                        action="store", dest="login_token",
                        required=True)
    parser.add_argument("-p", "--testingplatform",
                        help="testing platform. 'prod' or 'stage'",
                        action="store", dest="testing_platform",
                        default="stage")
    parser.add_argument("-e", "--clustername",
                        help="osd cluster name",
                        action="store", dest="cluster_name",
                        default="osd-qe-1")
    parser.add_argument("-r", "--awsregion",
                        help="aws region",
                        action="store", dest="aws_region",
                        default="us-east-1")
    parser.add_argument("-t", "--awsinstancetype",
                        help="aws instance type",
                        action="store", dest="aws_instance_type",
                        default="m5.2xlarge")
    parser.add_argument("-c", "--numcomputenodes",
                        help="Number of compute nodes",
                        action="store", dest="num_compute_nodes",
                        default="3")
    parser.add_argument("-j", "--htpasswd-cluster-admin",
                        help="Cluster admin user of idp type htpasswd",
                        action="store", dest="htpasswd_cluster_admin",
                        default="htpasswd-cluster-admin-user")
    parser.add_argument("-y", "--htpasswd-cluster-password",
                        help="htpasswd Cluster admin password",
                        action="store", dest="htpasswd_cluster_password",
                        default="rhodsPW#123456")
    parser.add_argument("-u", "--ldap-url",
                        help="Ldap url",
                        action="store", dest="ldap_url",
                        default=("ldap://openldap.openldap.svc."
                                 "cluster.local:1389"
                                 "/dc=example,dc=org?uid"))
    parser.add_argument("-b", "--ldap-bind-dn",
                        help="Ldap bind dn",
                        action="store", dest="ldap_bind_dn",
                        default="cn=admin,dc=example,dc=org")
    parser.add_argument("-w", "--ldap-bind-password",
                        help="Ldap bind password",
                        action="store", dest="ldap_bind_password",
                        default="adminpassword")
    parser.add_argument("-z", "--num-users-to-create-per-group",
                        help="Ldap bind password",
                        action="store", dest="num_users_to_create_per_group",
                        default="20")
    parser.add_argument("-s", "--skip-cluster-creation",
                        help="skip osd cluster creation",
                        action="store_true", dest="skip_cluster_creation")
    parser.add_argument("-x", "--skip-rhods-installation",
                        help="skip rhods installation",
                        action="store_true", dest="skip_rhods_installation")
    parser.add_argument("-m", "--create-cluster-admin-user",
                        help="create cluster admin user for login",
                        action="store_true", dest="create_cluster_admin_user")
    parser.add_argument("-q", "--create-ldap-idp",
                        help="create ldap idp and add users to rhods groups",
                        action="store_true", dest="create_ldap_idp")
    parser.add_argument("-d", "--delete-ldap-idp",
                        help="delete ldap idp",
                        action="store_true", dest="delete_ldap_idp")
    parser.add_argument("-g", "--delete-cluster",
                        help="delete osd cluster",
                        action="store_true", dest="delete_cluster")
    parser.add_argument("-o", "--ocmclibinaryurl",
                        help="ocm cli binary url",
                        action="store", dest="ocm_cli_binary_url",
                        default=ocm_cli_binary_url)

    return parser.parse_args()


if __name__ == '__main__':

    args = parse_args()
    ocm_obj = OpenshiftClusterManager(args)

    # Install ocm cli if not already installed
    ocm_obj.ocm_cli_install()

    # Perform ocm login to cluster
    ocm_obj.login()

    # Setup OSD Cluster
    ocm_obj.setup_osd_cluster()

    # Create ldap idp and add users to rhods groups
    if bool(args.create_ldap_idp):
        ocm_obj.create_idp(type="ldap")
        ocm_obj.add_users_to_rhods_group()

        # TODO: Add wait mechanism to let ldap IDP
        # to be in action in cluster
        time.sleep(120)

    if bool(args.delete_ldap_idp):
        if (ocm_obj.is_idp_exists("ldap-provider-qe")):
            ocm_obj.delete_idp("ldap-provider-qe")

            # TODO: Add wait mechanism to let ldap IDP
            # deletion to be in action in cluster
            time.sleep(120)

    if bool(args.delete_cluster):
        print ("Deleting OSD Cluster...")
        ocm_obj.delete_cluster()

        print ("Wait for cluster to get deleted")
        ocm_obj.wait_for_osd_cluster_to_get_deleted()
