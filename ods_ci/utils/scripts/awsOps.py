
from util import (
    execute_command,
)
from logging import log
from time import sleep
def aws_configure(aws_access_key_id, aws_secret_access_key, aws_region):
    """
    Runs aws configure and set the configuration required
    for OpenShift Installation

    === Code using pexpect ===
    configure_cmd = pexpect.spawn("aws configure")
    configure_cmd.expect("AWS Access Key ID .*: ")
    configure_cmd.sendline(aws_access_key_id)
    configure_cmd.expect("AWS Secret Access Key .*: ")
    configure_cmd.sendline(aws_secret_access_key)
    configure_cmd.expect("Default region name .*: ")
    configure_cmd.sendline(aws_region)
    configure_cmd.sendline("yaml")
    configure_cmd.interact()
    """
    print(aws_access_key_id, aws_secret_access_key, aws_region)

    cmd_aws_configure_key_id = ["aws", "configure", "set" ,"default.aws_access_key_id" ,aws_access_key_id]
    print(' '.join(cmd_aws_configure_key_id))
    ret = execute_command(' '.join(cmd_aws_configure_key_id))
    if ret is None:
        print("Failed  to configure aws_access_key_id")
        return ret 
    sleep(1)

    cmd_aws_configure_access_id = ["aws", "configure", "set" ,"default.aws_secret_access_key" ,aws_secret_access_key]
    print(' '.join(cmd_aws_configure_access_id))
    ret = execute_command(' '.join(cmd_aws_configure_access_id))
    if ret is None:
        print("Failed  to configure aws_secret_access_key")
        return ret     
    sleep(1)

    cmd_aws_configure_region = ["aws", "configure", "set" ,"default.region" ,aws_region]
    print(' '.join(cmd_aws_configure_region))
    ret = execute_command(' '.join(cmd_aws_configure_region))
    if ret is None:
        print("Failed  to configure region")
        return ret     
