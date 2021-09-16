*** Settings ***
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Suite Teardown   End Web Test

*** Test Cases ***
Open RHODS Dashboard and Login as a User
  [Tags]  Sanity    ODS-354
  Set Library Search Order  JupyterLibrary  SeleniumLibrary
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']

Logout and Log Back in as an Admin
  [Tags]  Sanity    ODS-354
  Click Link  id=logout
  Wait Until Page Contains  Successfully logged out.
  Click Link    id=login
  Wait Until Page Contains  Log in with  10
  Login To Jupyterhub  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']

Go to Admin View of All Users
  [Tags]  Sanity    ODS-354
  Click Link    Admin
  Wait Until Page Contains Element  id=add-users

Verify User and Admin Are There
  [Tags]  Sanity    ODS-354
  Page Should Contain   ${OCP_ADMIN_USER.USERNAME}
  Page Should Contain   ${TEST_USER.USERNAME}
  Capture Page Screenshot