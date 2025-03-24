# robocop: off=wrong-case-in-keyword-name,unnecessary-string-conversion,hyphen-in-variable-name
*** Settings ***
Documentation    Tests the must-gather image for ODH/RHOAI
Library          Process
Library          OperatingSystem
Resource         ../../Common.robot


*** Keywords ***
Get Must-Gather Logs
    [Documentation]    Runs the must-gather image and obtains the ODH/RHOAI logs
    ${output}=    Run process    tests/Resources/CLI/MustGather/get-must-gather-logs.sh     shell=yes
    Should Be Equal As Integers	  ${output.rc}	 0
    Should Not Contain    ${output.stdout}    FAIL
    ${must_gather_dir}=  Run     ls -d must-gather.local.*
    ${namespaces_log_dir}=      Run     ls -d ${must_gather_dir}/quay-io-modh-must-gather-sha256-*/namespaces
    Set Suite Variable      ${must_gather_dir}
    Set Suite Variable      ${namespaces_log_dir}
    Directory Should Exist    ${must_gather_dir}
    Directory Should Not Be Empty   ${must_gather_dir}

Verify Logs For ${namespace}
    [Documentation]    Verifies the must-gather logs related to a namespace
    Directory Should Exist    ${namespaces_log_dir}/${namespace}
    Directory Should Not Be Empty    ${namespaces_log_dir}/${namespace}
    Directory Should Not Be Empty    ${namespaces_log_dir}/${namespace}/pods
    ${log_files}=     Run   find ${namespaces_log_dir}/${namespace}/pods -type f -name "*.log"
    Should Not Be Equal    ${log_files}  ${EMPTY}

Cleanup Must-Gather Logs
    [Documentation]    Deletes the folder with the must-gather logs
    Run Keyword If      "${must_gather_dir}" != "${EMPTY}"      Remove Directory   ${must_gather_dir}    recursive=True
