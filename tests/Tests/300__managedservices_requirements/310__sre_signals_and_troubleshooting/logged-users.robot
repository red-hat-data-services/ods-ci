*** Settings ***
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Test Cases ***
Verify "logged in users" are displayed in the dashboard
  [Tags]  Sanity    ODS-354
  Launch JupyterHub From RHODS Dashboard Dropdown
  Click Link  id:logout
  Wait Until Page Contains  Successfully logged out.
  Click Link    id:login
  Wait Until Page Contains  Log in with  10
  Login To Jupyterhub  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
  Click Link    Admin
  Wait Until Page Contains Element  id:add-users
  Page Should Contain   ${OCP_ADMIN_USER.USERNAME}
  Page Should Contain   ${TEST_USER.USERNAME}
  Capture Page Screenshot
