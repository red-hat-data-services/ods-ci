*** Settings ***
Documentation     Check if notifications emails list parameter is properly set after RHODS installation
Resource          ../../../Resources/ODS.robot
Resource          ../../../Resources/Common.robot
Resource          ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource          ../../../Resources/Page/OSD/ClusterManagement/ClusterManagement.resource
Library           DebugLibrary
Library           SeleniumLibrary
Library           Process
Library           yaml
Library           Collections
Test Setup        Set Library Search Order  SeleniumLibrary
Test Teardown     End Web Test


*** Variables ***
#${MOCK_EMAIL_ADDRESS}  dummyEmail@redhat.com   # Look into this, as the capital 'E' is not allowed by some input validation RegEx.
${MOCK_EMAIL_ADDRESS}  dummyemail@redhat.com
${OPERATOR_NAMESPACE}  redhat-ods-operator
${PARAMETER_SECRET_NAME}  addon-managed-odh-parameters
${MONITORING_NAMESPACE}  redhat-ods-monitoring
${ALERTMANAGER_CM}        alertmanager
${ALERTMANAGER_CFG_NAME}  alertmanager.yml

*** Test Cases ***
Can Install RHODS Operator With custom notification emails list
  [Tags]  TBC  ODS-518
  Open ClusterManagement  ${RED_HAT_USER.USERNAME}  ${RED_HAT_USER.PASSWORD}
  Open Addons Tab
  Install RHODS Operator From AddOns  ${MOCK_EMAIL_ADDRESS}
  Wait Until Page Does Not Contain  Installing  timeout=1800
  Sleep  10

Verify RHODS notification emails list Secret properly set
  [Tags]  Smoke  Sanity  ODS-518
  [Documentation]  Check if the addon-managed-odh-parameters Secret has a properly set notification-emails value
  ...              Note: in order to run this, user must be logged into openshift console via oc
  ${email_list}=  Run  oc get secret -n ${OPERATOR_NAMESPACE} -o go-template --template='{{ index .data "notification-email" | base64decode }}' ${PARAMETER_SECRET_NAME}
  Should Not Contain  ${email_list}  "error:"
  Should Be Equal  ${email_list}  ${MOCK_EMAIL_ADDRESS}

Verify RHODS notification emails list Secret matches value set in installation
  [Tags]  Smoke  Sanity  ODS-518
  [Documentation]  Check if the addon-managed-odh-parameters Secret has a properly set notification-emails value
  ...              Note: in order to run this, user must be logged into openshift console via oc
  ${email_list}=  Run  oc get secret -n ${OPERATOR_NAMESPACE} -o go-template --template='{{ index .data "notification-email" | base64decode }}' ${PARAMETER_SECRET_NAME}
  Should Be Equal  ${email_list}  ${MOCK_EMAIL_ADDRESS}

Verify RHODS alertmanger reciever set correctly with email list
  [Tags]  Smoke  Sanity  ODS-518
  [Documentation]  Retreive, parse, and verify that the Mock email address used in RHODS installation is correctly set in the AlertManager Config file.
  ${am_cfg}   Run   oc get cm -n ${MONITORING_NAMESPACE} -o go-template --template='{{ index .data "${ALERTMANAGER_CFG_NAME}" }}' ${ALERTMANAGER_CM}
  Should Not Contain    ${am_cfg}    "error:"
  ${loaded_cfg}=   yaml.Safe Load  ${am_cfg}
  @{receivers}=      Set Variable  ${loaded_cfg}[receivers]
  FOR   ${rcv}   IN   @{receivers}
    Run keyword if  'email_configs' in ${rcv}  Find Email Recipients In Configs  ${rcv}
  END

*** Keywords ***
Find Email Recipients In Configs
  [Arguments]  ${rcv}
  @{email_configs}=   Set Variable  ${rcv}[email_configs]
  ${found} =   Set Variable  ${false}

  FOR  ${cfg}  IN  @{email_configs}
    ${cfg_dict}=  Convert To Dictionary  ${cfg}
    IF  'to' in ${cfg_dict}
      IF  "${cfg_dict}[to]" == "${MOCK_EMAIL_ADDRESS}"
        ${found} =  Set Variable  ${true}
      END
    END
  END
  Should Be True  ${found}
