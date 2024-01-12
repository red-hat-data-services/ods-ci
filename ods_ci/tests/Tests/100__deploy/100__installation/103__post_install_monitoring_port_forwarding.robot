*** Settings ***
Library          OperatingSystem
Library          Process
Resource         ../../../Resources/Page/ODH/Grafana/Grafana.resource
Resource         ../../../Resources/RHOSi.resource
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Suite Setup      Post Install Monitoring Port Forwarding Suite Setup
Suite Teardown   Post Install Monitoring Port Forwarding Suite Teardown


*** Variables ***
${PROC}                         none
${JUPYTERHB_SLI}                //*[contains(@aria-label,"Jupyterhub SLIs")]


*** Test Cases ***
Verify That MT-SRE Can Connect To Grafana Using Port Forwarding
    [Documentation]    Verifies that Grafana is accessible by MT-SRE when using oc port-forwarding
    [Tags]   Tier2
    ...      ODS-754
    Skip If RHODS Version Greater Or Equal Than    version=1.20.0
    ...    msg=Grafana was removed in RHODS 1.20
    ${grafana_port_forwarding_process} =  Enable Access To Grafana Using OpenShift Port Forwarding
    Wait Until HTTP Status Code Is  url=http://localhost:3001/api/health  retry=7x  expected_status_code=200
    Open Browser  http://localhost:3001  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Go To Grafana Dashboard Search
    [Teardown]  Terminate Process  ${grafana_port_forwarding_process}

Verify MT-SRE Can Connect To Prometheus Using Port-Forwarding
    [Documentation]    Verifies that MT-SRE can connect to Prometheus using Port-forwarding
    [Tags]    Tier2
    ...       ODS-752
    ...       AutomationBug
    ${prometheus_port_forwarding_process} =  Enable Access To Prometheus Using OpenShift Port Forwarding
    Wait Until HTTP Status Code Is  url=http://localhost:9090  retry=10x  expected_status_code=200
    Go To  http://localhost:9090
    Verify Access To Prometheus Using Browser
    [Teardown]  Terminate Process  ${prometheus_port_forwarding_process}

Verify MT-SRE Can Connect To Alert Manager Using Port-forwarding
    [Documentation]    Verifies that MT-SRE can connect to Alert Manager using Port Forwarding
    [Tags]    Tier2
    ...       ODS-753
    ...       AutomationBug
    ${alertmanager_port_forwarding_process} =  Enable Access To Alert Manager Using OpenShift Port Forwarding
    Wait Until HTTP Status Code Is  url=http://localhost:9093  retry=10x  expected_status_code=200
    Go To  http://localhost:9093
    Verify Access To Alert Manager Using Browser
    [Teardown]  Terminate Process  ${alertmanager_port_forwarding_process}


*** Keywords ***
Verify Access To Prometheus Using Browser
    [Documentation]  Verifies if we are able to access Prometheus without asking to login
    Wait Until Page Contains    text=Prometheus
    Wait Until Page Contains    text=Alerts
    Wait Until Page Contains    text=Graph

Verify Access To Alert Manager Using Browser
    [Documentation]  Verifies if we are able to access Alert Manager
    Wait Until Page Contains    text=Alertmanager
    Wait Until Page Contains    text=Silences
    Wait Until Page Contains    text=Status

Post Install Monitoring Port Forwarding Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Set Library Search Order  SeleniumLibrary

Post Install Monitoring Port Forwarding Suite Teardown
    [Documentation]    Suite Teardown
    Close Browser
    RHOSi Teardown
