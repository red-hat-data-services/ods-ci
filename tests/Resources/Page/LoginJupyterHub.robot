*** Settings ***
Library  SeleniumLibrary

*** Keywords ***
Login To Jupyterhub
   #TODO: We should assume that the CURRENT browser window is where we are logging in
   Switch Window  JupyterHub
   Wait Until Page Contains  Sign in with OpenShift
   Click Element  xpath=//*[@id="login-main"]/div/a
   Wait Until Page Contains  Log in to your account
   Input Text  id=inputUsername  ${TEST_USER_NAME}
   Input Text  id=inputPassword  ${TEST_USER_PW}
   Click Button  Log in

Is Service Account Authorization Required
   ${title} =  Get Title
   ${result} =  Run Keyword And Return Status  Should Start With  ${title}  Authorize service account
   [Return]  ${result}

Authorize jupyterhub service account
  Wait Until Page Contains  Authorize Access
  Checkbox Should Be Selected  user:info
  Click Element  approve
