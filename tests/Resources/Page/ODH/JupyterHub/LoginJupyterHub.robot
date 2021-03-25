*** Settings ***
Library  JupyterLibrary

*** Keywords ***
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
