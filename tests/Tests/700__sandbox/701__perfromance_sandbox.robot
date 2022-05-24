*** Settings ***
Documentation    Test Suite for Performance Sandbox Test cases
Library         OperatingSystem
Library         Collections
Library         Process
Library         String


*** Variables ***
${NAMESPACE}     openshift-kube-apiserver
${LABEL_SELECTOR}     app=openshift-kube-apiserver
${MEMORY_THRESHOLD}    102400
${PERF_CODE}    go run setup/main.go --users 50 --default 50  --custom 0 --username "user" --workloads redhat-ods-operator:rhods-operator --workloads redhat-ods-applications:rhods-dashboard --workloads redhat-ods-operator:cloud-resource-operator --workloads redhat-ods-monitoring:blackbox-exporter --workloads redhat-ods-monitoring:grafana --workloads redhat-ods-monitoring:prometheus <<< y   #robocop:disable


*** Test Cases ***
Verify RHODS Performance For Sandbox Onboarding Process
    [Documentation]    Performance test for RHODS operator onboard
    ...    to Sandbox environment
    [Tags]     ODS-1404
    ...        Sandbox
    ...        Performance-Test
    Run    git clone https://github.com/codeready-toolchain/toolchain-e2e.git
    Run Keyword And Continue On Failure    Run Performance Test On RHODS Operator
    Verify Sandbox Toolchain Data


*** Keywords ***
Capture Memory Utilization Of Openshift API Server POD
    [Documentation]  Capture and compare the realtime memory utilization
    ${memory_usage}     Run    kubectl top pod -n ${NAMESPACE} -l ${LABEL_SELECTOR} | awk '{if(NR>1)print $3}'
    ${memory}    Split String    ${memory_usage}   \n
    IF   len(${memory}) < ${3}
         FAIL     Check if all the pods are available
    ELSE
        @{memory_value}    Create List
        FOR    ${m_usage}    IN    @{memory}
               ${m_value}    Convert To Integer    ${m_usage}[:-2]
               Append To List    ${memory_value}    ${m_value}
        END
        Run Keyword And Continue On Failure   RHODS Performance Result Validation     ${memory_value}
    END

RHODS Performance Result Validation
    [Documentation]   Compare the current memory usage against expected threshold value
    [Arguments]     ${m_data}
    ${m_sum}    Evaluate    math.fsum(${m_data})                      math
    Run Keyword If     ${m_sum} > ${MEMORY_THRESHOLD}
    ...   FAIL      Kube-API Server Pod memory value is higher than expected

Run Performance Test On RHODS Operator
    [Documentation]    Perform toolchain-e2e sandbox performance test on rhods-operator component
    ${PROC} =  Start Process   cd ${EXECDIR}/toolchain-e2e/ && ${PERF_Code} >${EXECDIR}/log.txt  shell=True   alias=perf  #robocop:disable
    FOR    ${counter}    IN RANGE    21000
           ${result}   Wait For Process   perf     timeout=10 secs
           ${status}   Is Process Running    perf
           IF    ${status} == True
                Run Keyword And Warn On Failure    Should Be Equal  ${result}  ${NONE}
                Capture Memory Utilization Of Openshift API Server POD
                Sleep  30s
           ELSE
                Exit For Loop
           END
    END

Verify Sandbox Toolchain Data
    [Documentation]    Compare the memory utilization of kube api server pod
    ${result}  Run   cat ${EXECDIR}/log.txt | grep "invalid\\|failed"
    IF    "failed" in $result or "invalid" in $result
           FAIL    RHODS onboarding script is not executed successfully.Check log for more detail.
    ELSE
           ${k_data}  Run   cat ${EXECDIR}/log.txt | grep -i "openshift-kube-apiserver"
           ${k_mem_data}   Split String    ${k_data}      \n
           FOR    ${data}    IN    @{k_mem_data}
                  ${km_data}    Split String    ${data}       :
                  ${m_value}    Convert To Number    ${km_data[1]}[:-3]
                  Run Keyword And Continue On Failure    Run Keyword Unless     ${m_value} <= ${MEMORY_THRESHOLD}
                  ...   FAIL    Kube-API server value is higher than,
                  ...   expected in toolchain result=> ${km_data[0]} : ${m_value}
           END
    END
