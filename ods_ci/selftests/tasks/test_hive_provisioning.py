"""Exercise the production Hive readiness keywords without a live cluster."""

import logging
import re
from pathlib import Path
from types import SimpleNamespace

import pytest
from robot.api import TestSuite as RobotTestSuite
from robot.libraries.BuiltIn import BuiltIn
from robot.libraries.Process import Process

PROVISION_RESOURCE = Path(__file__).resolve().parents[2] / "tasks/Resources/Provisioning/Hive/provision.robot"


def run_readiness_check(
    monkeypatch,
    tmp_path,
    *,
    provider="AWS",
    use_pool=True,
    provision_rc=0,
    running_rc=0,
    missing_url_reads=0,
    installer_fails=False,
):
    """Run actual Robot keywords with simulated Hive responses and fast retries."""
    source = PROVISION_RESOURCE.read_text()
    # Avoid Common.robot's browser/cloud imports while executing the unchanged
    # production keyword bodies. Older revisions have no console-URL helper.
    definitions = []
    for name in ("Cluster Web Console URL Should Be Set", "Wait For Cluster To Be Ready"):
        match = re.search(rf"^{name}\n.*?(?=^\S|\Z)", source, re.MULTILINE | re.DOTALL)
        if match:
            definitions.append(match.group())

    state = {"running": False, "url_reads": 0, "early_url_reads": 0}

    def run_process(_self, command, **_kwargs):
        rc, stdout = 0, "condition met\n"
        if "condition=ProvisionFailed=False" in command:
            rc = provision_rc
        elif "condition=ClusterRunning=True" in command or "condition=Ready=True" in command:
            rc = running_rc
            state["running"] = rc == 0
        elif "webConsoleURL" in command:
            state["url_reads"] += 1
            if not state["running"]:
                state["early_url_reads"] += 1
            rc = int(not state["running"] or state["url_reads"] <= missing_url_reads)
            stdout = "null\n" if rc else "https://console.example.test\n"
        elif ".status.conditions" not in command:
            stdout = "{}"
        return SimpleNamespace(rc=rc, stdout=stdout, stderr="simulated Hive error" if rc else "")

    original_retry = BuiltIn.wait_until_keyword_succeeds

    def fast_retry(self, _retry, _interval, name, *args):
        return original_retry(self, "3x", "0s", name, *args)

    monkeypatch.setattr(Process, "run_process", run_process)
    monkeypatch.setattr(BuiltIn, "wait_until_keyword_succeeds", fast_retry)
    suite_source = [
        """*** Settings ***
Library    OperatingSystem
Library    Process

*** Variables ***
${cluster_name}    readiness-test
${pool_name}    readiness-test-pool
${hive_namespace}    hive-test
${claim_name}    readiness-test-claim
""",
        f"${{artifacts_dir}}    {tmp_path.as_posix()}",
        f"${{provider_type}}    {provider}",
        "${use_cluster_pool}    " + ("${TRUE}" if use_pool else "${FALSE}"),
        "\n*** Tasks ***\nCheck Readiness\n    Wait For Cluster To Be Ready\n\n*** Keywords ***",
        "\n".join(definitions),
        "Get Cluster Pool Namespace\n    [Arguments]    ${pool}\n    RETURN    readiness-test-pool-abcde\n",
        "Watch Hive Install Log\n    [Arguments]    ${pool}    ${namespace}",
        "    Fail    Installer failed\n" if installer_fails else "    No Operation\n",
    ]
    suite = RobotTestSuite.from_string("\n".join(suite_source))
    # Robot changes the root logging level; preserve pytest's logging setup.
    root_logger = logging.getLogger()
    original_level = root_logger.level
    try:
        result = suite.run(outputdir=str(tmp_path), log=None, report=None, console="none")
    finally:
        root_logger.setLevel(original_level)
    return result.suite.tests[0], state


@pytest.mark.parametrize("provider,use_pool", [("AWS", True), ("GCP", True), ("IBM", False), ("OSP", True)])
def test_waits_for_running_then_retries_delayed_console_url(monkeypatch, tmp_path, provider, use_pool):
    result, state = run_readiness_check(
        monkeypatch, tmp_path, provider=provider, use_pool=use_pool, missing_url_reads=1
    )
    assert result.status == "PASS", result.message
    assert state["early_url_reads"] == 0
    assert state["url_reads"] >= 2


@pytest.mark.parametrize("failure", ["provision", "running", "console", "installer"])
def test_real_failures_still_fail_readiness(monkeypatch, tmp_path, failure):
    result, _ = run_readiness_check(
        monkeypatch,
        tmp_path,
        provision_rc=int(failure == "provision"),
        running_rc=int(failure == "running"),
        missing_url_reads=100 if failure == "console" else 0,
        installer_fails=failure == "installer",
    )
    assert result.status == "FAIL"
    if failure == "installer":
        assert "Installer failed" in result.message
    else:
        assert "provisioning failed" in result.message
