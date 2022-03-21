import os
import argparse
import re
import subprocess
import shutil
import yaml
import sys
import jinja2
import time
import glob

dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path+"/../")
from util import (clone_config_repo, read_yaml,
                  execute_command)
from logger import log

"""
Class for Openshift Cluster Manager
"""


class OpenshiftClusterManager():
    def __init__(self, args={}):

        # Initialize instance variables
        self.aws_account_id = args.get("aws_account_id")
        self.aws_access_key_id = args.get("aws_access_key_id")
        self.aws_secret_access_key = args.get("aws_secret_access_key")
        self.token = args.get("token")
        self.testing_platform = args.get("testing_platform")
        self.cluster_name = args.get("cluster_name")
        self.aws_region = args.get("aws_region")
        self.aws_instance_type = args.get("aws_instance_type")
        self.num_compute_nodes = args.get("num_compute_nodes")
        self.openshift_version = args.get("openshift_version")
        self.channel_group = args.get("channel_group")
        self.ocm_cli_binary_url = args.get("ocm_cli_binary_url")
        self.num_users_to_create_per_group = args.get("num_users_to_create_per_group")
        self.htpasswd_cluster_admin = args.get("htpasswd_cluster_admin")
        self.htpasswd_cluster_password = args.get("htpasswd_cluster_password")
        self.ldap_url = args.get("ldap_url")
        self.ldap_bind_dn = args.get("ldap_bind_dn")
        self.ldap_bind_password = args.get("ldap_bind_password")
        self.ldap_test_password = args.get("ldap_test_password")
        self.idp_type = args.get("idp_type")
        self.idp_name = args.get("idp_name")

        ocm_env = glob.glob(dir_path+"/../../../ocm.json.*")
        if ocm_env != []:
            os.environ['OCM_CONFIG'] = ocm_env[0]
            match = re.search(r'.*\.(\S+)', (os.path.basename(ocm_env[0])))
            if match is not None:
                self.testing_platform = match.group(1)
 
    def _is_ocmcli_installed(self):
        """Checks if ocm cli is installed"""
        cmd = "ocm version"
        ret = execute_command(cmd)
        if ret is None:
            log.info("ocm cli not installed.")
            return False
        log.info("ocm cli already installed...")
        return True

    def ocm_cli_install(self):
        """Installs ocm cli if not installed"""
        if not self._is_ocmcli_installed():
            log.info("Installing ocm cli...")
            cmd = "sudo curl -Lo /bin/ocm {}".format(self.ocm_cli_binary_url)
            ret = execute_command(cmd)
            if ret is None:
                log.info("Failed to download ocm cli binary")
                sys.exit(1)

            cmd = "sudo chmod +x /bin/ocm"
            ret = execute_command(cmd)
            if ret is None:
                log.info("Failed to give execute permission to ocm cli binary")
                sys.exit(1)

    def ocm_describe(self, filter=""):
        """Describes cluster and returns cluster info"""
        cmd = "ocm describe cluster {}".format(self.cluster_name)
        if filter != "":
            cmd += " " + filter
        ret = execute_command(cmd)
        if ret is None:
            log.info("ocm describe for cluster "
                   "{} failed".format(self.cluster_name))
            return None
        return ret

    def is_osd_cluster_exists(self):
        """Checks if cluster exists"""
        ret = self.ocm_describe()
        if ret is None:
            log.info("ocm cluster with name "
                   "{} not exists!".format(self.cluster_name))
            return False
        log.info("ocm cluster with name {} exists!".format(self.cluster_name))
        return True

    def osd_cluster_create(self):
        """Creates OSD cluster"""

        if ((self.channel_group == "candidate") and (self.testing_platform == "prod")):
            log.error("Channel group 'candidate' is available only for stage environment.")
            sys.exit(1)

        version = ""
        if self.openshift_version != "":
            version_match = re.match(r'(\d+\.\d+)\-latest',self.openshift_version)
            if version_match is not None:
                version = version_match.group(1)
                chan_grp = ""
                if (self.channel_group == "candidate"):
                    chan_grp = "--channel-group {}".format(self.channel_group)
                 
                version_cmd = "ocm list versions {} | grep -w \"".format(chan_grp) + re.escape(version) + "*\""
                log.info("CMD: {}".format(version_cmd))
                versions = execute_command(version_cmd)
                if versions is not None:
                    version = [ver for ver in versions.split("\n") if ver][-1]
                self.openshift_version = version
            else:
                log.info("Using the osd version given by user as it is...")
            version = "--version {} ".format(self.openshift_version)
        else:
            log.info("Using the latest osd version available in AWS...")

        channel_grp = ""
        if (self.channel_group != ""):
            if ((self.channel_group == "stable") or (self.channel_group == "candidate")):
                if version == "":
                    log.error(("Please enter openshift version as argument."
                               "Channel group option is used along with openshift version."))    
                    sys.exit(1)
                else:
                    channel_grp = "--channel-group {} ".format(self.channel_group)
            else:
                log.error("Invalid channel group. Values can be 'stable' or 'candidate'.")

        cmd = ("ocm create cluster --aws-account-id {} "
               "--aws-access-key-id {} --aws-secret-access-key {} "
               "--ccs --region {} --compute-nodes {} "
               "--compute-machine-type {} {} {}"
               "{}".format(self.aws_account_id,
                           self.aws_access_key_id,
                           self.aws_secret_access_key,
                           self.aws_region, self.num_compute_nodes,
                           self.aws_instance_type, version, 
                           channel_grp, self.cluster_name))
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.info("Failed to create osd cluster {}".format(self.cluster_name))
            sys.exit(1)

    def get_osd_cluster_id(self):
        """Gets osd cluster ID"""

        cluster_name = self.ocm_describe(filter="--json | jq -r '.id'")
        if cluster_name is None:
            log.info("Unable to retrieve cluster ID for "
                     "cluster name {}. EXITING".format(self.cluster_name))
            sys.exit(1)
        return cluster_name.strip("\n")

    def get_osd_cluster_state(self):
        """Gets osd cluster state"""

        cluster_state = self.ocm_describe(filter="--json | jq -r '.state'")
        if cluster_state is None:
            log.info("Unable to retrieve cluster state for "
                   "cluster name {}. EXITING".format(self.cluster_name))
            sys.exit(1)
        return cluster_state.strip("\n")

    def get_osd_cluster_version(self):
        """Gets osd cluster version"""

        cluster_version = self.ocm_describe(filter="--json | jq -r '.version.raw_id'")
        if cluster_version is None:
            log.info("Unable to retrieve cluster version for "
                   "cluster name {}. EXITING".format(self.cluster_name))
            sys.exit(1)
        return cluster_version.strip("\n")

    def get_osd_cluster_console_url(self):
        """Gets osd cluster console url"""

        filter_str = "--json | jq -r '.console.url'"
        cluster_console_url = self.ocm_describe(filter=filter_str)
        if cluster_console_url is None:
            log.info("Unable to retrieve cluster console url "
                   "for cluster name {}. EXITING".format(self.cluster_name))
            sys.exit(1)
        return cluster_console_url.strip("\n")

    def get_osd_cluster_info(self, config_file="osd_config_file.yaml"):
        """Gets osd cluster information and stores in config file"""

        cluster_info = {}
        console_url = self.get_osd_cluster_console_url()
        cluster_info['OCP_CONSOLE_URL'] = console_url
        cluster_version = self.get_osd_cluster_version()
        cluster_info['CLUSTER_VERSION'] = cluster_version
        odh_dashboard_url = console_url.replace('console-openshift-console',
                                                'rhods-dashboard-redhat-ods-applications')
        cluster_info['ODH_DASHBOARD_URL'] = odh_dashboard_url
        # TODO: Avoid this hard coding and call
        # create identity provider method once its ready
        cluster_info['TEST_USER'] = {}
        cluster_info['TEST_USER']['AUTH_TYPE'] = "ldap-provider-qe"
        cluster_info['TEST_USER']['USERNAME'] = "ldap-admin1"
        cluster_info['OCP_ADMIN_USER'] = {}
        cluster_info['OCP_ADMIN_USER']['AUTH_TYPE'] = "htpasswd-cluster-admin"
        cluster_info['OCP_ADMIN_USER']['USERNAME'] = "htpasswd-cluster-admin-user"
        osd_cluster_info = {}
        osd_cluster_info[self.cluster_name] = cluster_info
        with open(config_file, 'w') as file:
            yaml.dump(osd_cluster_info, file)

    def update_osd_cluster_info(self, config_file="osd_config_file.yaml"):
        """Updates osd cluster information and stores in config file"""

        with open(config_file, 'r') as file:
            config_data = yaml.load(file)

        if self.ldap_test_password != "":
            config_data[self.cluster_name]['TEST_USER']['PASSWORD'] = self.ldap_test_password

        if self.htpasswd_cluster_password != "":
            config_data[self.cluster_name]['OCP_ADMIN_USER']['PASSWORD'] = self.htpasswd_cluster_password

        with open(config_file, 'w') as yaml_file:
            yaml_file.write( yaml.dump(config_data, default_flow_style=False))

    def wait_for_osd_cluster_to_be_ready(self, timeout=7200):
        """Waits for cluster to be in ready state"""

        log.info("Waiting for cluster to be ready")
        cluster_state = self.get_osd_cluster_state()
        count = 0
        check_flag = False
        while(count <= timeout):
            cluster_state = self.get_osd_cluster_state()
            if cluster_state == "ready":
                log.info("{} is in ready state".format(self.cluster_name))
                check_flag = True
                break
            elif cluster_state == "error":
                log.info("{} is in error state. Hence "
                       "exiting!!".format(self.cluster_name))
                sys.exit(1)

            time.sleep(60)
            count += 60
        if not check_flag:
            log.info("{} not in ready state even after 2 hours."
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
            log.info("Failed to render template and create json "
                   "file {}".format(output_file))
            sys.exit(1)

    def is_addon_installed(self, addon_name="managed-odh"):
        """Check if given addon is installed"""

        addon_state = self.get_addon_state(addon_name)
        if addon_state == "not installed":
            log.info("Addon {} not installed in cluster "
                   "{}".format(addon_name, self.cluster_name))
            return False
        log.info("Addon {} is installed in cluster"
               " {}".format(addon_name, self.cluster_name))
        return True

    def get_addon_state(self, addon_name="managed-odh"):
        """Gets given addon's state"""

        cmd = ("ocm list addons --cluster {} --columns id,state | grep "
               "{} ".format(self.cluster_name, addon_name))
        ret = execute_command(cmd)
        if ret is None:
            log.info("Failed to get {} addon state for cluster "
                   "{}".format(addon_name, self.cluster_name))
            return None
        match = re.search(addon_name+'\s*(.*)', ret)
        if match is None:
            log.info("regex failed in get_addon_state")
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
                log.info("addon {} is in installed state".format(addon_name))
                check_flag = True
                break

            time.sleep(60)
            count += 60
        if not check_flag:
            log.info("addon {} not in installed state even after "
                   "60 minutes. EXITING".format(addon_name))
            sys.exit(1)

    def wait_for_addon_uninstallation_to_complete(self, addon_name="managed-odh",
                                                  timeout=3600):
        """Waits for addon uninstallation to get complete"""

        addon_state = self.get_addon_state(addon_name)
        count = 0
        check_flag = False
        while(count <= timeout):
            addon_state = self.get_addon_state(addon_name)
            if addon_state == "not installed":
                log.info("addon {} is in uninstalled state".format(addon_name))
                check_flag = True
                break

            time.sleep(60)
            count += 60
        if not check_flag:
            log.info("addon {} not in uninstalled state even after "
                   "60 minutes. EXITING".format(addon_name))
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
            log.info("IDP with idp name {} exists!".format(idp_name))
            return True
        return False

    def install_addon(self, addon_name="managed-odh"):
        """Installs addon"""
        replace_vars = {
                       "CLUSTER_ID": self.cluster_name,
                       "ADDON_NAME": addon_name
                       }
        template_file = "install_addon.jinja"
        output_file = "install_operator.json"
        self._render_template(template_file, output_file, replace_vars)

        cluster_id = self.get_osd_cluster_id()
        cmd = ("ocm post /api/clusters_mgmt/v1/clusters/{}/addons "
               "--body={}".format(cluster_id, output_file))
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.info("Failed to install {} addon on cluster "
                  "{}".format(addon_name, self.cluster_name))
            sys.exit(1)

    def uninstall_addon(self, addon_name="managed-odh"):
        """Uninstalls addon"""

        addon_state = self.get_addon_state(addon_name)
        if addon_state != "not installed":
            cluster_id = self.get_osd_cluster_id()
            cmd = ("ocm delete /api/clusters_mgmt/v1/clusters/{}/addons/"
                   "{}".format(cluster_id, addon_name))
            log.info("CMD: {}".format(cmd))
            ret = execute_command(cmd)
            if ret is None:
                log.info("Failed to uninstall {} addon on cluster "
                      "{}".format(addon_name, self.cluster_name))
                sys.exit(1)

    def install_rhods(self):
        """Installs RHODS addon"""
        self.install_addon(addon_name="managed-odh")

    def uninstall_rhods(self):
        """Uninstalls RHODS addon"""
        self.uninstall_addon(addon_name="managed-odh")

    def create_idp(self):
        """Creates Identity Provider"""

        if self.idp_type == "htpasswd":
            cmd = ("ocm create idp -c {} -t {} -n {} --username {} "
                   "--password {}".format(self.cluster_name,
                                          self.idp_type,
                                          self.idp_name,
                                          self.htpasswd_cluster_admin,
                                          self.htpasswd_cluster_password))
            log.info("CMD: {}".format(cmd))
            ret = execute_command(cmd)
            if ret is None:
                log.info("Failed to add identity provider of "
                      "type {}".format(self.idp_type))
            self.add_user_to_group()

        elif (self.idp_type == "ldap"):
            ldap_yaml_file = (os.path.abspath(
                os.path.dirname(__file__)) +
                "/../../../configs/templates/ldap/ldap.yaml")
            cmd = "oc apply -f {}".format(ldap_yaml_file)
            log.info("CMD: {}".format(cmd))
            ret = execute_command(cmd)
            if ret is None:
                log.info("Failed to deploy openldap application")
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
            log.info("CMD: {}".format(cmd))
            ret = execute_command(cmd)
            if ret is None:
                log.info("Failed to add ldap identity provider")
            self.add_users_to_rhods_group()
        time.sleep(300)

    def delete_idp(self):
        """Deletes Identity Provider"""

        cmd = ("ocm delete idp -c {} {}".format(self.cluster_name,
                                                self.idp_name))
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.info("Failed to delete identity provider of "
                  "type {}".format(self.idp_name))

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
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.info("Failed to add user {} to group "
                  "{}".format(user, group))

    def create_group(self, group_name):
        """Creates new group"""

        cmd = "oc adm groups new {}".format(group_name)
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.info("Failed to add group "
                  "{}".format(group_name))

    def add_users_to_rhods_group(self):
        """Add users to rhods group"""

        self.create_group("rhods-admins")
        # Adds user ldap-admin1..ldap-adminN
        for i in range(1, int(self.num_users_to_create_per_group)+1):
            self.add_user_to_group(user="ldap-admin"+str(i),
                                   group="rhods-admins")

        self.create_group("rhods-users")
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
        log.info("CMD: {}".format(cmd))
        users_list = execute_command(cmd)
        log.info("Users present in cluster: {}".format(users_list))

        cmd = "oc get groups"
        log.info("CMD: {}".format(cmd))
        groups_list = execute_command(cmd)
        log.info("Groups present in cluster: {}".format(groups_list))

    def create_cluster(self):
        """
        Creates OSD cluster
        """
        self.osd_cluster_create()
        self.wait_for_osd_cluster_to_be_ready()

        # Waiting 5 minutes to ensure all the cluster services are
        # up even after cluster is in ready state
        time.sleep(300)

    def install_rhods_addon(self):
        if not self.is_addon_installed():
            self.install_rhods()
            self.wait_for_addon_installation_to_complete()
        # Waiting 5 minutes to ensure all the services are up
        time.sleep(300)

    def uninstall_rhods_addon(self):
        self.uninstall_rhods()
        self.wait_for_addon_uninstallation_to_complete()

    def ocm_login(self):
        """ Login to OCM using ocm cli"""

        cmd = "ocm login --token=\"{}\" ".format(self.token)

        if self.testing_platform == "stage":
            cmd += "--url=staging"

        cmd = "OCM_CONFIG=ocm.json." + self.testing_platform + " " + cmd
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.info("Failed to login to aws openshift platform using token")
            sys.exit(1)
        os.environ["OCM_CONFIG"] =  "ocm.json." + self.testing_platform

    def delete_cluster(self):
        """ Delete OSD Cluster"""

        cluster_id = self.get_osd_cluster_id()
        cmd = "ocm delete cluster {}".format(cluster_id)
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.info("Failed to delete osd cluster {}".format(self.cluster_name))
            sys.exit(1)
        self.wait_for_osd_cluster_to_get_deleted()

    def wait_for_osd_cluster_to_get_deleted(self, timeout=3600):
        """Waits for cluster to get deleted"""

        cluster_exists = self.is_osd_cluster_exists()
        count = 0
        check_flag = False
        while(count <= timeout):
            cluster_exists = self.is_osd_cluster_exists()
            if not cluster_exists:
                log.info("{} is deleted".format(self.cluster_name))
                check_flag = True
                break

            time.sleep(60)
            count += 60
        if not check_flag:
            log.info("{} not deleted even after an hour."
                   " EXITING".format(self.cluster_name))
            sys.exit(1)

if __name__ == "__main__":

        #Instance for OpenshiftClusterManager Class
        ocm_obj = OpenshiftClusterManager()

        """Parse CLI arguments"""

        ocm_cli_binary_url = ("https://github.com/openshift-online/ocm-cli/"
                              "releases/download/v0.1.55/ocm-linux-amd64")
        parser = argparse.ArgumentParser(
            formatter_class=argparse.ArgumentDefaultsHelpFormatter,
            description='Script to generate test config file')

        subparsers = parser.add_subparsers(title='Available sub commands',
                                           help='sub-command help')

        #Argument parsers for ocm_login
        ocm_login_parser = subparsers.add_parser(
            'ocm_login',
            help=("Login to OCM using token"),
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)

        optional_ocm_login_parser = ocm_login_parser._action_groups.pop()
        required_ocm_login_parser = ocm_login_parser.add_argument_group('required arguments')
        ocm_login_parser._action_groups.append(optional_ocm_login_parser)
        required_ocm_login_parser.add_argument("--token",
            help="openshift token for login",
            action="store", dest="token", metavar="",
            required=True)
        optional_ocm_login_parser.add_argument("--testingplatform",
            help="testing platform. 'prod' or 'stage'",
            action="store", dest="testing_platform", metavar="",
            default="stage")
        ocm_login_parser.set_defaults(func=ocm_obj.ocm_login)

        #Argument parsers for create_cluster
        create_cluster_parser = subparsers.add_parser(
            'create_cluster',
            help=("Create managed OpenShift Dedicated v4 clusters via OCM."),
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)

        optional_create_cluster_parser = create_cluster_parser._action_groups.pop()
        required_create_cluster_parser = create_cluster_parser.add_argument_group('required arguments')
        create_cluster_parser._action_groups.append(optional_create_cluster_parser)

        required_create_cluster_parser.add_argument("--aws-account-id",
            help="aws account id",
            action="store", dest="aws_account_id",
            required=True)
        required_create_cluster_parser.add_argument("--aws-accesskey-id",
            help="aws access key id",
            action="store", dest="aws_access_key_id",
            required=True)
        required_create_cluster_parser.add_argument("--aws-secret-accesskey",
            help="aws secret access key",
            action="store", dest="aws_secret_access_key",
            required=True)

        optional_create_cluster_parser.add_argument("--cluster-name",
            help="osd cluster name",
            action="store", dest="cluster_name", metavar="",
            default="osd-qe-1")
        optional_create_cluster_parser.add_argument("--aws-region",
            help="aws region",
            action="store", dest="aws_region", metavar="",
            default="us-east-1")
        optional_create_cluster_parser.add_argument("--aws-instance-type",
            help="aws instance type",
            action="store", dest="aws_instance_type", metavar="",
            default="m5.2xlarge")
        optional_create_cluster_parser.add_argument("--num-compute-nodes",
            help="Number of compute nodes",
            action="store", dest="num_compute_nodes", metavar="",
            default="3")
        optional_create_cluster_parser.add_argument("--openshift-version",
            help="Openshift Version",
            action="store", dest="openshift_version",
            metavar="", default="")
        optional_create_cluster_parser.add_argument("--channel-group",
            help="Channel group name. Values can be stable or candidate.",
            action="store", dest="channel_group",
            metavar="", default="")

        create_cluster_parser.set_defaults(func=ocm_obj.create_cluster)

        #Argument parsers for delete_cluster
        delete_cluster_parser = subparsers.add_parser(
            'delete_cluster',
            help=("Delete managed OpenShift Dedicated v4 clusters via OCM."),
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        delete_cluster_parser.add_argument("--cluster-name",
            help="osd cluster name",
            action="store", dest="cluster_name", metavar="",
            default="osd-qe-1")
        delete_cluster_parser.set_defaults(func=ocm_obj.delete_cluster)

        #Argument parsers for delete_idp
        delete_idp_parser = subparsers.add_parser(
            'delete_idp',
            help=("Delete a specific identity provider for a cluster."),
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        optional_delete_idp_parser = delete_idp_parser._action_groups.pop()
        required_delete_idp_parser = delete_idp_parser.add_argument_group('required arguments')
        delete_idp_parser._action_groups.append(optional_delete_idp_parser)
        required_delete_idp_parser.add_argument("--idp-name",
            help="IDP name",
            action="store", dest="idp_name", metavar="",
            required=True)
        optional_delete_idp_parser.add_argument("--cluster-name",
            help="osd cluster name",
            action="store", dest="cluster_name", metavar="",
            default="osd-qe-1")
        delete_idp_parser.set_defaults(func=ocm_obj.delete_idp)

        #Argument parsers for get_osd_cluster_info
        info_parser = subparsers.add_parser(
            'get_osd_cluster_info',
            help=("Gets the cluster information"),
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        optional_info_parser = info_parser._action_groups.pop()
        required_info_parser = info_parser.add_argument_group('required arguments')
        info_parser._action_groups.append(optional_info_parser)

        optional_info_parser.add_argument("--cluster-name",
            help="osd cluster name",
            action="store", dest="cluster_name", metavar="",
            default="osd-qe-1")
        info_parser.set_defaults(func=ocm_obj.get_osd_cluster_info)

        #Argument parsers for update_osd_cluster_info
        update_info_parser = subparsers.add_parser(
            'update_osd_cluster_info',
            help=("Updates the cluster information"),
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        optional_update_info_parser = update_info_parser._action_groups.pop()
        required_update_info_parser = update_info_parser.add_argument_group('required arguments')
        update_info_parser._action_groups.append(optional_update_info_parser)

        optional_update_info_parser.add_argument("--cluster-name",
            help="osd cluster name",
            action="store", dest="cluster_name", metavar="",
            default="osd-qe-1")
        optional_update_info_parser.add_argument("--htpasswd-cluster-password",
            help="htpasswd Cluster admin password",
            action="store", dest="htpasswd_cluster_password", metavar="",
            default="")
        optional_update_info_parser.add_argument("--ldap-test-password",
            help="Ldap test password",
            action="store", dest="ldap_test_password", metavar="",
            default="")
        update_info_parser.set_defaults(func=ocm_obj.update_osd_cluster_info)

        #Argument parsers for install_rhods_addon
        install_rhods_parser = subparsers.add_parser(
            'install_rhods_addon',
            help=("Install rhods addon cluster."),
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        required_install_rhods_parser = install_rhods_parser.add_argument_group('required arguments')

        required_install_rhods_parser.add_argument("--cluster-name",
            help="osd cluster name",
            action="store", dest="cluster_name",
            required=True)
        install_rhods_parser.set_defaults(func=ocm_obj.install_rhods_addon)

        #Argument parsers for uninstall_rhods_addon
        uninstall_rhods_parser = subparsers.add_parser(
            'uninstall_rhods_addon',
            help=("Uninstall rhods addon cluster."),
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        required_uninstall_rhods_parser = uninstall_rhods_parser.add_argument_group('required arguments')

        required_uninstall_rhods_parser.add_argument("--cluster-name",
            help="osd cluster name",
            action="store", dest="cluster_name",
            required=True)
        uninstall_rhods_parser.set_defaults(func=ocm_obj.uninstall_rhods_addon)

        #Argument parsers for create_idp
        create_idp_parser = subparsers.add_parser(
            'create_idp',
            help=("Add an Identity providers to determine how users log into the cluster."),
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        optional_create_idp_parser = create_idp_parser._action_groups.pop()
        required_create_idp_parser = create_idp_parser.add_argument_group('required arguments')
        ldap_create_idp_parser = create_idp_parser.add_argument_group('  Options for ldap IDP')
        htpasswd_create_idp_parser = create_idp_parser.add_argument_group('  Options for htpasswd IDP')
        create_idp_parser._action_groups.append(optional_create_idp_parser)

        required_create_idp_parser.add_argument("--type",
            help = "Type of identity provider. Options are [ldap htpasswd]",
            action="store", dest="idp_type",
            required=True, choices=['ldap', 'htpasswd'])
        required_create_idp_parser.add_argument("--cluster",
            help = "Cluster name",
            action="store", dest="cluster_name",
            required=True)
        ldap_create_idp_parser.add_argument("--ldap-url ",
            help="ldap: Ldap url", metavar=" ",
            default=("ldap://openldap.openldap.svc."
                     "cluster.local:1389"
                     "/dc=example,dc=org?uid"))
        ldap_create_idp_parser.add_argument("--ldap-bind-dn ",
            help="ldap: Ldap bind dn", metavar=" ",
            default="cn=admin,dc=example,dc=org")
        ldap_create_idp_parser.add_argument("--num-users-to-create-per-group ", metavar=" ",
            help="ldap: Number of users to create per group",
            default="20")
        htpasswd_create_idp_parser.add_argument("--htpasswd-cluster-admin ",
                            help="Cluster admin user of idp type htpasswd", metavar=" ",
                            default="htpasswd-cluster-admin-user")
        known_args = parser.parse_known_args()
        if "idp_type" in known_args[0]:
            idp_type = known_args[0].idp_type
            if idp_type == "ldap":
                optional_create_idp_parser.add_argument("--ldap-url",
                    help="ldap: Ldap url",
                    action="store", dest="ldap_url", metavar="",
                    default=("ldap://openldap.openldap.svc."
                             "cluster.local:1389"
                             "/dc=example,dc=org?uid"))
                optional_create_idp_parser.add_argument("--ldap-bind-dn",
                    help="ldap: Ldap bind dn", metavar="",
                    action="store", dest="ldap_bind_dn",
                    default="cn=admin,dc=example,dc=org")
                required_create_idp_parser.add_argument("--ldap-bind-password",
                    help="ldap: Ldap bind password",
                    action="store", dest="ldap_bind_password", required=True)
                optional_create_idp_parser.add_argument("--num-users-to-create-per-group",
                    help="ldap: Ldap bind password", metavar="",
                    action="store", dest="num_users_to_create_per_group",
                    default="20")
            elif idp_type == "htpasswd":
                optional_create_idp_parser.add_argument("--idp-name",
                                help="Cluster admin's idp name",
                                action="store", dest="idp_name", metavar="",
                                default="htpasswd-cluster-admin")

                optional_create_idp_parser.add_argument("--htpasswd-cluster-admin",
                                help="Cluster admin user of idp type htpasswd",
                                action="store", dest="htpasswd_cluster_admin", metavar="",
                                default="htpasswd-cluster-admin-user")

                required_create_idp_parser.add_argument("--htpasswd-cluster-password",
                                help="htpasswd Cluster admin password",
                                action="store", dest="htpasswd_cluster_password", required=True)
        create_idp_parser.set_defaults(func=ocm_obj.create_idp)

        parser.add_argument("-o", "--ocmclibinaryurl",
                            help="ocm cli binary url",
                            action="store", dest="ocm_cli_binary_url",
                            default=ocm_cli_binary_url)
        args = parser.parse_args(namespace=ocm_obj)
        if hasattr(args, 'func'):
            args.func()
