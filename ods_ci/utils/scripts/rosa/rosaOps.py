import sys
from time import sleep

from logger import log
from util import execute_command


def rosa_whoami():
    cmd_rosa_whoami = [
        "rosa",
        "whoami",
    ]
    execute_command(" ".join(cmd_rosa_whoami))


def create_account_roles() -> str | None:
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
        log.error("Failed to Create account roles")
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

    if sts is True:
        cmd_rosa_create_cluster.append("--sts")
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
    if ret is None:
        log.error("Failed to Create operator-roles")
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
        log.error("Failed to Create oidc roles")
        return ret

    rosa_describe(cluster_name=cluster_name)
    return None


def rosa_describe(cluster_name, jq_filter=""):
    """Describes cluster and returns cluster info"""
    cmd_check_cluster = [
        "rosa",
        "describe",
        "cluster",
        f"--cluster={cluster_name}",
    ]
    if jq_filter:
        cmd_check_cluster.append(jq_filter)
    ret = execute_command(" ".join(cmd_check_cluster))
    if ret is None:
        log.error(f"rosa describe for cluster {cluster_name} failed")
        return None
    return ret


def get_rosa_cluster_state(cluster_name):
    """Gets osd cluster state"""

    cluster_state = rosa_describe(cluster_name, jq_filter="--output json | jq -r '.state'")
    if cluster_state is None:
        log.error(f"Unable to retrieve cluster state for cluster name {cluster_name}. EXITING")
        sys.exit(1)
    cluster_state = cluster_state.strip("\n")
    return cluster_state


def wait_for_osd_cluster_to_be_ready(cluster_name, timeout=7200):
    """Waits for cluster to be in ready state"""

    log.info("Waiting for cluster to be ready")
    cluster_state = get_rosa_cluster_state(cluster_name)
    count = 0
    check_flag = False
    while count <= timeout:
        cluster_state = get_rosa_cluster_state(cluster_name)
        if cluster_state == "ready":
            log.info(f"{cluster_name} is in ready state")
            check_flag = True
            break
        elif cluster_state == "error":
            log.error(f"{cluster_name} is in error state. Hence exiting!!")
            sys.exit(1)

        sleep(60)
        count += 60
    if not check_flag:
        log.error(f"{cluster_name} not in ready state even after 2 hours. EXITING")
        sys.exit(1)
