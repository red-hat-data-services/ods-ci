import sys
from logging import log
from time import sleep

from util import execute_command


def create_account_roles():
    cmd_create_account_roles = [
        "rosa",
        "create",
        "account-roles",
        "--mode",
        "auto",
        "--yes",
    ]

    ret = execute_command(" ".join(cmd_create_account_roles))
    if ret is None:
        print("Failed  to Create account roles")
        return ret


def rosa_create_cluster(
    cluster_name,
    region,
    channel_name,
    compute_nodes,
    compute_machine_type,
    rosa_version,
    sts=True,
):
    if sts is True:
        cmd_rosa_create_cluster = [
            "rosa",
            "create",
            "cluster",
            "--cluster-name",
            cluster_name,
            "--replicas   ",
            compute_nodes,
            "--region",
            region,
            "--compute-machine-type",
            compute_machine_type,
            "--yes",
            "--sts",
            "--version",
            rosa_version,
            "--channel-group",
            channel_name,
        ]
        execute_command(" ".join(cmd_rosa_create_cluster))
    else:
        cmd_rosa_create_cluster = [
            "rosa",
            "create",
            "cluster",
            "--cluster-name",
            cluster_name,
            "--replicas   ",
            compute_nodes,
            "--region",
            region,
            "--compute-machine-type",
            compute_machine_type,
            "--yes",
            "--version",
            rosa_version,
            "--channel-group",
            channel_name,
        ]
        execute_command(" ".join(cmd_rosa_create_cluster))

    cmd_create_operator_roles = [
        "rosa",
        "create",
        "operator-roles",
        "--cluster",
        cluster_name,
        "--mode",
        "auto",
        "--region",
        region,
        "--yes",
    ]
    ret = execute_command(" ".join(cmd_create_operator_roles))
    print(" ".join(cmd_create_operator_roles))
    if ret is None:
        print("Failed  to Create operator-roles")
        return ret

    cmd_create_oidc_provider = [
        "rosa",
        "create",
        "oidc-provider",
        "--cluster",
        cluster_name,
        "--mode",
        "auto",
        "--region",
        region,
        "--yes",
    ]
    ret = execute_command(" ".join(cmd_create_oidc_provider))
    if ret is None:
        print("Failed  to Create oidc roles")
        return ret

    cmd_check_cluster = [
        "rosa",
        "describe",
        "cluster",
        "--cluster={}".format(cluster_name),
    ]
    ret = execute_command(" ".join(cmd_check_cluster))
    if ret is None:
        print("Failed  creation failed")
        return ret
    print("ret = {}".format(ret))


def rosa_describe(cluster_name, filter=""):
    """Describes cluster and returns cluster info"""
    cmd = "rosa describe cluster --cluster {}".format(cluster_name)
    if filter != "":
        cmd += " " + filter
    ret = execute_command(cmd)
    if ret is None:
        print("rosa describe for cluster {} failed".format(cluster_name))
        return None
    return ret


def get_rosa_cluster_state(cluster_name):
    """Gets osd cluster state"""

    cluster_state = rosa_describe(cluster_name, filter="--output json | jq -r '.state'")
    if cluster_state is None:
        print("Unable to retrieve cluster state for cluster name {}. EXITING".format(cluster_name))
        sys.exit(1)
    cluster_state = cluster_state.strip("\n")
    return cluster_state


def wait_for_osd_cluster_to_be_ready(cluster_name, timeout=7200):
    """Waits for cluster to be in ready state"""

    print("Waiting for cluster to be ready")
    cluster_state = get_rosa_cluster_state(cluster_name)
    count = 0
    check_flag = False
    while count <= timeout:
        cluster_state = get_rosa_cluster_state(cluster_name)
        if cluster_state == "ready":
            print("{} is in ready state".format(cluster_name))
            check_flag = True
            break
        elif cluster_state == "error":
            print("{} is in error state. Hence exiting!!".format(cluster_name))
            sys.exit(1)

        sleep(60)
        count += 60
    if not check_flag:
        print("{} not in ready state even after 2 hours. EXITING".format(cluster_name))
        sys.exit(1)
