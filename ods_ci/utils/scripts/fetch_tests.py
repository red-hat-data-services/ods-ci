import argparse
import os

from robot.model import SuiteVisitor
from robot.running import TestSuiteBuilder
from util import execute_command


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
    if "http" in test_repo or "git@" in test_repo:
        print("Cloning repo ", test_repo)
        ret = execute_command(
            "git clone {test_repo} {output_dir}".format(test_repo=test_repo, output_dir=repo_local_path)
        )
        if "error" in ret.lower():
            # actual error gets printed during "execute_command"
            raise Exception("Failed to clone the given repository")
    elif not os.path.exists(test_repo):
        raise FileNotFoundError("local path {} was not found".format(test_repo))
    else:
        print("Using local repo ", test_repo)
        repo_local_path = test_repo
    return repo_local_path


def checkout_repository(ref):
    """
    Checkouts the repository at current directory to the given branch/commit ($ref)
    """
    ret = execute_command("git checkout {}".format(ref))
    if "error" in ret.lower():
        # actual error gets printed during "execute_command"
        raise Exception("Failed to checkout to the given branch/commit {}".format(ref))
    ret = execute_command("git checkout")
    print(ret)


def extract_test_cases_from_ref(repo_local_path, ref):
    """
    Navigate to the $test_repo directory, checkouts the target branch/commit ($ref) and extracts
    the test case titles leveraging RobotFramework TestSuiteBuilder() and TestCasesFinder() classes
    """
    curr_dir = os.getcwd()
    try:
        os.chdir(repo_local_path)
        checkout_repository(ref)
        builder = TestSuiteBuilder()
        testsuite = builder.build("ods_ci/tests/")
        finder = TestCasesFinder()
        tests = []
        testsuite.visit(finder)
        for test in finder.tests:
            # print (f'"{test.tags}"') # for future reference in order to fetch test tags
            tests.append(test.name)
    except Exception as err:
        print(err)
        os.chdir(curr_dir)
        raise
    os.chdir(curr_dir)
    return tests


def generate_rf_argument_file(tests, output_filepath):
    """
    Writes the RobotFramework argument file containing the test selection args
    to include the extracted new tests in previous stage of this script.
    """
    content = ""
    for testname in tests:
        content += "--test {}\n".format(testname.strip())
    try:
        with open(output_filepath, "w") as argfile:
            argfile.write(content)
    except Exception as err:
        print("Failed to generate argument file")
        print(err)


def extract_new_test_cases(test_repo, ref_1, ref_2, output_argument_file):
    """
    Wrapping function for all the new tests extraction stages.
    """
    repo_local_path = get_repository(test_repo)
    print("\n---| Extracting test cases from {} branch/commit |---".format(ref_1))
    tests_1 = extract_test_cases_from_ref(repo_local_path, ref_1)
    print("\nDone. Found {num} test cases".format(num=len(tests_1)))
    print("\n---| Extracting test cases from {} branch/commit |---".format(ref_2))
    tests_2 = extract_test_cases_from_ref(repo_local_path, ref_2)
    print("Done. Found {num} test cases".format(num=len(tests_2)))
    print("\n---| Computing differences |----")
    new_tests = list(set(tests_1) - set(tests_2))
    if len(new_tests) == 0:
        print("[WARN] Done. No new tests found in {ref_1} with respect to {ref_2}!".format(ref_1=ref_1, ref_2=ref_2))
        print("Skip argument file creation")
    else:
        print(
            "Done. Found {num} new tests in {ref_1} which were not present in {ref_2}".format(
                num=len(new_tests), ref_1=ref_1, ref_2=ref_2
            )
        )
        if output_argument_file is not None:
            print("\n---| Generating RobotFramework arguments file |----")
            generate_rf_argument_file(new_tests, output_argument_file)
            print("Done.")


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

    args = parser.parse_args()

    extract_new_test_cases(
        args.test_repo,
        args.ref_1,
        args.ref_2,
        args.output_argument_file,
    )
