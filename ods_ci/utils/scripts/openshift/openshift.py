import argparse
import os
import re
import shutil
import subprocess
import sys

import pexpect
import yaml

dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path + "/../")
from logger import log
from util import execute_command

"""
Class for Openshift Installation on AWS
Pre-requisites to install before executing the script: awscli, openshift-install
"""


class OpenshiftOps:
    def __init__(self, args={}):
        # Initialize instance variables
        self.aws_access_key_id = args.get("aws_access_key_id")
        self.aws_secret_access_key = args.get("aws_secret_access_key")
        self.install_config_file = args.get("install_config_file")
        self.aws_region = args.get("aws_region")
        self.cluster_name = args.get("cluster_name")
        cwd = os.getcwd()
        self.work_dir = cwd + "/ocp/"

    def _generate_ssh_key(self):
        """
        Generates ssh key required for OpenShift Installation
        """
        cmd = "ssh-keygen -t rsa -b 4096 -N '' -f {}/id_rsa".format(self.work_dir)
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.error("Failed to generate ssh key")
            return None

        cmd = 'eval "$(ssh-agent -s)";' + "ssh-add {}/id_rsa".format(self.work_dir)
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.error("Failed to eval ssh-agent and to add ssh rsa key")
            return None

        return True

    def _update_install_config(self):
        """
        Helper module to update sshKey in install-config.yaml
        """

        cmd = "cat {}/id_rsa.pub".format(self.work_dir)
        ret = execute_command(cmd)
        if ret is None:
            log.error("Failed to add ssh rsa key")
            return None
        with open(self.install_config_file, "r") as file:
            config_data = yaml.safe_load(file)

        config_data["sshKey"] = ret
        config_data["metadata"]["name"] = self.cluster_name

        with open(self.install_config_file, "w") as yaml_file:
            yaml_file.write(yaml.dump(config_data, default_flow_style=False))

        return True

    def _aws_configure(self):
        """
        Runs aws configure and set the configuration required
        for OpenShift Installation

        === Code using pexpect ===
        configure_cmd = pexpect.spawn("aws configure")
        configure_cmd.expect("AWS Access Key ID .*: ")
        configure_cmd.sendline(self.aws_access_key_id)
        configure_cmd.expect("AWS Secret Access Key .*: ")
        configure_cmd.sendline(self.aws_secret_access_key)
        configure_cmd.expect("Default region name .*: ")
        configure_cmd.sendline(self.aws_region)
        configure_cmd.expect("Default output format .*: ")
        configure_cmd.sendline("yaml")
        configure_cmd.interact()
        """

        contents = "aws configure << EOF \n{}\n{}\n{}\n{}\nEOF".format(
            self.aws_access_key_id,
            self.aws_secret_access_key,
            self.aws_region,
            "yaml",
        )

        with open("aws.sh", "w") as f:
            f.write(contents)

        cmd = "sh aws.sh"
        ret = execute_command(cmd)
        if ret is None:
            log.error("Failed to configure aws")
            return None

        return True

    def install_prerequisites(self):
        """Module to install pre-requisites"""

        if os.path.exists(self.work_dir) and os.path.isdir(self.work_dir):
            shutil.rmtree(self.work_dir)

        if not os.path.exists(self.work_dir):
            os.makedirs(self.work_dir)

        ret = self._generate_ssh_key()
        if ret is None:
            sys.exit(1)

        ret = self._update_install_config()
        if ret is None:
            sys.exit(1)

        ret = self._aws_configure()
        if ret is None:
            sys.exit(1)

    def openshift_install(self, config_file="cluster_config.yaml"):
        """Installs ocm cli if not installed"""

        self.install_prerequisites()
        install_config_dir = os.path.dirname(self.install_config_file)
        cmd = "cd {}".format(install_config_dir)
        ret = execute_command(cmd)
        if ret is None:
            log.error("Failed to cd to directory where install config is present")
            return None

        process = subprocess.Popen(
            ["openshift-install", "create", "cluster"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        log.info(
            "Executing openshift-install create cluster command in {}".format(
                install_config_dir
            )
        )
        log.info("OpenShift Cluster creation is in progress...")
        returncode = process.wait()
        if returncode != 0:
            log.error("Failed to create openshift cluster on AWS")
            sys.exit(1)

        output = process.stdout.read().decode("utf-8")
        match = re.search(
            ".*Access the OpenShift web-console here: (\S+)"
            '.*Login to the console with user: "(\S+)".*password: "(\S+)".*',
            output,
            re.S,
        )
        if match is None:
            log.error(
                "Unexpected console logs in openshift-install create cluster output"
            )
            sys.exit(1)

        log.info(
            "OpenShift Cluster {} created successfully !".format(self.cluster_name)
        )

        cluster_info = {}
        cluster_info["CLUSTER_NAME"] = self.cluster_name
        cluster_info["OCP_CONSOLE_URL"] = match.group(1)
        cluster_info["OCP_ADMIN_USER"] = {}
        cluster_info["OCP_ADMIN_USER"]["AUTH_TYPE"] = "kube:admin"
        cluster_info["OCP_ADMIN_USER"]["USERNAME"] = match.group(2)
        cluster_info["OCP_ADMIN_USER"]["PASSWORD"] = match.group(3)

        with open(config_file, "w") as file:
            yaml.dump(cluster_info, file)

    def openshift_destroy(self):
        """Delete openshift cluster using openshift-installer"""

        install_config_dir = os.path.dirname(self.install_config_file)
        cmd = "cd {}".format(install_config_dir)

        ret = execute_command(cmd)
        if ret is None:
            log.error("Failed to cd to directory where install config is present")
            sys.exit(1)

        cmd = "openshift-install destroy cluster"
        log.info("CMD: {}".format(cmd))
        ret = execute_command(cmd)
        if ret is None:
            log.error("Failed to destroy openshift cluster")
            sys.exit(1)


if __name__ == "__main__":
    # Instance for OpenshiftOps Class
    oc_obj = OpenshiftOps()

    """Parse CLI arguments"""

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Script to do openshift operations on AWS",
    )

    subparsers = parser.add_subparsers(
        title="Available sub commands", help="sub-command help"
    )

    # Argument parsers for create_cluster
    openshift_install_parser = subparsers.add_parser(
        "openshift_install",
        help=("Create OpenShift clusters using openshift installer"),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    optional_openshift_install_parser = openshift_install_parser._action_groups.pop()
    required_openshift_install_parser = openshift_install_parser.add_argument_group(
        "required arguments"
    )
    openshift_install_parser._action_groups.append(optional_openshift_install_parser)

    required_openshift_install_parser.add_argument(
        "--aws-accesskey-id",
        help="aws access key id",
        action="store",
        dest="aws_access_key_id",
        required=True,
    )

    required_openshift_install_parser.add_argument(
        "--aws-secret-accesskey",
        help="aws secret access key",
        action="store",
        dest="aws_secret_access_key",
        required=True,
    )

    required_openshift_install_parser.add_argument(
        "--install-config-file",
        help="Install config file. Note: "
        "Place this file from where you are running this for now",
        action="store",
        dest="install_config_file",
        required=True,
    )

    optional_openshift_install_parser.add_argument(
        "--aws-region",
        help="aws region",
        action="store",
        dest="aws_region",
        metavar="",
        default="us-east-1",
    )

    optional_openshift_install_parser.add_argument(
        "--cluster-name",
        help="openshift cluster name",
        action="store",
        dest="cluster_name",
        metavar="",
        default="qeaisrhods-x1",
    )

    openshift_install_parser.set_defaults(func=oc_obj.openshift_install)

    # Argument parsers for destroy cluster
    openshift_destroy_parser = subparsers.add_parser(
        "openshift_destroy",
        help=("Destroy OpenShift clusters using openshift installer"),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    openshift_destroy_parser.add_argument(
        "--install-config-file",
        help="Install config file",
        action="store",
        dest="install_config_file",
        required=True,
    )

    openshift_destroy_parser.set_defaults(func=oc_obj.openshift_destroy)

    args = parser.parse_args(namespace=oc_obj)
    if hasattr(args, "func"):
        args.func()
