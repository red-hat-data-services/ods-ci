*** Settings ***
Library  JupyterLibrary

*** Keywords ***
Login To Jupyterhub
   Wait Until Page Contains  Sign in with OpenShift
   Click Element  xpath=//*[@id="login-main"]/div/a
   ${login_required} =  Is OpenShift Login Visible
   Run Keyword If  ${login_required}  Login To Openshift

Is Service Account Authorization Required
   ${title} =  Get Title
   ${result} =  Run Keyword And Return Status  Should Start With  ${title}  Authorize service account
   [Return]  ${result}

Authorize jupyterhub service account
  Wait Until Page Contains  Authorize Access
  Checkbox Should Be Selected  user:info
  Click Element  approve
