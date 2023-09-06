*** Settings ***
Documentation  Set of Keywords for OCP login
Library       OperatingSystem
Resource      ../LoginPage.robot

*** Keywords ***
Login To OCP
    Login To Openshift
    ...  ${OCP_ADMIN_USER.USERNAME}
    ...  ${OCP_ADMIN_USER.PASSWORD}
    ...  ${OCP_ADMIN_USER.AUTH_TYPE}

Login To OCP Using API
  [Documentation]   Login to openshitf using username and password
  [Arguments]    ${username}      ${password}
  ${rc}    ${out}=    Run And Return Rc And Output    oc login $(oc whoami --show-server) -u ${username} -p ${password}  #robocop:disable
  Should Be Equal As Integers    ${rc}    ${0}
