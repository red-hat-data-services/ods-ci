from logging import log
from time import sleep

from util import execute_command


def aws_configure(aws_access_key_id, aws_secret_access_key, aws_region):
    """
    Runs aws configure and set the configuration required
    for OpenShift/ROSA Installation
    """
    cmd_aws_configure_key_id = [
        "aws",
        "configure",
        "set",
        "default.aws_access_key_id",
        aws_access_key_id,
    ]
    ret = execute_command(" ".join(cmd_aws_configure_key_id))
    if ret is None:
        print("Failed  to configure aws_access_key_id")
        return ret
    sleep(1)

    cmd_aws_configure_access_id = [
        "aws",
        "configure",
        "set",
        "default.aws_secret_access_key",
        aws_secret_access_key,
    ]
    ret = execute_command(" ".join(cmd_aws_configure_access_id))
    if ret is None:
        print("Failed  to configure aws_secret_access_key")
        return ret
    sleep(1)

    cmd_aws_configure_region = ["aws", "configure", "set", "default.region", aws_region]
    ret = execute_command(" ".join(cmd_aws_configure_region))
    if ret is None:
        print("Failed  to configure region")
        return ret
