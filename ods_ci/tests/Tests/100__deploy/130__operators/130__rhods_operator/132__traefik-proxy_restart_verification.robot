*** Settings ***
Documentation       132 - RHODS_TRAEFIK_PROXY_CONTAINER_RESTART_VERIFICATION
...                 Verify that rhods traefik-proxy container
...                 restart verification
...
...                 = Variables =
...                 | Namespace         | Required |    RHODS Namespace/Project for RHODS operator POD |
...                 | LABEL_SELECTOR    | Required |    Label selector for traefik proxy|

Resource            ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../../Resources/RHOSi.resource
Resource            ../../../../Resources/Common.robot

Suite Setup         RHOSi Setup
Suite Teardown         RHOSi Teardown


*** Variables ***
${NAMESPACE}            ${APPLICATIONS_NAMESPACE}
${LABEL_SELECTOR}       name=traefik-proxy


*** Test Cases ***
Verify Traefik Proxy Containers Have Zero Restarts
    [Documentation]    Verify traefik proxy
    ...    container restart
    [Tags]    Sanity    Tier1
    ...       ODS-1163    ProductBug
    Skip If RHODS Version Greater Or Equal Than    version=1.16.0
    ...    msg=Traefik proxy is removed after KFNBC migration
    ${pod_names}    Get POD Names    ${NAMESPACE}    ${LABEL_SELECTOR}
    Verify Containers Have Zero Restarts    ${pod_names}    ${NAMESPACE}
