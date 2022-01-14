# Script to update ods-ci test results in polarion

import os
import argparse
import re
import shutil
import yaml
import sys
import uuid
import subprocess
dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path+"/../")

from util import clone_config_repo, read_yaml

POLARION_URL = "https://polarion.engineering.redhat.com/polarion/import/xunit"
PYLERO_REPO = "https://github.com/RedHatQE/pylero.git"
SCRIPT_DIR = dir_path + "/"

def parse_args():
    """Parse CLI arguments"""
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='Script to update ods-ci test results in polarion'
        )

    parser.add_argument("-r", "--robotResultFile",
                        help="robot tests results file",
                        action="store", dest="robot_result_file",
                        required=True)
    parser.add_argument("-x", "--xunitXmlFile",
                        help="xunit xml robot test result file",
                        action="store", dest="xunit_xml_file",
                        required=True)
    parser.add_argument("-m", "--releasePlanName",
                        help="release plan name. Usually, product release name",
                        action="store", dest="release_plan_name",
                        required=True)
    parser.add_argument("-n", "--testPlanName",
                        help="test plan name. This will created as child test plan for "
                             "release plan. Usually, it will be build number",
                        action="store", dest="test_plan_name",
                        required=True)
    parser.add_argument("-t", "--TestrunTitle",
                        help="polarion testrun title",
                        action="store", dest="testrun_title",
                        required=True)
    parser.add_argument("-u", "--polarionuser",
                        help="polarion username",
                        action="store", dest="polarion_username",
                        required=True)
    parser.add_argument("-p", "--polarionpassword",
                        help="polarion password",
                        action="store", dest="polarion_password",
                        required=True)

    return parser.parse_args()


def generate_polarion_config(config_template, config_data, testrun_title):
    """
    Generates test config file dynamically by substituting the values in a template file.
    """
    shutil.copy(config_template, '.')
    config_file = os.path.basename(config_template)
    with open(config_file, 'r') as fh:
        data = yaml.safe_load(fh)

    data["testrun_info"]["polarion-testrun-title"] = testrun_title
    data["testrun_info"]["polarion-testrun-id"] = testrun_title

    with open(config_file, 'w') as yaml_file:
        yaml_file.write( yaml.dump(data, default_flow_style=False, sort_keys=False))


def main():
    """main function"""

    args = parse_args()

    # Clone pylero repo
    ret = clone_config_repo(git_repo = PYLERO_REPO,
                            git_branch = "main",
                            repo_dir = "pylero")
    if not ret:
        sys.exit(1)

    polarion_config_file = "polarion_config.yml"
    filename = SCRIPT_DIR + polarion_config_file
    config_data = read_yaml(filename)
    generate_polarion_config(filename, config_data, args.testrun_title)

    # Installs pylero
    cmd = "pip3 install pylero/."
    ret = subprocess.call(cmd, shell=True)
    if ret:
        print("Failed to install pylero")
        return False

    addPropertyScriptName = SCRIPT_DIR + "xunit_add_properties.py"
    testRunCreateScriptName = SCRIPT_DIR + "createPolarionTestRun.py"

    # Add property tag to the test report xml file"
    output_report_file = "polarion-report-" + str(uuid.uuid1()) + ".xml"
    cmd = ("python3 {} -c {} -i {} -x {} -o {}".format(addPropertyScriptName,
            polarion_config_file, args.robot_result_file,
            args.xunit_xml_file, output_report_file))

    ret = subprocess.call(cmd, shell=True)
    if ret:
        print("Failed to add property to the test report xml file")
        return False

    # Create test plan and test runs in polarion
    cmd = ("python3 {} -s {} -t {} -n {} -u {} -p {}".format(testRunCreateScriptName,
           args.release_plan_name, args.test_plan_name, args.testrun_title,
           args.polarion_username, args.polarion_password))

    ret = subprocess.call(cmd, shell=True)
    if ret:
        print("Failed to create test plan and test runs in polarion")
        return False

    # Update test results in polarion
    cmd = ("curl -k -X POST -u {}:{} -F file=@{} {}".format(args.polarion_username,
            args.polarion_password, output_report_file, POLARION_URL))
    ret = subprocess.call(cmd, shell=True)
    if ret:
        print("Failed to update test results in polarion")
        return False


if __name__ == '__main__':
    main()
