*** Settings ***
Library  JupyterLibrary

*** Keywords ***
Special User Testing Suite Setup
  Set Library Search Order  SeleniumLibrary

Login To Jupyterhub
   [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
   ${login_required} =  Is OpenShift Login Visible
   Run Keyword If  ${login_required}  Login To Openshift  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}

Is Service Account Authorization Required
   ${title} =  Get Title
   ${result} =  Run Keyword And Return Status  Should Start With  ${title}  Authorize service account
   [Return]  ${result}

Authorize jupyterhub service account
  Wait Until Page Contains  Authorize Access
  Checkbox Should Be Selected  user:info
  Click Element  approve

Login Verify Access Level
   [Arguments]  ${username}  ${password}  ${auth}  ${expected_result}
   Login To Jupyterhub  ${username}  ${password}  ${auth}
   ${authorization_required} =  Is Service Account Authorization Required
   Run Keyword If  ${authorization_required}  Authorize jupyterhub service Account
   IF  '${expected_result}'=='none'
     User Is Not Allowed  
   ELSE IF  '${expected_result}'=='admin'
     User Is JupyterHub Admin
   ELSE IF  '${expected_result}'=='user'
     User Is Not JupyterHub Admin
   END   
   Capture Page Screenshot  verify-access-level-{$expected_result}.png
