*** Settings ***
Documentation   Verify that MT-SRE can connect to Grafana-dashboard using port-forwarding
...
...             = Variables =
...             | PROC             | Required |        To store process id|

Library          OperatingSystem
Library          Process
Resource         ../../../Resources/Page/OCPDashboard/Monitoring/Grafana.robot
Resource         ../../../Resources/ODS.robot
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

    # Enable Port Forwarding
    ${PROC} =  Enable Access To Grafana Using OpenShift Port Forwarding
    # Check if Grafna is UP and running
    ${response} =   Wait Until Grafana Page Is UP  RETRIES=7
    Should Contain   ${response}     "database": "ok",
    # Open Browser
    Open Browser  http://localhost:3001  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Go To Grafana Dashbord Search
    Verify If Jupyterhub Sli Is Present
    [Teardown]  Disable Access To Grafana Using OpenShift Port Forwarding  ${PROC}


*** Keywords ***
Verify If Jupyterhub Sli Is Present
    [Documentation]    Verifies Jupyterhub SLI element is present
    Wait Until Element Is Visible    ${JUPYTERHB_SLI}   error="Jupyterhub SLIs Not Found"
