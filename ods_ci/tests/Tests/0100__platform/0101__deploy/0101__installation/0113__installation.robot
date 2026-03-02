*** Settings ***
Documentation    Tests to verify that ODH in Openshift can be
...              installed from Dashboard
Metadata         Version    0.0.1
Resource         ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource         ../../../../Resources/Page/HybridCloudConsole/HCCLogin.robot
Resource         ../../../../Resources/Common.robot
Resource         ../../../../Resources/RHOSi.resource
Resource         ../../../../Resources/ODS.robot
Library          ../../../../../utils/scripts/ocm/ocm.py
Library          ../../../../../libs/Helpers.py
Library          SeleniumLibrary
Suite Setup      Installation Suite Setup
Suite Teardown   Installation Suite Teardown


*** Variables ***
${STAGE_URL}    https://console.dev.redhat.com/openshift
${PROD_URL}     https://console.redhat.com/openshift


*** Test Cases ***
Can Install ODH Operator
  [Tags]  TBC
  Open OperatorHub
  Install ODH Operator
  ODH Operator Should Be Installed

Verify User Can Access RHODS Documentation From OCM Console
  [Documentation]   Checks user can access RHODS documentation from addon on OCM Console
  [Tags]  ODS-1303
  ...     Tier2
  [Setup]   OCM Test Setup
  Decide OCM URL And Open Link
  Login To HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  Maybe Skip OCM Tour
  Open Cluster By Name
  Wait Until Page Contains Element    //div[@id="cl-details-top"]     20
  Click Button      //button[@data-ouia-component-id="Add-ons"]
  Wait Until Page Contains Element      //div[@data-ouia-component-id="card-addon-managed-odh"]     10
  Click Element     //div[@data-ouia-component-id="card-addon-managed-odh"]
  Page Should Contain Element       //div[@class="pf-l-flex pf-m-space-items-lg pf-m-column"]//a
  Verify Documentation Is Accessible

Verify RHOAI Addon Validates Notification E-Mail Format
  [Tags]  Sanity
  ...     ODS-672
  ...     RHOAI-13065
  [Setup]   OCM Test Setup
  Grant Cluster Editor To User  ${SSO.USERNAME}
  Decide OCM URL And Open Link
  Login To HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  Maybe Skip OCM Tour
  Open Cluster By Name
  Wait Until Page Contains Element    //*[@data-ouia-component-id="Add-ons"]
  Click Element      //*[@data-ouia-component-id="Add-ons"]
  Wait Until Page Contains Element      //div[@data-ouia-component-id="card-addon-managed-odh"]     10
  Click Element     //div[@data-ouia-component-id="card-addon-managed-odh"]
  Click Button    Install
  Wait Until Page Contains Element  //input[@id="notification-email"]
  @{email_values} =  Set Variable
  ...       test@
  ...       test@test.com,
  ...       test@test.com test@test.com test@test.com
  FOR  ${email_value}  IN   @{email_values}
      Input Text    //input[@id="notification-email"]  ${email_value}
      Click Button    //div[@aria-label="Configure Red Hat OpenShift AI"]//button[@type="submit"]
      Wait Until Page Contains Element    //div[@aria-label="Configure Red Hat OpenShift AI"]//div[@data-testid="alert-error"]
      Element Should Contain    //div[@aria-label="Configure Red Hat OpenShift AI"]//p      Add-on parameter value for 'notification-email' is invalid.
  END

Verify RHOAI Is Present In List Of Subscriptions
  [Tags]  Sanity
  ...     ODS-701
  ...     RHOAI-13070
  Skip If RHODS Is Self-Managed
  ${addons} =  Run
  ...    ocm get addons --parameter search="id like 'managed-odh'"
  ${addons} =    Load Json String    ${addons}
  ${num_addons}=  Get From Dictionary    ${addons}  size
  Should Be Equal    ${num_addons}  ${1}


*** Keywords ***
Installation Suite Setup
  Set Library Search Order    SeleniumLibrary
  RHOSi Setup

Installation Suite Teardown
  Close All Browsers
  RHOSi Teardown

OCM Test Setup
  [Documentation]   Setup for ODH in Openshift Installation Test Cases
  Skip If RHODS Is Self-Managed
  Open Browser   browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}

Decide OCM URL And Open Link
  [Documentation]   Decides OCM URL based on the OpenShift Console URL and open the URL.
  ${cluster_type}=  Fetch ODS Cluster Environment
  IF    "${cluster_type}" == "stage"
        ${OCM_URL}=     Set Variable    ${STAGE_URL}
  ELSE
        ${OCM_URL}=     Set Variable    ${PROD_URL}
  END
  Go To     ${OCM_URL}

Verify Documentation Is Accessible
  [Documentation]   Checks documentation link is accessible.
  ${link}=  Get Element Attribute   //div[@class="pf-l-flex pf-m-space-items-lg pf-m-column"]//a    href
  ${status}=    Check HTTP Status Code    ${link}
  IF  ${status}!=200      FAIL
  ...     Documentation Is Not Accessible

Grant Cluster Editor To User
  [Documentation]    Grants Cluster Editor role on the cluster to a user so that it can initiate Addon installation
  [Arguments]  ${username}
  ${cluster_id} =     Get Cluster ID
  ${subscription_id} =  Run
  ...       ocm describe cluster ${cluster_id} --json | jq -r .subscription.id
  Run       echo '{"account_username": "${username}", "role_id": "ClusterEditor"}' | ocm post /api/accounts_mgmt/v1/subscriptions/${subscription_id}/role_bindings

