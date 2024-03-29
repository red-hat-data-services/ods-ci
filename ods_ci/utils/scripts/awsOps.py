from time import sleep

from logger import log
from util import execute_command


def aws_configure_execute_cmd(aws_key, aws_value, aws_profile):
    aws_configure_cmd = ["aws", "configure", "set", aws_key, aws_value, "--profile", aws_profile]
    ret = execute_command(" ".join(aws_configure_cmd))
    if ret is None:
        log.error(f"Failed to configure {aws_key}")
        return ret
    sleep(1)
    return None


def aws_configure(aws_access_key_id, aws_secret_access_key, aws_region, aws_profile="default"):
    """
    Runs aws configure and set the configuration required
    for OpenShift/ROSA Installation
    """
    aws_configure_execute_cmd(aws_key="aws_access_key_id", aws_value=aws_access_key_id, aws_profile=aws_profile)
    aws_configure_execute_cmd(aws_key="aws_secret_access_key", aws_value=aws_secret_access_key, aws_profile=aws_profile)
    aws_configure_execute_cmd(aws_key="region", aws_value=aws_region, aws_profile=aws_profile)
