*** Settings ***
Resource    ../../Resources/ODS.robot
Resource    ../../Resources/Page/ODH/JupyterHub/LaunchJupyterHub.robot
Resource    ../../Resources/Page/ODH/JupyterHub/LoginJupyterHub.robot
Resource    ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource    ../../Resources/Page/OCPDashboard/OCPMenu.robot
Library     SeleniumLibrary

*** Test Cases ***
Verify Telemetry Data Is Accessible
  [Tags]  Sanity
  Set Library Search Order  SeleniumLibrary
  Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  LoginPage.Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
  OCPMenu.Switch To Administrator Perspective
  Wait Until Page Contains    Status  timeout=20
  Click Element  xpath://*[@id="content"]/div[2]/div/div/div/button
  Click Element  xpath://*[@id="redhat-ods-applications-link"]
  Create Secret  rhods-segment-key  foo  bar
  Launch Jupyterhub via Routes
  Login To Jupyterhub  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
  Access Spawner API  api/instance
  Wait Until Page Contains  "cluster_id"  timeout=2
  Page Should Contain  "foo": "bar"