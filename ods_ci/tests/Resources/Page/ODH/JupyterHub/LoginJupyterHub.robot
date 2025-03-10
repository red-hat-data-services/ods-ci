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

Verify Service Account Authorization Not Required
   ${title} =  Get Title
   Should Not Start With  ${title}  Authorize service account

Verify Jupyter Access Level
   [Arguments]    ${expected_result}
   IF  '${expected_result}'=='none'
     User Is Not Allowed
   ELSE IF  '${expected_result}'=='admin'
     User Is JupyterHub Admin
   ELSE IF  '${expected_result}'=='user'
     User Is Not JupyterHub Admin
   END
