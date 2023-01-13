*** Settings ***
Library  JupyterLibrary

Resource  ../../../RHOSi.resource

*** Keywords ***
Special User Testing Suite Setup
  Set Library Search Order  SeleniumLibrary
  RHOSi Setup

Login To Jupyterhub
   [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
   ${login_required} =  Is OpenShift Login Visible
   IF  ${login_required}  Login To Openshift  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}

Is Service Account Authorization Required
   ${title} =  Get Title
   ${result} =  Run Keyword And Return Status  Should Start With  ${title}  Authorize service account
   RETURN  ${result}

Authorize jupyterhub service account
  Wait Until Page Contains  Authorize Access
  Checkbox Should Be Selected  user:info
  Click Element  approve

Verify Jupyter Access Level
   [Arguments]    ${expected_result}
   IF  '${expected_result}'=='none'
     User Is Not Allowed
   ELSE IF  '${expected_result}'=='admin'
     User Is JupyterHub Admin
   ELSE IF  '${expected_result}'=='user'
     User Is Not JupyterHub Admin
   END
