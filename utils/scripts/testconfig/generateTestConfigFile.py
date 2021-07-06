# Script to generate test config file

import os
import argparse
import re
import subprocess
import shutil
import yaml
import sys
dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path+"/../")
from util import clone_config_repo, read_yaml

def parse_args():
    """Parse CLI arguments"""
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='Script to generate test config file'
        )
    parser.add_argument("-u", "--gituser",
                        help="git username",
                        action="store", dest="git_username",
                        default="")
    parser.add_argument("-p", "--gitpassword",
                        help="git password",
                        action="store", dest="git_password",
                        default="")
    parser.add_argument("-r", "--gitrepo",
                        help="config git repo for ods-ci tests",
                        action="store", dest="git_repo",
                        default="https://gitlab.cee.redhat.com/ods/odhcluster.git")
    parser.add_argument("-b", "--gitRepoBranch",
                        help="config git repo branch for ods-ci tests",
                        action="store", dest="git_repo_branch",
                        default="master")
    parser.add_argument("-d", "--repoDir",
                        help="directory to clone the git repo",
                        action="store", dest="repo_dir",
                        default="configrepo")
    parser.add_argument("-c", "--configtemplate",
                        help="absolute path of test config yaml file template",
                        action="store", dest="config_template",
                        default="utils/scripts/testconfig/test-variables.yml")
    parser.add_argument("-t", "--testcluster",
                        help="Test cluster. Eg: modh-qe-1",
                        action="store", dest="test_cluster",
                        required=True)
    parser.add_argument("-s", "--skip-git-clone",
                        help="If this option is used then cloning config git repo for ods-ci tests is skipped.",
                        action="store_true", dest="skip_clone")
    return parser.parse_args()


def generate_test_config_file(config_template, config_data, test_cluster):
    """
    Generates test config file dynamically by substituting the values in a template file.
    """
    shutil.copy(config_template, '.')
    config_file = os.path.basename(config_template)
    with open(config_file, 'r') as fh:
        data = yaml.safe_load(fh)

    data["BROWSER"]["NAME"] = config_data["BROWSER"]["NAME"]
    data["S3"]["AWS_ACCESS_KEY_ID"] = config_data["S3"]["AWS_ACCESS_KEY_ID"]
    data["S3"]["AWS_SECRET_ACCESS_KEY"] = config_data["S3"]["AWS_SECRET_ACCESS_KEY"]
    data["OCP_CONSOLE_URL"] = config_data["TEST_CLUSTERS"][test_cluster]["OCP_CONSOLE_URL"]
    data["ODH_DASHBOARD_URL"] = config_data["TEST_CLUSTERS"][test_cluster]["ODH_DASHBOARD_URL"]
    data["TEST_USER"]["AUTH_TYPE"] = config_data["TEST_CLUSTERS"][test_cluster]["TEST_USER"]["AUTH_TYPE"] 
    data["TEST_USER"]["USERNAME"] = config_data["TEST_CLUSTERS"][test_cluster]["TEST_USER"]["USERNAME"]
    data["TEST_USER"]["PASSWORD"] = config_data["TEST_CLUSTERS"][test_cluster]["TEST_USER"]["PASSWORD"]
    data["OCP_ADMIN_USER"]["AUTH_TYPE"] = config_data["TEST_CLUSTERS"][test_cluster]["OCP_ADMIN_USER"]["AUTH_TYPE"]
    data["OCP_ADMIN_USER"]["USERNAME"] = config_data["TEST_CLUSTERS"][test_cluster]["OCP_ADMIN_USER"]["USERNAME"]
    data["OCP_ADMIN_USER"]["PASSWORD"] = config_data["TEST_CLUSTERS"][test_cluster]["OCP_ADMIN_USER"]["PASSWORD"]

    with open(config_file, 'w') as yaml_file:
        yaml_file.write( yaml.dump(data, default_flow_style=False, sort_keys=False))

def main():
    """main function"""

    args = parse_args()

    if not args.skip_clone:
        ret = clone_config_repo(git_repo = args.git_repo,
                                git_branch = args.git_repo_branch,
                                repo_dir = args.repo_dir,
                                git_username = args.git_username,
                                git_password = args.git_password)
        if not ret:
            sys.exit(1)
    else:
        print ("Skipping cloning of congig gitlab repo")

    config_file = args.repo_dir + "/test-variables.yml"
    config_data = read_yaml(config_file)
    
    # Generate test config file
    generate_test_config_file(args.config_template, config_data, args.test_cluster)


if __name__ == '__main__':
    main()
