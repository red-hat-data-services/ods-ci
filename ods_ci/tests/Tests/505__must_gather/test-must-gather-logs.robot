*** Settings ***
Library   Process
Library   OperatingSystem
Resource         ../../Resources/Common.robot

*** Test Cases ***
Verify that the must-gather image provides RHODS logs and info
      [Tags]   Smoke
      ...      Tier1
      ...      ODS-505
      ...      Upgrade
      Get must-gather logs
      Verify logs for ${APPLICATIONS_NAMESPACE}
      IF  "${PRODUCT}" == "RHODS"
        Verify logs for ${OPERATOR_NAMESPACE}
        Run Keyword If RHODS Is Managed    Verify logs for ${MONITORING_NAMESPACE}
      END
      [Teardown]  Cleanup must-gather logs


*** Keywords ***
Get must-gather logs
      ${output}    Run process    ods_ci/tests/Tests/505__must_gather/get-must-gather-logs.sh     shell=yes
      Should Not Contain    ${output.stdout}    FAIL
      ${must-gather-dir}=  Run     ls -d must-gather.local.*
      ${namespaces-log-dir}=      Run     ls -d ${must-gather-dir}/quay-io-modh-must-gather-sha256-*/namespaces
      Set Suite Variable      ${must-gather-dir}
      Set Suite Variable      ${namespaces-log-dir}
      Directory Should Exist    ${must-gather-dir}
      Directory Should Not Be Empty   ${must-gather-dir}

Verify logs for ${namespace}
      Directory Should Exist    ${namespaces-log-dir}/${namespace}
      Directory Should Not Be Empty    ${namespaces-log-dir}/${namespace}
      Directory Should Not Be Empty    ${namespaces-log-dir}/${namespace}/pods
      ${log-files}=     Run   find ${namespaces-log-dir}/${namespace}/pods -type f -name "*.log"
      Should Not Be Equal    ${log-files}  ${EMPTY}

Cleanup must-gather logs
      Remove Directory   ${must-gather-dir}    recursive=True
