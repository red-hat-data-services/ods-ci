
import os
import subprocess
import shutil
import yaml
import re
import sys

def clone_config_repo(**kwargs):
    """
    Helper function to clone git repo
    """
    if "git_username" not in kwargs.keys():
        kwargs["git_username"] = ""

    if "git_password" not in kwargs.keys():
        kwargs["git_password"] = ""

    try:
       if os.path.exists(kwargs["repo_dir"]) and os.path.isdir(kwargs["repo_dir"]):
           shutil.rmtree(kwargs["repo_dir"])
       os.makedirs(kwargs["repo_dir"])
       print("git repo dir '%s' created successfully" % kwargs["repo_dir"])
    except OSError as error:
       print("git repo dir '%s' can not be created." % kwargs["repo_dir"])
       return False

    git_repo_with_credens = kwargs["git_repo"]
    if kwargs["git_username"] != "" and kwargs["git_password"] != "":
        git_credens = "{}:{}".format(kwargs["git_username"], kwargs["git_password"])
        git_repo_with_credens = re.sub(r'(https://)(.*)', r'\1' + git_credens + "@" + r'\2', kwargs["git_repo"])
    cmd = "git clone {} -b {} {}".format(git_repo_with_credens, kwargs["git_branch"], kwargs["repo_dir"])
    ret = subprocess.call(cmd, shell=True)
    if ret:
        print("Failed to clone repo {}.".format(kwargs["git_repo"]))
        return False
    return True


def read_yaml(filename):
    """
    Reads the given config file and returns the contents of file in dict format
    """
    try:
        with open(filename, 'r') as fh:
            return yaml.safe_load(fh)
    except OSError as error:
        return None


def execute_command(cmd):
    """
    Executes command in the local node
    """
    try:
        process = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
        output = process.stdout
        return output
    except:
        return None


def oc_login(ocp_console_url, username, password):
    """
    Login to test cluster using oc cli command
    """
    cluster_api_url = ocp_console_url.replace("console-openshift-console.apps", "api")
    cluster_api_url = re.sub(r'/$','', cluster_api_url) + ":6443"
    cmd = "oc login -u {} -p {} {} --insecure-skip-tls-verify=true".format(username, password, cluster_api_url)
    out = execute_command(cmd)
    if "Login successful" in out:
        print ("Logged into cluster successfully")
    else:
        print ("Failed to login to cluster")
        sys.exit(1)
