# robocop: off=wrong-case-in-keyword-name,unnecessary-string-conversion,hyphen-in-variable-name
*** Settings ***
Documentation    Tests the must-gather image for ODH/RHOAI
Library          Process
Library          OperatingSystem
Resource         ../../../Resources/Common.robot


*** Test Cases ***
Verify that the must-gather image provides RHODS logs and info
    [Documentation]   Tests the must-gather image for ODH/RHOAI
    [Tags]   Smoke
    ...      Tier1
    ...      ODS-505
    ...      Operator
    ...      Upgrade
    Get must-gather Logs
    Verify logs for ${APPLICATIONS_NAMESPACE}
    IF  "${PRODUCT}" == "RHODS"
        Verify Logs For ${OPERATOR_NAMESPACE}
        Run Keyword If RHODS Is Managed    Verify logs for ${MONITORING_NAMESPACE}
    END
    [Teardown]  Cleanup must-gather Logs


*** Keywords ***
Get must-gather Logs
    [Documentation]    Runs the must-gather image and obtains the ODH/RHOAI logs
    ${output}=    Run process    tests/Tests/0100__platform/0103__must_gather/get-must-gather-logs.sh     shell=yes
    Should Not Contain    ${output.stdout}    FAIL
    ${must-gather-dir}=  Run     ls -d must-gather.local.*
    ${namespaces-log-dir}=      Run     ls -d ${must-gather-dir}/quay-io-modh-must-gather-sha256-*/namespaces
    Set Suite Variable      ${must-gather-dir}
    Set Suite Variable      ${namespaces-log-dir}
    Directory Should Exist    ${must-gather-dir}
    Directory Should Not Be Empty   ${must-gather-dir}

Verify Logs For ${namespace}
    [Documentation]    Verifies the must-gather logs related to a namespace
    Directory Should Exist    ${namespaces-log-dir}/${namespace}
    Directory Should Not Be Empty    ${namespaces-log-dir}/${namespace}
    Directory Should Not Be Empty    ${namespaces-log-dir}/${namespace}/pods
    ${log-files}=     Run   find ${namespaces-log-dir}/${namespace}/pods -type f -name "*.log"
    Should Not Be Equal    ${log-files}  ${EMPTY}

Cleanup must-gather Logs
    [Documentation]    Deletes the folder with the must-gather logs
    Remove Directory   ${must-gather-dir}    recursive=True
