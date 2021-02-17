*** Settings *** 
Library  SeleniumLibrary

*** Keywords ***
Can LoginTo Jupyterhub
   Switch Window  NEW
   Wait Until Page Contains  Sign in with OpenShift
   Click Element  xpath=//*[@id="login-main"]/div/a

Authorize jupyterhub service account
  Wait Until Page Contains  Authorize Access
  Checkbox Should Be Selected  user:info
  Click Element  approve
