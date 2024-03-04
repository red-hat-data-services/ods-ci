import argparse
import os
import re
import sys

dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path + "/../")
from awsOps import aws_configure
from logger import log
from rosaOps import create_account_roles, rosa_create_cluster, rosa_whoami, wait_for_osd_cluster_to_be_ready
from util import execute_command


class RosaClusterManager:
    def __init__(self, args={}):
        self.aws_access_key_id = args.get("aws_access_key_id")
        self.aws_secret_access_key = args.get("aws_secret_access_key")
        self.aws_region = args.get("aws_region")
        self.aws_profile = args.get("aws_profile")
        self.cluster_name = args.get("cluster_name")
        self.compute_nodes = args.get("compute_nodes")
        self.compute_machine_type = args.get("compute_machine_type")
        self.rosa_version = args.get("rosa_version")
        self.channel_name = args.get("channel_name")

    def set_rosa_version(self):
        version_match = re.match(r"(\d+\.\d+)\-latest", self.rosa_version)
        if version_match is None:
            log.info(f"Using the rosa version given by user: {self.rosa_version}")
            return
        log.info(f"User provided {self.rosa_version}, trying to determine the appropriate latest version for ROSA")
        version = version_match.group(1)
        latest_version_cmd = (
            f"rosa list versions --channel-group {self.channel_name} | "
            f"awk '{{print $1}}' | grep -w '^{re.escape(version)}*' | head -n1"
        )
        latest_version = execute_command(latest_version_cmd)
        self.rosa_version = latest_version.strip()
        log.info(f"Using the latest rosa version: {self.rosa_version}")

    def create_rosa_cluster(self):
        log.info(
            "Creating ROSA cluster with the following details:\n"
            f"Name: {self.cluster_name}\n"
            f"Region: {self.aws_region}\n"
            f"Channel: {self.channel_name}\n"
            f"Compute Nodes: {self.compute_nodes}\n"
            f"Compute machine type: {self.compute_machine_type}\n"
            f"Rosa version: {self.rosa_version}\n"
        )
        aws_configure(self.aws_access_key_id, self.aws_secret_access_key, self.aws_region, self.aws_profile)
        rosa_whoami()
        self.set_rosa_version()
        create_account_roles()
        rosa_create_cluster(
            self.cluster_name,
            self.aws_region,
            self.channel_name,
            self.compute_nodes,
            self.compute_machine_type,
            self.rosa_version,
        )
        wait_for_osd_cluster_to_be_ready(self.cluster_name)


def main():
    parser = argparse.ArgumentParser(
        description="Create a ROSA cluster",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    # Argument parsers for create_cluster
    subparsers = parser.add_subparsers(title="Available sub commands", help="sub-command help")
    rosa_cluster_create_parser = subparsers.add_parser(
        "create_rosa_cluster",
        help="create ROSA clusters using openshift installer",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    rosa_cluster_create_parser.add_argument(
        "--aws-access-key-id",
        required=True,
        action="store",
        dest="aws_access_key_id",
        help="AWS access key ID",
    )

    rosa_cluster_create_parser.add_argument(
        "--aws-secret-access-key",
        required=True,
        action="store",
        dest="aws_secret_access_key",
        help="AWS secret access key",
    )

    rosa_cluster_create_parser.add_argument(
        "--aws_region",
        required=True,
        action="store",
        dest="aws_region",
        help="AWS aws_region",
    )

    rosa_cluster_create_parser.add_argument(
        "--aws_profile",
        required=False,
        action="store",
        dest="aws_profile",
        help="AWS aws_profile",
    )

    rosa_cluster_create_parser.add_argument(
        "--cluster-name",
        required=True,
        action="store",
        dest="cluster_name",
        help="ROSA cluster name",
    )

    rosa_cluster_create_parser.add_argument(
        "--compute_nodes",
        required=True,
        action="store",
        dest="compute_nodes",
        help="Number of compute nodes",
    )

    rosa_cluster_create_parser.add_argument(
        "--compute-machine-type",
        required=True,
        action="store",
        dest="compute_machine_type",
        help="Compute machine type",
    )

    rosa_cluster_create_parser.add_argument(
        "--osd-version",
        required=True,
        action="store",
        dest="rosa_version",
        help="ROSA version",
    )
    rosa_cluster_create_parser.add_argument(
        "--channel-name",
        required=True,
        action="store",
        dest="channel_name",
        help="Channel Group stable/candidate",
    )
    rosa_cluster_manager = RosaClusterManager()

    rosa_cluster_create_parser.set_defaults(func=rosa_cluster_manager.create_rosa_cluster)
    args = parser.parse_args(namespace=rosa_cluster_manager)
    if hasattr(args, "func"):
        args.func()


if __name__ == "__main__":
    main()
