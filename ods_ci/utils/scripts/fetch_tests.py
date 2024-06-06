#!/usr/bin/env python3

"""
Examples
Input:
poetry run ods_ci/utils/scripts/fetch_tests.py --test-repo git@github.com:red-hat-data-services/ods-ci.git --ref1 releases/2.8.0 --ref2-auto true --selector-attribute creatordate -A new-arg-file.txt
Output:
---| Computing differences |----
Done. Found 30 new tests in releases/2.8.0 which were not present in origin/releases/2.7.0

Input:
poetry run ods_ci/utils/scripts/fetch_tests.py --test-repo git@github.com:red-hat-data-services/ods-ci.git --ref1 master  --ref2-auto true --selector-attribute creatordate -A new-arg-file.txt
Output:
---| Computing differences |----
Done. Found 14 new tests in master which were not present in origin/releases/2.9.0

"""

import argparse
import os
import shutil

from robot.model import SuiteVisitor
from robot.running import TestSuiteBuilder

from ods_ci.utils.scripts.util import execute_command


class TestCasesFinder(SuiteVisitor):
    def __init__(self):
        self.tests = []

    def visit_test(self, test):
        self.tests.append(test)


def get_repository(test_repo):
    """
    If $test_repo is a remote repo, the function clones it in "ods-ci-temp" directory.
    If $test_repo is a local path, the function checks the path exists.
    """
    repo_local_path = "./ods_ci/ods-ci-temp"
    cloned = False
    if "http" in test_repo or "git@" in test_repo:
        print("Cloning repo ", test_repo)
        cloned = True
        execute_command(f"git clone {test_repo} {repo_local_path}")
    elif not os.path.exists(test_repo):
        raise FileNotFoundError(f"local path {test_repo} was not found")
    else:
        print("Using local repo ", test_repo)
        repo_local_path = test_repo
    return repo_local_path, cloned


def checkout_repository(ref):
    """
    Checkouts the repository at current directory to the given branch/commit ($ref)
    """
    execute_command(f"git checkout {ref}")
    execute_command("git checkout")


def get_branch(ref_to_exclude, selector_attribute):
    """
    List the remote branches and sort by selector_attribute date (ASC order), exclude $ref_to_exclude and get latest
    """
    ref_to_exclude_esc = ref_to_exclude.replace("/", r"\/")
    cmd = f"git branch -r --sort={selector_attribute} | grep releases/"
    if "master" not in ref_to_exclude and "main" not in ref_to_exclude:
        cmd += rf" | sed  's/.*{ref_to_exclude_esc}$/current/g' |  grep -zPo '[\S\s]+(?=current)'"
    ret = execute_command(cmd)
    branches = ret.split(" ")
    branch = branches[-1].split("\x00")[0].strip().replace("\n", "")
    if not branch or "fatal:" in branch:
        raise Exception("Failed to auto-selecting ref_2 branch.")
    print(f"Done. {branch} branch selected as ref_2")
    return branch


def extract_test_cases_from_ref(repo_local_path, ref, auto=False, selector_attribute=None, ref_to_exclude=None):
    """
    Navigate to the $test_repo directory, checkouts the target branch/commit ($ref) and extracts
    the test case titles leveraging RobotFramework TestSuiteBuilder() and TestCasesFinder() classes
    """
    curr_dir = os.getcwd()
    try:
        os.chdir(repo_local_path)
        if auto:
            print("\n---| Auto-selecting ref_2 branch")
            ref = get_branch(ref_to_exclude, selector_attribute)
        print(f"\n---| Extracting test cases from {ref} branch/commit |---")
        checkout_repository(ref)
        builder = TestSuiteBuilder()
        testsuite = builder.build("ods_ci/tests/")
        finder = TestCasesFinder()
        tests = []
        testsuite.visit(finder)
        for test in finder.tests:
            # print (f'"{test.tags}"') # for future reference in order to fetch test tags
            tests.append(test.name)
        print(f"\nDone. Found {len(tests)} test cases")
    except Exception as err:
        print(err)
        os.chdir(curr_dir)
        raise
    os.chdir(curr_dir)
    return tests, ref


def generate_rf_argument_file(tests, output_filepath):
    """
    Writes the RobotFramework argument file containing the test selection args
    to include the extracted new tests in previous stage of this script.
    """
    content = ""
    for testname in tests:
        content += f"--test {testname.strip()}\n"
    try:
        with open(output_filepath, "w") as argfile:
            argfile.write(content)
    except Exception as err:
        print("Failed to generate argument file")
        print(err)


def extract_new_test_cases(test_repo, ref_1, ref_2, ref_2_auto, selector_attribute, output_argument_file):
    """
    Wrapping function for all the new tests extraction stages.
    """
    repo_local_path, cloned = get_repository(test_repo)
    tests_1, _ = extract_test_cases_from_ref(repo_local_path, ref_1)
    tests_2, ref_2 = extract_test_cases_from_ref(repo_local_path, ref_2, ref_2_auto, selector_attribute, ref_1)
    print("\n---| Computing differences |----")
    new_tests = list(set(tests_1) - set(tests_2))
    if len(new_tests) == 0:
        print(f"[WARN] Done. No new tests found in {ref_1} with respect to {ref_2}!")
        print("Skip argument file creation")
    else:
        print(f"Done. Found {len(new_tests)} new tests in {ref_1} which were not present in {ref_2}")
        if output_argument_file is not None:
            print("\n---| Generating RobotFramework arguments file |----")
            generate_rf_argument_file(new_tests, output_argument_file)
            print("Done.")
    if cloned:
        print(f"\n---| Deleting cloned repo in {repo_local_path} |----")
        shutil.rmtree(repo_local_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        usage=argparse.SUPPRESS,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Script to fetch newly added test cases",
    )

    parser.add_argument(
        "-A",
        "--output-argument-file",
        help="generate argument file for RobotFramework to include test cases. It expects to receive a file path",
        action="store",
        dest="output_argument_file",
        default=None,
    )
    parser.add_argument(
        "--test-repo",
        help="ODS-CI repository. It accepts either local path or URL",
        action="store",
        dest="test_repo",
        default="https://github.com/red-hat-data-services/ods-ci",
    )
    parser.add_argument(
        "--ref1",
        help="first branch or commit to use for comparison (e.g., older one)",
        action="store",
        dest="ref_1",
        default="master",
    )
    parser.add_argument(
        "--ref2",
        help="second branch or commit to use for comparison (e.g., newer one)",
        action="store",
        dest="ref_2",
        default="releases/2.8.0",
    )
    parser.add_argument(
        "--ref2-auto",
        help="Auto select the second branch to use for comparison (e.g., latest updated branch)",
        action="store",
        dest="ref_2_auto",
        default=False,
    )
    parser.add_argument(
        "--selector-attribute",
        help="Select the git attribute to use when --ref2-auto is enabled",
        action="store",
        dest="selector_attribute",
        choices=["creatordate", "committerdate", "authordate", "taggerdate", "version:refname"],
        default="version:refname",
    )

    args = parser.parse_args()

    extract_new_test_cases(
        args.test_repo,
        args.ref_1,
        args.ref_2,
        args.ref_2_auto,
        args.selector_attribute,
        args.output_argument_file,
    )
