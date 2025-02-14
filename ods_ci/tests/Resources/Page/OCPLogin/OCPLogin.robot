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
  ${rc}    ${out}=    Run And Return Rc And Output    oc login ${OCP_API_URL} -u ${username} -p ${password}  #robocop:disable
  Run Keyword If    ${rc} == ${1}        Log To Console    "Error logging into cluster ${OCP_API_URL} : " ${out}
  Should Be Equal As Integers    ${rc}    ${0}

Login To OCP Using API And Kubeconfig
  [Documentation]   Login to openshift using username and password, storing credentials to Kubeconfig file
  [Arguments]    ${username}      ${password}      ${kubeconfig}
  ${rc}    ${out}=    Run And Return Rc And Output    oc login ${OCP_API_URL} -u ${username} -p ${password} --kubeconfig=${kubeconfig} --insecure-skip-tls-verify=true    #robocop:disable
  Run Keyword If    ${rc} == ${1}        Log To Console    "Error logging into cluster ${OCP_API_URL} : " ${out}
  Should Be Equal As Integers    ${rc}    ${0}
