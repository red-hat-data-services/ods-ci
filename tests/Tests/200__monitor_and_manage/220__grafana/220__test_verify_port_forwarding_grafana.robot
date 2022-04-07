*** Settings ***
Documentation   Verify that MT-SRE can connect to Grafana using port-forwarding
...
...             = Variables =
...             | PROC             | Required |        Is used  to get the process id|

Library        OperatingSystem
Library        Process
Library        SeleniumLibrary


*** Variables ***
${PROC}     none


*** Test Cases ***
Verify that MT-SRE can connect to Grafana using port-forwarding
    [Documentation]  Verify Grafana webiste is using port-forwarding
    [Tags]   Tier2
     ...     ODS-754

    # Port Forwarding
    ${PROC}    Start Process    oc -n redhat-ods-monitoring port-forward $(oc get pods -n redhat-ods-monitoring | grep grafana | awk '{print $1}' | head -n 1) 3001  shell=True  # robocop: disable
    # It takes aroung 7 sec for the website to come up
    Sleep  7s
    ${response} =   Run   curl -I "http://localhost:3001"   # robocop: disable
    Run Keyword If    "HTTP/1.1 200 OK" not in $response    Fail
    ...       ELSE     Log To Console    SRE can connect to Grafana using prot-forwarding"

    Open Browser  http://localhost:3001  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Wait Until Element Is Visible     //div[@class="sidemenu-item dropdown"]
    Run Keywords
    ...    Click Element    //div[@class="sidemenu-item dropdown"]
    ...    AND
    ...    Click Element    //*[text()="Search"]

    Wait Until Element Is Visible    //*[contains(@aria-label,"Jupyterhub SLIs")]

    ${data}     Get WebElements    //*[contains(@aria-label,"Jupyterhub SLIs")]

    Close Browser
    [Teardown]   Terminating Process Tierdown


*** Keywords ***
Terminating Process Tierdown
    [Documentation]   Deletes the process running in background
    Terminate Process   ${PROC}
