
import os
import subprocess
import shutil
import yaml
import re

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
