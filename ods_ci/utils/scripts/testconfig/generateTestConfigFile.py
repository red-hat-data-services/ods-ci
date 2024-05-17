# Script to generate test config file

import argparse
import os
import shutil
import sys

import yaml

dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path + "/../")
from util import clone_config_repo, execute_command, oc_login, read_yaml


def parse_args():
    """Parse CLI arguments"""
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Script to generate test config file",
    )
    parser.add_argument(
        "-u",
        "--gituser",
        help="git username",
        action="store",
        dest="git_username",
        default="",
    )
    parser.add_argument(
        "-p",
        "--gitpassword",
        help="git password",
        action="store",
        dest="git_password",
        default="",
    )
    parser.add_argument(
        "-r",
        "--gitrepo",
        help="config git repo for ods-ci tests",
        action="store",
        dest="git_repo",
        required=True,
    )
    parser.add_argument(
        "-b",
        "--gitRepoBranch",
        help="config git repo branch for ods-ci tests",
        action="store",
        dest="git_repo_branch",
        default="master",
    )
    parser.add_argument(
        "-d",
        "--repoDir",
        help="directory to clone the git repo",
        action="store",
        dest="repo_dir",
        default="configrepo",
    )
    parser.add_argument(
        "-c",
        "--configtemplate",
        help="absolute path of test config yaml file template",
        action="store",
        dest="config_template",
        default="utils/scripts/testconfig/test-variables.yml",
    )
    parser.add_argument(
        "-t",
        "--testcluster",
        help="Test cluster. Eg: modh-qe-1",
        action="store",
        dest="test_cluster",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--setPromotheusConfig",
        help="append prometheus config to config file",
        action="store_true",
        dest="set_prometheus_config",
    )

    parser.add_argument(
        "--setDashboardUrl",
        help="append dashboard Url to config file",
        action="store_true",
        dest="set_dashboard_url",
    )
    parser.add_argument(
        "-s",
        "--skip-git-clone",
        help="If this option is used then cloning config git repo for ods-ci tests is skipped.",
        action="store_true",
        dest="skip_clone",
    )
    parser.add_argument(
        "--components",
        type=str,
        dest="components",
        help="Comma-separated list of components and their states (component1:state1,component2:state2,...)",
    )
    parser.add_argument(
        "--custom_manifests",
        type=str,
        dest="custom_manifests",
        help="Comma-separated list of custom_manifests("
             "component1:repo_org:repo_name:branch_name:context_dir:source_path,"
             "component2:repo_org:repo_name:branch_name:context_dir:source_path,...)",
    )

    return parser.parse_args()


def change_component_state(components):
    # Parse and convert the component states argument into a dictionary
    component_states = {}
    components_list = components.split(",")
    for component in components_list:
        comp, state = component.split(":")
        print(comp, state)
        component_states[comp] = "Managed" if state.lower() == "managed" else "Removed"
        print(component_states[comp])

    print(component_states)
    return component_states


def initialize_custom_manifest(custom_manifests):
    # Parse and convert the custom manifest argument into a dictionary
    manifest_details = {}
    custom_manifest_list = custom_manifests.split(",")

    for custom_manifest in custom_manifest_list:
        comp, repo_org, repo_name, branch_name, context_dir, source_path = custom_manifest.split(":")
        comp_manifest = {
            "uri": f"https://github.com/{repo_org}/{repo_name}/tarball/{branch_name}",
            "contextDir": context_dir,
            "sourcePath": source_path if len(source_path) > 0 else ""
        }

        if comp not in manifest_details:
            manifest_details[comp] = {"manifests": []}

        manifest_details[comp]["manifests"].append(comp_manifest)

    return manifest_details


def get_prometheus_token(project):
    """
    Get prometheus token for the cluster.
    """
    cmd = "oc create token prometheus -n {} --duration 6h".format(project)
    prometheus_token = execute_command(cmd)
    return prometheus_token.strip("\n")


