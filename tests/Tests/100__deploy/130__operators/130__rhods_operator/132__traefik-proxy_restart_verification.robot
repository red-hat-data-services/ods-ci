*** Settings ***
Documentation       132 - RHODS_TRAEFIK_PROXY_CONTAINER_RESTART_VERIFICATION
...                 Verify that rhods traefik-proxy container
...                 restart verification
...
...                 = Variables =
...                 | Namespace         | Required |    RHODS Namespace/Project for RHODS operator POD |
...                 | LABEL_SELECTOR    | Required |    Label selector for traefik proxy|

Resource            ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource


*** Variables ***
${NAMESPACE}            redhat-ods-applications
${LABEL_SELECTOR}       name=traefik-proxy


*** Test Cases ***
Verify Traefik Proxy Containers Restart
    [Documentation]    Verify traefik proxy
    ...    container restart
    [Tags]    Sanity
    ...       ODS-1163    KnownIssues
    ${p_names}    Get POD Names    ${NAMESPACE}    ${LABEL_SELECTOR}
    Verify Restart Container Verification    ${p_names}


*** Keywords ***
Verify Restart Container Verification
    [Documentation]    Get and verify container restart
    ...    Counts for pods
    [Arguments]    ${names}
    # Todo:We should move this keyword to common folder in future
    ${r_data}    Get Container Restart Counts    ${names}    ${NAMESPACE}
    ${len}    Get Length    ${r_data}
    FOR    ${key}    ${value}    IN    &{r_data}
        IF    len(${value}) > ${0}
            Run Keyword And Continue On Failure    FAIL
            ...    Container restart "${value}" found for '${key}' pod.
        ELSE
            Pass Execution    No container with restart count found!
        END
    END
