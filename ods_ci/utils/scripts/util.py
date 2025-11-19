import json
import os
import re
import shutil
import subprocess
import sys
import time

import jinja2
import yaml

from ods_ci.utils.scripts.logger import log


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
    except OSError:
        print("git repo dir '%s' can not be created." % kwargs["repo_dir"])
        return False

    git_repo_with_credens = kwargs["git_repo"]
    if kwargs["git_username"] != "" and kwargs["git_password"] != "":
        git_credens = "{}:{}".format(kwargs["git_username"], kwargs["git_password"])
        git_repo_with_credens = re.sub(r"(https://)(.*)", r"\1" + git_credens + "@" + r"\2", kwargs["git_repo"])
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
        with open(filename, "r") as fh:
            return yaml.safe_load(fh)
    except OSError:
        return None


def execute_command(cmd: str, print_stdout: bool = True) -> str | None:
    """
    Executes command in the local node, and print real-time output
    """
    log.info(f"CMD: {cmd}")
    try:
        with subprocess.Popen(
            cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            encoding="utf-8",
            errors="replace",
        ) as p:
            output = []
            for line in p.stdout:
                output.append(line)
                if print_stdout:
                    print(">:", line.expandtabs(tabsize=8), end="")
                    sys.stdout.flush()
            return "".join(output)
    except Exception as e:
        log.exception(f"Starting the subprocess '{cmd}' failed", exc_info=e)
    return None


def oc_login(ocp_api_url="", username="", password="", kubeconfig_path="", timeout=600):
    """
    Login to test cluster using oc cli command:
    - If kubeconfig_path is set (path to a kubeconfig file), do NOT use username/password.
      Instead, rely on that kubeconfig and just validate access with `oc whoami`.
    - Otherwise, login with expected username/password credentials.
    """
    if kubeconfig_path:
        os.environ["KUBECONFIG"] = kubeconfig_path
        log.info("Using KUBECONFIG, skipping username/password login")

        if (not os.path.exists(kubeconfig_path)) or (os.path.getsize(kubeconfig_path) == 0):
            log.error("kubeconfig does not exist or is empty")
            sys.exit(1)

        out = execute_command(f"oc config get-contexts --kubeconfig={external_kcfg}")
        if out is None or not out.strip():
            log.error("kubeconfig is invalid or missing contexts")
            sys.exit(1)

        count = 0
        while count <= timeout:
            out = execute_command("oc whoami")
            if out and out.strip() and "Missing or incomplete configuration info" not in out:
                print(f"Kubeconfig context valid, current user={out.strip()}")
                return
            time.sleep(5)
            count += 5

        log.error("Failed to validate kubeconfig context via 'oc whoami'")
        sys.exit(1)

    if not ocp_api_url or not username or not password:
        log.error("Missing API URL / IDP credentials for cluster login")
        sys.exit(1)

    cmd = f"oc login -u {username} -p {password} {ocp_api_url} --insecure-skip-tls-verify=true"
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
        log.error("Failed to login to cluster")
        sys.exit(1)


def oc_login_oidc(ocp_api_url, username, password, issuer_url, timeout=600):
    """
    Login to test cluster using oidc
    """
    setup_cmd = f"""
        oc config set-cluster test-cluster \
            --server={ocp_api_url} \
            --insecure-skip-tls-verify=true && \
        oc config set-context main \
            --cluster=test-cluster \
            --user={username} && \
        oc config use-context main
    """
    execute_command(setup_cmd)
    tokens = get_oidc_tokens(username, password, issuer_url)
    count = 0
    chk_flag = 0
    while count <= timeout:
        cmd = f"""
            oc config set-credentials "{username}"  \
                    --auth-provider=oidc  \
                    --auth-provider-arg=idp-issuer-url={issuer_url} \
                    --auth-provider-arg=client-id=oc-cli  \
                    --auth-provider-arg=client-secret=""  \
                    --auth-provider-arg=refresh-token={tokens["refresh_token"]} \
                    --auth-provider-arg=id-token={tokens["id_token"]}
            oc auth whoami
        """
        out = execute_command(cmd)
        if (out is not None) and (username in out):
            print("Logged into cluster successfully")
            chk_flag = 1
            break
        time.sleep(5)
        count += 5
    if not chk_flag:
        print("Failed to login to cluster")
        sys.exit(1)

def get_oidc_tokens(username, password, issuer_url, timeout=60):
    """
    Get id and refresh token from OIDC issuer
    """
    cmd = f"""
        curl -s -L -X POST "{issuer_url}/protocol/openid-connect/token" \
            -H "Content-Type: application/x-www-form-urlencoded" -d "username={username}" \
            -d "password={password}" -d "grant_type=password" -d "client_id=oc-cli" -d "scope=openid"
    """
    count = 0
    chk_flag = 0
    while count <= timeout:
        out = execute_command(cmd)
        try:
            tokens = json.loads(out)
            if "refresh_token" in tokens and "id_token" in tokens:
                print("Logged into OIDC issuer correctly")
                chk_flag = 1
                return tokens
        except Exception:
            print("Failed to parse tokens, retrying")
        time.sleep(5)
        count += 5
    if not chk_flag:
        print("Failed to obtain OIDC tokens")
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
    except Exception:
        print("Failed to render template and create json file {}".format(output_file))
        sys.exit(1)


def read_data_from_json(filename):
    """
    Helper to read Json file
    """
    try:
        with open(filename, "r") as f:
            data = json.load(f)
        return data
    except Exception:
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
