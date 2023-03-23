# Script to create Test plan and Test Run in polarion
# Prerequisite: Clone https://github.com/RedHatQE/pylero.git
# Install pylero.
# Doc: https://github.com/RedHatQE/pylero#readme

import argparse
import os
import ssl

ssl._create_default_https_context = ssl._create_unverified_context


def parse_args():
    """Parse CLI arguments"""
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Create Test Plan and Test run in Polarion",
    )
    parser.add_argument(
        "-s",
        "--releasetestplan",
        help="polarion release test plan name to create",
        action="store",
        dest="release_testplan_name",
        required=True,
    )
    parser.add_argument(
        "-t",
        "--testplanname",
        help="polarion test plan name to create",
        action="store",
        dest="testplan_name",
        required=True,
    )
    parser.add_argument(
        "-n",
        "--testrunname",
        help="polarion test run name to create",
        action="store",
        dest="testrun_name",
        required=True,
    )
    parser.add_argument(
        "-i",
        "--projectid",
        help="polarion project ID",
        action="store",
        dest="project_id",
        default="OpenDataHub",
    )
    parser.add_argument(
        "-u",
        "--username",
        help="polarion username",
        action="store",
        dest="username",
        required=True,
    )
    parser.add_argument(
        "-p",
        "--password",
        help="polarion password",
        action="store",
        dest="password",
        required=True,
    )
    parser.add_argument(
        "-c",
        "--certsfilepath",
        help="certificate file",
        action="store",
        dest="certs_filepath",
        default="/etc/pki/tls/RH-IT-Root-CA.crt",
    )
    parser.add_argument(
        "-l",
        "--polarionurl",
        help="polarion URL",
        action="store",
        dest="polarion_url",
        default="https://polarion.engineering.redhat.com/polarion",
    )
    parser.add_argument(
        "-r",
        "--polarionrepo",
        help="Polarion repo",
        action="store",
        dest="polarion_repo",
        default="https://polarion.engineering.redhat.com/repo",
    )
    return parser.parse_args()


def set_pylero_environment(env_config):
    """
    Sets environment variables for executing pylero
    """
    for env_key in env_config.keys():
        os.environ[env_key] = env_config[env_key]


def create_testplan(project_id, release_testplan, build_testplan):
    """
    Creates release test plan and build test plan
    """
    from pylero.plan import Plan

    release_testplan_id = release_testplan.replace(".", "_")
    build_testplan_id = build_testplan.replace(".", "_")
    rst_res = Plan.search("id:{}".format(release_testplan_id))
    if rst_res == []:
        Plan.create(release_testplan_id, release_testplan, project_id, None, "release")
    else:
        print("release test plan {} already exists".format(release_testplan))
    plan = Plan(project_id=project_id, plan_id=release_testplan_id)
    if plan.status == "open":
        plan.status = "inprogress"
        plan.update()

    btp_res = Plan.search("id:{}".format(build_testplan_id))
    if btp_res == []:
        res = Plan.create(
            build_testplan_id,
            build_testplan,
            project_id,
            release_testplan_id,
            "iteration",
        )
    else:
        res = True
        print("build test plan {} already exists".format(build_testplan))

    plan = Plan(project_id=project_id, plan_id=build_testplan_id)
    if plan.status == "open":
        plan.status = "inprogress"
        plan.update()

    return res


def create_testrun(project_id, testrun_name, build_testplan):
    """
    Creates test run and adds plannedin version to the
    tes run.
    """
    from pylero.test_run import TestRun

    build_testplan_id = build_testplan.replace(".", "_")
    try:
        TestRun(project_id=project_id, test_run_id=testrun_name)
        print("test run {} already exists".format(testrun_name))
    except:
        TestRun.create(project_id, testrun_name, "Build Acceptance type", testrun_name)
    tr = TestRun(project_id=project_id, test_run_id=testrun_name)
    tr.plannedin = build_testplan_id
    tr.update()


def main():
    """main function"""

    args = parse_args()
    env_config = {
        "POLARION_URL": args.polarion_url,
        "POLARION_REPO": args.polarion_repo,
        "POLARION_USERNAME": args.username,
        "POLARION_PASSWORD": args.password,
        "POLARION_PROJECT": args.project_id,
        "POLARION_CERT_PATH": args.certs_filepath,
    }

    # Set pylero environment variables
    set_pylero_environment(env_config)

    # Create test plan
    testplan = create_testplan(
        args.project_id, args.release_testplan_name, args.testplan_name
    )

    # Create test run
    if testplan:
        create_testrun(args.project_id, args.testrun_name, args.testplan_name)


if __name__ == "__main__":
    main()
