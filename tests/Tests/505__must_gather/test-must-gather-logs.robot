*** Settings ***
Library   Process
Library   OperatingSystem

*** Test Cases ***
Get must-gather logs
      ${output}    Run process    tests/Tests/505__must_gather/get-must-gather-logs.sh     shell=yes
      Should Not Contain    ${output.stdout}    FAIL
      ${must-gather-dir}=  Run     ls -d must-gather.local.*
      ${namespaces-log-dir}=      Run     ls -d ${must-gather-dir}/quay-io-modh-must-gather-sha256-*/namespaces
      Set Suite Variable      ${must-gather-dir}
      Set Suite Variable      ${namespaces-log-dir}

      Directory Should Exist    ${must-gather-dir}
      Directory Should Not Be Empty   ${must-gather-dir}

Verify logs for redhat-ods-applications
      Directory Should Exist    ${namespaces-log-dir}/redhat-ods-applications
      Directory Should Not Be Empty    ${namespaces-log-dir}/redhat-ods-applications
      Directory Should Not Be Empty    ${namespaces-log-dir}/redhat-ods-applications/pods
      ${log-files}=     Run   find ${namespaces-log-dir}/redhat-ods-applications/pods -type f -name "*.log"
      Should Not Be Equal    ${log-files}  ${EMPTY}

Verify logs for redhat-ods-operator
      Directory Should Exist    ${namespaces-log-dir}/redhat-ods-operator
      Directory Should Not Be Empty   ${namespaces-log-dir}/redhat-ods-operator
      Directory Should Not Be Empty   ${namespaces-log-dir}/redhat-ods-operator/pods
      ${log-files}=     Run   find ${namespaces-log-dir}/redhat-ods-operator/pods -type f -name "*.log"
      Should Not Be Equal    ${log-files}  ${EMPTY}

Verify logs for redhat-ods-monitoring
      Directory Should Exist    ${namespaces-log-dir}
      Directory Should Not Be Empty   ${namespaces-log-dir}/redhat-ods-monitoring
      Directory Should Not Be Empty   ${namespaces-log-dir}/redhat-ods-monitoring/pods
      ${log-files}=     Run   find ${namespaces-log-dir}/redhat-ods-monitoring/pods -type f -name "*.log"
      Should Not Be Equal    ${log-files}  ${EMPTY}

Cleanup must-gather logs
      Remove Directory   ${must-gather-dir}    recursive=True
