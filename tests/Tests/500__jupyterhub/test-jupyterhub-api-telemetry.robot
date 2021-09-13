*** Settings ***
Resource    ../../Resources/ODS.robot
Resource    ../../Resources/Common.robot
Resource    ../../Resources/Page/ODH/JupyterHub/LaunchJupyterHub.robot
Resource    ../../Resources/Page/ODH/JupyterHub/LoginJupyterHub.robot
Library     SeleniumLibrary
Test Setup  API Setup

*** Test Cases ***
Verify Telemetry Data Is Accessible
  Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  LoginPage.Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
  OCPMenu.Switch To Administrator Perspective
  Wait Until Page Contains    Status  timeout=20
  Menu.Navigate To Page   Workloads  Secrets
  Create Secret  foo  bar
  Access Spawner API  api/instance
  Page Should Contain  "cluster_id"
  Page Should Contain  "foo": "bar"
  

*** Keywords ***
Create Secret
  [Arguments]  ${key}  ${value}
  Wait Until Page Contains  Create  timeout=30
  Click Button  Create
  Click Element  xpath://*[@id="generic-link"]
  Wait Until Page Contains  Secret name  timeout=30
  Input Text  xpath://*[@id="secret-name"]  rhods-segment-key
  Input Text  xpath://*[@id="0-key"]  ${Key}
  Input Text  xpath://*[@id="content-scrollable"]/div/form/div[1]/div/div[2]/div/div/div/div/textarea  ${Value}
  Click Button  Create

Access Spawner API
  [Arguments]  ${Target}
  Launch Jupyterhub via Routes
  Login To Jupyterhub  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
  Click Element  xpath://*[@id="thenavbar"]/ul[1]/li[4]/a
  Click Element  xpath://*[@id="thenavbar"]/ul[1]/li[4]/ul/li/a
  ${url}=   Get Location
  ${url}=   Catenate  SEPARATOR=  ${url}  ${Target}
  Go To  ${url}

API Setup
  Set Library Search Order  SeleniumLibrary

