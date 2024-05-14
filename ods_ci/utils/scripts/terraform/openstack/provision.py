import argparse
import os
import shutil
import sys

from python_terraform import IsFlagged, IsNotFlagged, Terraform

dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path + "/../../")
from logger import log
from util import render_template

"""
Class for Openstack Terraform Provisioner
"""


class OpenstackTerraformProvisioner:
    def __init__(self, args={}):
        # Initialize instance variables
        self.cloud_name = args.get("cloud_name")
        self.vm_name = args.get("vm_name")
        self.vm_user = args.get("vm_user")
        self.vm_private_key = args.get("vm_private_key")
        self.image_name = args.get("image_name")
        self.flavor_name = args.get("flavor_name")
        self.key_pair = args.get("key_pair")
        self.network_name = args.get("network_name")
        self.auth_url = args.get("auth_url")
        self.project_id = args.get("project_id")
        self.project_name = args.get("project_name")
        self.username = args.get("username")
        self.password = args.get("password")
        self.user_domain_name = args.get("user_domain_name")
        self.interface = args.get("interface")
        self.identity_api_version = args.get("identity_api_version")
        self.working_dir = dir_path

    def create_instance(self):
        """Created Openstack vm instance"""
        tf = Terraform(
            working_dir=self.working_dir,
            variables={
                "cloud_name": self.cloud_name,
                "vm_name": self.vm_name,
                "vm_user": self.vm_user,
                "vm_private_key": self.vm_private_key,
                "image_name": self.image_name,
                "flavor_name": self.flavor_name,
                "key_pair": self.key_pair,
                "network_name": self.network_name,
            },
        )
        tf.init()
        ret, out, err = tf.apply(
            no_color=IsFlagged,
            input=False,
            refresh=False,
            capture_output=True,
            skip_plan=True,
        )
        if ret != 0:
            log.error("Failed to create instance! {}".format(err))
            sys.exit(1)

    def delete_instance(self):
        """Deletes Openstack vm instance"""
        tf = Terraform(
            working_dir=self.working_dir,
            variables={
                "cloud_name": self.cloud_name,
                "vm_name": self.vm_name,
                "image_name": self.image_name,
                "flavor_name": self.flavor_name,
                "key_pair": self.key_pair,
                "network_name": self.network_name,
            },
        )
        tf.init()
        ret, out, err = tf.destroy(
            capture_output="yes",
            no_color=IsNotFlagged,
            force=IsNotFlagged,
            auto_approve=True,
        )
        if ret != 0:
            log.error("Failed to delete instance! {}".format(err))
            sys.exit(1)

    def set_config(self):
        """Creates configuration file for using terraform with openstack"""
        replace_vars = {
            "CLOUD_NAME": self.cloud_name,
            "AUTH_URL": self.auth_url,
            "PROJECT_ID": self.project_id,
            "PROJECT_NAME": self.project_name,
            "USER_DOMAIN_NAME": self.user_domain_name,
            "USERNAME": self.username,
            "PASSWORD": self.password,
            "REGION_NAME": self.region_name,
            "INTERFACE": self.interface,
            "IDENTITY_API_VERSION": self.identity_api_version,
        }
        template_file = "clouds.jinja"
        output_file = "clouds.yaml"
        search_path = os.path.abspath(os.path.dirname(__file__)) + "/templates"
        render_template(search_path, template_file, output_file, replace_vars)
        dst_dir = os.path.expanduser("~") + "/.config/openstack/"
        os.makedirs(dst_dir, exist_ok=True)
        shutil.move(output_file, os.path.join(dst_dir, output_file))


