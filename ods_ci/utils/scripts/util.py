import json
import os
import re
import shutil
import subprocess
import sys
import time

import jinja2
import yaml


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
        git_repo_with_credens = re.sub(
            r"(https://)(.*)", r"\1" + git_credens + "@" + r"\2", kwargs["git_repo"]
        )
    cmd = "git clone {} -b {} {}".format(
        git_repo_with_credens, kwargs["git_branch"], kwargs["repo_dir"]
    )
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
        with open(filename, "r") as fh:
            return yaml.safe_load(fh)
    except OSError as error:
        return None
          

def execute_command(cmd):
    """
    Executes command in the local node, and print real-time output
    """
    output = ''
    with subprocess.Popen(
            cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            encoding='utf-8',
            errors='replace'
        ) as p:
            while True:
                line = p.stdout.readline()
                if line != '':
                    output += (line + "\n")
                    print(line)
                elif p.poll() != None:
                    break
            sys.stdout.flush()
            exitCode = p.returncode
            if (exitCode == 0):
                return output
            else:
                raise Exception(cmd, exitCode, output)


def oc_login(ocp_console_url, username, password, timeout=600):
    """
    Login to test cluster using oc cli command
    """
    cluster_api_url = ocp_console_url.replace("console-openshift-console.apps", "api")
    cluster_api_url = re.sub(r"/$", "", cluster_api_url) + ":6443"
    cmd = "oc login -u {} -p {} {} --insecure-skip-tls-verify=true".format(
        username, password, cluster_api_url
    )
    count = 0
    chk_flag = 0
    while count <= timeout:
        out = execute_command(cmd)
        if (out is not None) and ("Login successful" in out):
            print("Logged into cluster successfully")
            chk_flag = 1
            break
        time.sleep(5)
        count += 5
    if not chk_flag:
        print("Failed to login to cluster")
        sys.exit(1)


def render_template(search_path, template_file, output_file, replace_vars):
    """Helper module to render jinja template"""

    try:
        templateLoader = jinja2.FileSystemLoader(searchpath=search_path)
        templateEnv = jinja2.Environment(loader=templateLoader)
        template = templateEnv.get_template(template_file)
        outputText = template.render(replace_vars)
        with open(output_file, "w") as fh:
            fh.write(outputText)
    except:
        print(
            "Failed to render template and create json " "file {}".format(output_file)
        )
        sys.exit(1)


def read_data_from_json(filename):
    """
    Helper to read Json file
    """
    try:
        with open(filename, "r") as f:
            data = json.load(f)
        return data
    except:
        return None


def write_data_in_json(filename, data):
    """
    Helper to write JSON file
    """
    with open(filename, "w") as convert_file:
        convert_file.write(json.dumps(data))


def compare_dicts(dict1, dict2, level=0):
    """
    Helper to compare Dictionary and returns Difference
    """
    lst_to_trigger_job = []
    if not (isinstance(dict1, dict) or isinstance(dict2, dict)):
        if dict1 == dict2:
            return "OK!"
        else:
            return "MISMATCH!"

    keys1 = set(dict1.keys())
    keys2 = set(dict2.keys())
    if len(keys1 | keys2) == 0:
        return "" if level else None

    max_len = max(tuple(map(len, keys1 | keys2))) + 2
    for key in keys1 & keys2:
        if compare_dicts(dict1[key], dict2[key], level=level + 1) == "MISMATCH!":
            lst_to_trigger_job.append("{}-latest".format(key))
    for key in keys1 - keys2:
        lst_to_trigger_job.append("{}-latest".format(key))
    for key in keys2 - keys1:
        print(f'{key + ":":<{max_len}}' + "presented only in old", end="")
    return "" if level else lst_to_trigger_job
