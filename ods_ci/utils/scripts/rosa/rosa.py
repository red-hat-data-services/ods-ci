import argparse
import os
import sys

dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path + "/../")
from awsOps import aws_configure
from logger import log
from rosaOps import create_account_roles, rosa_create_cluster, wait_for_osd_cluster_to_be_ready


class RosaClusterManager:
    def __init__(self, args={}):
        self.aws_access_key_id = args.get("aws_access_key_id")
        self.aws_secret_access_key = args.get("aws_secret_access_key")
        self.aws_region = args.get("aws_region")
        self.profile = args.get("profile")
        self.cluster_name = args.get("cluster_name")
        self.compute_nodes = args.get("compute_nodes")
        self.compute_machine_type = args.get("compute_machine_type")
        self.rosa_version = args.get("rosa_version")
        self.channel_name = args.get("channel_name")

    def create_rosa_cluster(self):
        print(
            self.cluster_name,
            self.aws_region,
            self.channel_name,
            self.compute_nodes,
            self.compute_machine_type,
            self.rosa_version,
        )
        aws_configure(self.aws_access_key_id, self.aws_secret_access_key, self.aws_region)
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
    rosaClusterCreate_parser = subparsers.add_parser(
        "create_rosa_cluster",
        help=("create ROSA clusters using openshift installer"),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    rosaClusterCreate_parser.add_argument(
        "--aws-access-key-id",
        required=True,
        action="store",
        dest="aws_access_key_id",
        help="AWS access key ID",
    )

    rosaClusterCreate_parser.add_argument(
        "--aws-secret-access-key",
        required=True,
        action="store",
        dest="aws_secret_access_key",
        help="AWS secret access key",
    )

    rosaClusterCreate_parser.add_argument(
        "--aws_region",
        required=True,
        action="store",
        dest="aws_region",
        help="AWS aws_region",
    )

    rosaClusterCreate_parser.add_argument(
        "--cluster-name",
        required=True,
        action="store",
        dest="cluster_name",
        help="ROSA cluster name",
    )

    rosaClusterCreate_parser.add_argument(
        "--compute_nodes",
        required=True,
        action="store",
        dest="compute_nodes",
        help="Number of compute nodes",
    )

    rosaClusterCreate_parser.add_argument(
        "--compute-machine-type",
        required=True,
        action="store",
        dest="compute_machine_type",
        help="Compute machine type",
    )

    rosaClusterCreate_parser.add_argument(
        "--osd-version",
        required=True,
        action="store",
        dest="rosa_version",
        help="ROSA version",
    )
    rosaClusterCreate_parser.add_argument(
        "--channel-name",
        required=True,
        action="store",
        dest="channel_name",
        help="Channel Group Stable/Candidate",
    )
    rosa_cluster_manager = RosaClusterManager()

    rosaClusterCreate_parser.set_defaults(func=rosa_cluster_manager.create_rosa_cluster)
    args = parser.parse_args(namespace=rosa_cluster_manager)
    if hasattr(args, "func"):
        args.func()


if __name__ == "__main__":
    main()
