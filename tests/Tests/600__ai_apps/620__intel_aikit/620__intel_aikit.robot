*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Library         SeleniumLibrary
Library         OpenShiftCLI
Suite Setup     Intel_Aikit Suite Setup
Suite Teardown  Intel_Aikit Suite Teardown

*** Variables ***
${intel_aikit_appname}           aikit
${intel_aikit_container_name}    Intel® oneAPI AI Analytics Toolkit Container
${intel_aikit_operator_name}    Intel® oneAPI AI Analytics Toolkit Operator
${image_path}                   image-registry.openshift-image-registry.svc:5000/redhat-ods-applications

*** Test Cases ***
Verify intel aikit Is Available In RHODS Dashboard Explore Page
  [Tags]  ODS-1017 Smoke  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page     ${intel_aikit_container_name}
  Verify Service Provides "Get Started" Button In The Explore Page     ${intel_aikit_container_name}

Verify Inetl AIKIT Operator Can Be Installed Using OpenShift Console
   [Tags]  ODS-760   ODS-702   Sanity
   [Documentation]  This Test Case Installed Intel AIKIT operator in Openshift cluster
   ...              Check and Launch AIKIT notebook image from RHODS dashboard
   Check And Install Operator in Openshift    ${intel_aikit_container_name}    ${intel_aikit_appname}
   Create Tabname Instance For Installed Operator        ${intel_aikit_operator_name}      AIKitContainer    redhat-ods-applications
   Verify If Intel AIKIT Service is Enabled in RHODS Dashboard
   Verify JupyterHub Can Spawn AIKIT Notebook
   [Teardown]   Uninstall AIKIT Operator

***Keywords ***
Intel_Aikit Suite Setup
  Set Library Search Order  SeleniumLibrary

Intel_Aikit Suite Teardown
  Close All Browsers

Verify If Intel AIKIT Service is Enabled in RHODS Dashboard
    Go To  ${ODH_DASHBOARD_URL}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Verify Service Is Enabled          ${intel_aikit_container_name}

Uninstall AIKIT Operator
    Go To  ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Delete Tabname Instance For Installed Operator      ${intel_aikit_operator_name}      AIKitContainer    redhat-ods-applications
    Uninstall Operator       ${intel_aikit_operator_name}
    OpenShiftCLI.Delete      kind=ImageStream    namespace=redhat-ods-applications  label_selector=opendatahub.io/notebook-image=true  field_selector=metadata.name==oneapi-aikit

Verify JupyterHub Can Spawn AIKIT Notebook
    Launch JupyterHub Spawner From Dashboard
    Wait Until Page Contains Element   xpath://input[@name="oneAPI AI Analytics Toolkit"]
    Wait Until Element Is Enabled     xpath://input[@name="oneAPI AI Analytics Toolkit"]  timeout=10
    Spawn Notebook With Arguments  image=oneapi-aikit
    Fix Spawner Status