if __name__ == "__main__":
    # Instance for OpenstackTerraformProvisioner Class
    prov_obj = OpenstackTerraformProvisioner()

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Script to manage instances in Openstack",
    )

    subparsers = parser.add_subparsers(title="Available sub commands", help="sub-command help")

    # Argument parsers for create_instance
    create_instance_parser = subparsers.add_parser(
        "create_instance",
        help=("Creates an instance in OpenStack"),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    optional_create_instance_parser = create_instance_parser._action_groups.pop()
    required_create_instance_parser = create_instance_parser.add_argument_group("required arguments")
    create_instance_parser._action_groups.append(optional_create_instance_parser)
    required_create_instance_parser.add_argument(
        "--cloud_name",
        help="Cloud provider name",
        action="store",
        dest="cloud_name",
        required=True,
    )
    required_create_instance_parser.add_argument(
        "--vm_name", help="vm name", action="store", dest="vm_name", required=True
    )
    required_create_instance_parser.add_argument(
        "--vm_user",
        help="vm instance username",
        action="store",
        dest="vm_user",
        required=True,
    )
    required_create_instance_parser.add_argument(
        "--vm_private_key",
        help="vm instance private key to login with",
        action="store",
        dest="vm_private_key",
        required=True,
    )
    required_create_instance_parser.add_argument(
        "--key_pair",
        help="The public key of an OpenSSH key pair to be used for access to created instances",
        action="store",
        dest="key_pair",
        required=True,
    )
    required_create_instance_parser.add_argument(
        "--network_name",
        help="Network Name",
        action="store",
        dest="network_name",
        required=True,
    )
    optional_create_instance_parser.add_argument(
        "--flavor-name",
        help="Flavour name",
        action="store",
        dest="flavor_name",
        metavar="",
        default="m1.medium",
    )
    optional_create_instance_parser.add_argument(
        "--image-name",
        help="Image name to create an instance",
        action="store",
        dest="image_name",
        metavar="",
        default="CentOS-Stream-8-x86_64-GenericCloud",
    )
    create_instance_parser.set_defaults(func=prov_obj.create_instance)

    # Argument parsers for delete_instance
    delete_instance_parser = subparsers.add_parser(
        "delete_instance",
        help=("Deletes an instance in OpenStack"),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    optional_delete_instance_parser = delete_instance_parser._action_groups.pop()
    required_delete_instance_parser = delete_instance_parser.add_argument_group("required arguments")
    delete_instance_parser._action_groups.append(optional_delete_instance_parser)
    required_delete_instance_parser.add_argument(
        "--cloud_name",
        help="Cloud provider name",
        action="store",
        dest="cloud_name",
        required=True,
    )
    required_delete_instance_parser.add_argument(
        "--vm_name", help="vm name", action="store", dest="vm_name", required=True
    )
    required_delete_instance_parser.add_argument(
        "--key_pair",
        help="The public key of an OpenSSH key pair to be used for access to created instances",
        action="store",
        dest="key_pair",
        required=True,
    )
    required_delete_instance_parser.add_argument(
        "--network_name",
        help="Network Name",
        action="store",
        dest="network_name",
        required=True,
    )
    optional_delete_instance_parser.add_argument(
        "--flavor-name",
        help="Flavour name",
        action="store",
        dest="flavor_name",
        metavar="",
        default="m1.medium",
    )
    optional_delete_instance_parser.add_argument(
        "--image-name",
        help="Image name to create an instance",
        action="store",
        dest="image_name",
        metavar="",
        default="CentOS-Stream-8-x86_64-GenericCloud",
    )
    delete_instance_parser.set_defaults(func=prov_obj.delete_instance)

    # Argument parsers for set_config
    set_config_parser = subparsers.add_parser(
        "set_config",
        help=("Sets config for using Openstack with terraform"),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    optional_set_config_parser = set_config_parser._action_groups.pop()
    required_set_config_parser = set_config_parser.add_argument_group("required arguments")
    set_config_parser._action_groups.append(optional_set_config_parser)
    required_set_config_parser.add_argument(
        "--cloud_name",
        help="Cloud provider name",
        action="store",
        dest="cloud_name",
        required=True,
    )
    required_set_config_parser.add_argument(
        "--auth_url",
        help="The identity authentication URL",
        action="store",
        dest="auth_url",
        required=True,
    )
    required_set_config_parser.add_argument(
        "--username",
        help="The Username to login with",
        action="store",
        dest="username",
        required=True,
    )
    required_set_config_parser.add_argument(
        "--password",
        help="The Password to login with",
        action="store",
        dest="password",
        required=True,
    )
    required_set_config_parser.add_argument(
        "--project_id",
        help="The project ID to login with",
        action="store",
        dest="project_id",
        required=True,
    )
    required_set_config_parser.add_argument(
        "--project_name",
        help="The project name to login with",
        action="store",
        dest="project_name",
        required=True,
    )
    required_set_config_parser.add_argument(
        "--user_domain_name",
        help="The domain name where the user is located",
        action="store",
        dest="user_domain_name",
        required=True,
    )
    required_set_config_parser.add_argument(
        "--region_name",
        help="The region of the OpenStack cloud to use",
        action="store",
        dest="region_name",
        required=True,
    )
    required_set_config_parser.add_argument(
        "--interface",
        help="Interface Name",
        action="store",
        dest="interface",
        required=True,
    )
    required_set_config_parser.add_argument(
        "--identity_api_version",
        help="Identity API verson to use",
        action="store",
        dest="identity_api_version",
        required=True,
    )

    set_config_parser.set_defaults(func=prov_obj.set_config)

    args = parser.parse_args(namespace=prov_obj)
    if hasattr(args, "func"):
        args.func()
