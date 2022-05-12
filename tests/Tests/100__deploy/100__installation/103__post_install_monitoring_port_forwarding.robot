*** Settings ***
Library          OperatingSystem
Library          Process
Resource         ../../../Resources/Page/ODH/Grafana/Grafana.resource
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Suite Setup      Set Library Search Order  SeleniumLibrary
Suite Teardown   Close Browser


*** Variables ***
${PROC}                         none
${JUPYTERHB_SLI}                //*[contains(@aria-label,"Jupyterhub SLIs")]


*** Test Cases ***
Verify That MT-SRE Can Connect To Grafana Using Port Forwarding
    [Documentation]    Verifies that Grafana is accessible by MT-SRE when using oc port-forwarding
    [Tags]   Tier2
    ...      ODS-754
    ${grafana_port_forwarding_process} =  Enable Access To Grafana Using OpenShift Port Forwarding
    Wait Until HTTP Status Code Is  url=http://localhost:3001/api/health  retry=7x  expected_status_code=200
    Open Browser  http://localhost:3001  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Go To Grafana Dashboard Search
    Verify If Jupyterhub Sli Is Present
    [Teardown]  Kill Process  ${grafana_port_forwarding_process}

Verify MT-SRE Can Connect To Prometheus Using Port-Forwarding
    [Documentation]    Verifies that MT-SRE can connect to Prometheus using Port-forwarding
    [Tags]    Tier2
    ...       ODS-752
    ${prometheus_port_forwarding_process} =  Enable Access To Prometheus Using OpenShift Port Forwarding
    Wait Until HTTP Status Code Is  url=http://localhost:9090  retry=10x  expected_status_code=200
    Go To  http://localhost:9090
    Verify Access To Prometheus Using Browser
    [Teardown]  Kill Process  ${prometheus_port_forwarding_process}

Verify MT-SRE Can Connect To Alert Manager Using Port-forwarding
    [Documentation]    Verifies that MT-SRE can connect to Alert Manager using Port Forwarding
    [Tags]    Tier2
    ...       ODS-753
    ${alertmanager_port_forwarding_process} =  Enable Access To Alert Manager Using OpenShift Port Forwarding
    Wait Until HTTP Status Code Is  url=http://localhost:9093  retry=10x  expected_status_code=200
    Go To  http://localhost:9093
    Verify Access To Alert Manager Using Browser
    [Teardown]  Kill Process  ${alertmanager_port_forwarding_process}


*** Keywords ***
Verify If Jupyterhub Sli Is Present
    [Documentation]    Verifies Jupyterhub SLI element is present
    Wait Until Element Is Visible    ${JUPYTERHB_SLI}   error="Jupyterhub SLIs Not Found"

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