def get_prometheus_url(project):
    """
    Get prometheus url for the cluster.
    """
    host_jsonpath = "{.spec.host}"
    cmd = "oc get route prometheus -n {} -o jsonpath='{}'".format(project, host_jsonpath)
    prometheus_url = execute_command(cmd)
    return "https://" + prometheus_url.strip("\n")


def get_dashboard_url():
    """
    Get dashboard url for the open data science.
    """
    cmd = "oc get route -A -o json  | jq '.items[].spec.host' | grep 'dashboard'"

    dashboard_url = execute_command(cmd)
    return "https://" + dashboard_url.strip('"').strip("\n")


def generate_test_config_file(
    config_template,
    config_data,
    test_cluster,
    set_prometheus_config,
    set_dashboard_url,
    components=None,
    custom_manifests=None,
):
    """
    Generates test config file dynamically by
     substituting the values in a template file.
    """
    shutil.copy(config_template, ".")
    config_file = os.path.basename(config_template)
    with open(config_file, "r") as fh:
        data = yaml.safe_load(fh)

    data["BROWSER"]["NAME"] = config_data["BROWSER"]["NAME"]
    data["S3"]["AWS_ACCESS_KEY_ID"] = config_data["S3"]["AWS_ACCESS_KEY_ID"]
    data["S3"]["AWS_SECRET_ACCESS_KEY"] = config_data["S3"]["AWS_SECRET_ACCESS_KEY"]
    data["S3"]["AWS_DEFAULT_ENDPOINT"] = config_data["S3"]["AWS_DEFAULT_ENDPOINT"]
    data["S3"]["AWS_DEFAULT_REGION"] = config_data["S3"]["AWS_DEFAULT_REGION"]
    if config_data["S3"].get("AWS_CA_BUNDLE"):
        data["S3"]["AWS_CA_BUNDLE"] = config_data["S3"]["AWS_CA_BUNDLE"]
    data["S3"]["BUCKET_1"]["NAME"] = config_data["S3"]["BUCKET_1"]["NAME"]
    data["S3"]["BUCKET_1"]["REGION"] = config_data["S3"]["BUCKET_1"]["REGION"]
    data["S3"]["BUCKET_1"]["ENDPOINT"] = config_data["S3"]["BUCKET_1"]["ENDPOINT"]
    data["S3"]["BUCKET_2"]["NAME"] = config_data["S3"]["BUCKET_2"]["NAME"]
    data["S3"]["BUCKET_2"]["REGION"] = config_data["S3"]["BUCKET_2"]["REGION"]
    data["S3"]["BUCKET_2"]["ENDPOINT"] = config_data["S3"]["BUCKET_2"]["ENDPOINT"]
    data["S3"]["BUCKET_3"]["NAME"] = config_data["S3"]["BUCKET_3"]["NAME"]
    data["S3"]["BUCKET_3"]["REGION"] = config_data["S3"]["BUCKET_3"]["REGION"]
    data["S3"]["BUCKET_3"]["ENDPOINT"] = config_data["S3"]["BUCKET_3"]["ENDPOINT"]
    data["S3"]["BUCKET_4"]["NAME"] = config_data["S3"]["BUCKET_4"]["NAME"]
    data["S3"]["BUCKET_4"]["REGION"] = config_data["S3"]["BUCKET_4"]["REGION"]
    data["S3"]["BUCKET_4"]["ENDPOINT"] = config_data["S3"]["BUCKET_4"]["ENDPOINT"]
    data["S3"]["BUCKET_5"]["NAME"] = config_data["S3"]["BUCKET_5"]["NAME"]
    data["S3"]["BUCKET_5"]["REGION"] = config_data["S3"]["BUCKET_5"]["REGION"]
    data["S3"]["BUCKET_5"]["ENDPOINT"] = config_data["S3"]["BUCKET_5"]["ENDPOINT"]
    data["ANACONDA_CE"]["ACTIVATION_KEY"] = config_data["ANACONDA_CE"]["ACTIVATION_KEY"]
    data["OCP_CONSOLE_URL"] = config_data["TEST_CLUSTERS"][test_cluster]["OCP_CONSOLE_URL"]
    data["ODH_DASHBOARD_URL"] = config_data["TEST_CLUSTERS"][test_cluster]["ODH_DASHBOARD_URL"]
    data["TEST_USER"]["AUTH_TYPE"] = config_data["TEST_CLUSTERS"][test_cluster]["TEST_USER"]["AUTH_TYPE"]
    data["TEST_USER"]["USERNAME"] = config_data["TEST_CLUSTERS"][test_cluster]["TEST_USER"]["USERNAME"]
    data["TEST_USER"]["PASSWORD"] = config_data["TEST_CLUSTERS"][test_cluster]["TEST_USER"]["PASSWORD"]
    data["OCP_ADMIN_USER"]["AUTH_TYPE"] = config_data["TEST_CLUSTERS"][test_cluster]["OCP_ADMIN_USER"]["AUTH_TYPE"]
    data["OCP_ADMIN_USER"]["USERNAME"] = config_data["TEST_CLUSTERS"][test_cluster]["OCP_ADMIN_USER"]["USERNAME"]
    data["OCP_ADMIN_USER"]["PASSWORD"] = config_data["TEST_CLUSTERS"][test_cluster]["OCP_ADMIN_USER"]["PASSWORD"]
    data["SSO"]["USERNAME"] = config_data["SSO"]["USERNAME"]
    data["SSO"]["PASSWORD"] = config_data["SSO"]["PASSWORD"]
    data["RHODS_BUILD"]["PULL_SECRET"] = config_data["RHODS_BUILD"]["PULL_SECRET"]
    data["RHODS_BUILD"]["SECRET_FILE"] = config_data["RHODS_BUILD"]["SECRET_FILE"]
    data["RHODS_BUILD"]["IMAGE"] = config_data["RHODS_BUILD"]["IMAGE"]
    data["TEST_USER_2"]["AUTH_TYPE"] = config_data["TEST_USER_2"]["AUTH_TYPE"]
    data["TEST_USER_2"]["USERNAME"] = config_data["TEST_USER_2"]["USERNAME"]
    data["TEST_USER_2"]["PASSWORD"] = config_data["TEST_USER_2"]["PASSWORD"]
    data["TEST_USER_3"]["AUTH_TYPE"] = config_data["TEST_USER_3"]["AUTH_TYPE"]
    data["TEST_USER_3"]["USERNAME"] = config_data["TEST_USER_3"]["USERNAME"]
    data["TEST_USER_3"]["PASSWORD"] = config_data["TEST_USER_3"]["PASSWORD"]
    data["TEST_USER_4"]["AUTH_TYPE"] = config_data["TEST_USER_4"]["AUTH_TYPE"]
    data["TEST_USER_4"]["USERNAME"] = config_data["TEST_USER_4"]["USERNAME"]
    data["TEST_USER_4"]["PASSWORD"] = config_data["TEST_USER_4"]["PASSWORD"]
    data["GITHUB_USER"]["EMAIL"] = config_data["GITHUB_USER"]["EMAIL"]
    data["GITHUB_USER"]["USERNAME"] = config_data["GITHUB_USER"]["USERNAME"]
    data["GITHUB_USER"]["TOKEN"] = config_data["GITHUB_USER"]["TOKEN"]
    data["SERVICE_ACCOUNT"]["NAME"] = config_data["SERVICE_ACCOUNT"]["NAME"]
    data["SERVICE_ACCOUNT"]["FULL_NAME"] = config_data["SERVICE_ACCOUNT"]["FULL_NAME"]
    data["STARBURST"]["LICENSE_ENCODED"] = config_data["STARBURST"]["LICENSE_ENCODED"]
    data["DEFAULT_NOTIFICATION_EMAIL"] = config_data["DEFAULT_NOTIFICATION_EMAIL"]
    data["RHM_TOKEN"] = config_data["RHM_TOKEN"]
    data["PRODUCT"] = config_data["PRODUCT"]
    data["APPLICATIONS_NAMESPACE"] = config_data["APPLICATIONS_NAMESPACE"]
    data["MONITORING_NAMESPACE"] = config_data["MONITORING_NAMESPACE"]
    data["OPERATOR_NAME"] = config_data["OPERATOR_NAME"]
    data["OPERATOR_NAMESPACE"] = config_data["OPERATOR_NAMESPACE"]
    data["NOTEBOOKS_NAMESPACE"] = config_data["NOTEBOOKS_NAMESPACE"]
    data["OPENSHIFT_PIPELINES_CHANNEL"] = config_data["OPENSHIFT_PIPELINES_CHANNEL"]
    if config_data.get("PIP_INDEX_URL"):
        data["PIP_INDEX_URL"] = config_data["PIP_INDEX_URL"]
    if config_data.get("PIP_TRUSTED_HOST"):
        data["PIP_TRUSTED_HOST"] = config_data["PIP_TRUSTED_HOST"]
    if config_data.get("PIP_CA_BUNDLE"):
        data["PIP_CA_BUNDLE"] = config_data["PIP_CA_BUNDLE"]

    # Git mirror details (optional)
    if config_data.get("GIT_HTTP_URL"):
        data["GIT_HTTP_URL"] = config_data["GIT_HTTP_URL"]
    if config_data.get("GIT_HTTPS_URL"):
        data["GIT_HTTPS_URL"] = config_data["GIT_HTTPS_URL"]
    if config_data.get("GIT_HTTPS_CA_BUNDLE"):
        data["GIT_HTTPS_CA_BUNDLE"] = config_data["GIT_HTTPS_CA_BUNDLE"]

    if components:
        print("Setting components")
        print(components)
        data["COMPONENTS"] = change_component_state(components)

    if custom_manifests:
        print("Setting custom_manifest")
        print(custom_manifests)
        data["CUSTOM_MANIFESTS"] = initialize_custom_manifest(custom_manifests)

    # Login to test cluster using oc command
    oc_login(
        data["OCP_CONSOLE_URL"],
        data["OCP_ADMIN_USER"]["USERNAME"],
        data["OCP_ADMIN_USER"]["PASSWORD"],
    )
    print("After oc login")

    if bool(set_prometheus_config):
        # Get prometheus token for test cluster
        prometheus_token = get_prometheus_token("redhat-ods-monitoring")
        data["RHODS_PROMETHEUS_TOKEN"] = prometheus_token

        # Get prometheus url
        prometheus_url = get_prometheus_url("redhat-ods-monitoring")
        data["RHODS_PROMETHEUS_URL"] = prometheus_url

    if bool(set_dashboard_url):
        # Get Dashboard url for open data science
        dashboard_url = get_dashboard_url()
        data["ODH_DASHBOARD_URL"] = dashboard_url.replace('"', "")

    with open(config_file, "w") as yaml_file:
        yaml_file.write(yaml.dump(data, default_flow_style=False, sort_keys=False))


def main():
    """main function"""

    args = parse_args()

    if not args.skip_clone:
        ret = clone_config_repo(
            git_repo=args.git_repo,
            git_branch=args.git_repo_branch,
            repo_dir=args.repo_dir,
            git_username=args.git_username,
            git_password=args.git_password,
        )
        if not ret:
            sys.exit(1)
    else:
        print("Skipping cloning of config gitlab repo")

    config_file = args.repo_dir + "/test-variables.yml"
    config_data = read_yaml(config_file)

    # Generate test config file
    generate_test_config_file(
        args.config_template,
        config_data,
        args.test_cluster,
        args.set_prometheus_config,
        args.set_dashboard_url,
        components=args.components,
        custom_manifests=args.custom_manifests,
    )
    print("Done generating config file")


if __name__ == "__main__":
    main()
