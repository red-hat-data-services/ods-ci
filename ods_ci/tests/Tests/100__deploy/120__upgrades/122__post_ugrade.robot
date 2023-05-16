*** Settings ***
Documentation       Test Suite for Upgrade testing,to be run after the upgrade
Library            OpenShiftLibrary
Resource           ../../../Resources/RHOSi.resource
Resource           ../../../Resources/ODS.robot
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource           ../../../Resources/Page/ODH/AiApps/Rhosak.resource
Resource           ../../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource           ../../../Resources/Page/LoginPage.robot
Resource           ../../../Resources/Page/OCPLogin/OCPLogin.robot
Resource           ../../../Resources/Common.robot
Resource           ../../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource           ../../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource           ../../../Resources/Page/HybridCloudConsole/OCM.robot


*** Variables ***
${S_SIZE}       25


*** Test Cases ***
Verify PVC Size
    [Documentation]    Verify PVC Size after the upgrade
    [Tags]  Upgrade
    Get Dashboard Config Data
    ${size}   Set Variable      ${payload[0]['spec']['notebookController']['pvcSize']}[:-2]
    Should Be Equal As Strings    '${size}'    '${S_SIZE}'

Verify Pod Toleration
    [Documentation]    Verify Pod toleration after the upgrade
    [Tags]  Upgrade
    ${enable}   Set Variable      ${payload[0]['spec']['notebookController']['notebookTolerationSettings']['enabled']}
    Should Be Equal As Strings    '${enable}'    'True'

Verify RHODS User Groups
    [Documentation]    Verify User Configuration after the upgrade
    [Tags]  Upgrade
    ${admin}     Set Variable      ${payload[0]['spec']['groupsConfig']['adminGroups']}
    ${user}      Set Variable      ${payload[0]['spec']['groupsConfig']['allowedGroups']}
    Should Be Equal As Strings    '${admin}'    'rhods-admins,rhods-users'
    Should Be Equal As Strings    '${user}'   'system:authenticated'
    [Teardown]  Set Default Users

Verify Culler is Enabled
    [Documentation]    Verify Culler Configuration after the upgrade
    [Tags]  Upgrade
    ${status}    Check If ConfigMap Exists   redhat-ods-applications     notebook-controller-culler-config
    IF    '${status}' != 'PASS'
         Fail    msg=Culler has been diabled after the upgrade
    END

Verify Notebook Has Not Restarted
    [Documentation]    Verify Notbook pod has not restarted after the upgrade
    [Tags]  Upgrade
    ${return_code}    ${new_timestamp}    Run And Return Rc And Output   oc get pod -n rhods-notebooks jupyter-nb-ldap-2dadmin2-0 --no-headers --output='custom-columns=TIMESTAMP:.metadata.creationTimestamp'   #robocop:disable
    Should Be Equal As Integers    ${return_code}     0
    Should Be Equal   ${timestamp}      ${new_timestamp}    msg=Running notebook pod has restarted

Verify Custom Image Is Present
   [Tags]  Upgrade
   [Documentation]    Verify Custom Noteboook is not deleted after the upgrade
   ${status}  Run Keyword And Return Status     Oc Get    kind=ImageStream   namespace=redhat-ods-applications
   ...   field_selector=metadata.name==byon-upgrade
   IF    not ${status}   Fail    Notebook image is deleted after the upgrade
   [Teardown]  Delete OOTB Image

Reset PVC Size Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Set PVC Value In RHODS Dashboard    20
    [Teardown]   Dashboard Test Teardown

Reset Culler Timeout
    [Documentation]    Sets a culler timeout via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Disable Notebook Culler
    [Teardown]   Dashboard Test Teardown

Resetting Pod Toleration Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains    Notebook pod tolerations
    Disable Pod Toleration Via UI
    Enable "Usage Data Collection"
    IF    ${is_data_collection_enabled}==True
          Fail    msg=Usage data colletion is enbaled after the upgrade
    END
    [Teardown]   Dashboard Test Teardown

Verify POD Status
    [Documentation]    Verify all the pods are up and running
    [Tags]  Upgrade
    Wait For Pods Status  namespace=redhat-ods-applications  timeout=60
    Log  Verified redhat-ods-applications  console=yes
    Wait For Pods Status  namespace=redhat-ods-operator  timeout=60
    Log  Verified redhat-ods-operator  console=yes
    Wait For Pods Status  namespace=redhat-ods-monitoring  timeout=60
    Log  Verified redhat-ods-monitoring  console=yes
    Oc Get  kind=Namespace  field_selector=metadata.name=rhods-notebooks
    Log  "Verified rhods-notebook"


*** Keywords ***
Dashboard Suite Setup
    [Documentation]  Basic suite setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Dashboard Test Teardown
    [Documentation]  Basic suite Teradown
    Close All Browsers

Get Dashboard Config Data
    [Documentation]  Get OdhDashboardConfig CR data
    ${payload}    Oc Get  kind=OdhDashboardConfig  namespace=redhat-ods-applications
    ...    field_selector=metadata.name==odh-dashboard-config
    Set Suite Variable    ${payload}   #robocop:disable

Set Default Users
    [Documentation]  Set Default user settings
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings

Delete OOTB Image
   [Documentation]  Delete the Custom notbook create
   ${status}  Run Keyword And Return Status     Oc Delete  kind=ImageStream  name=byon-upgrade  namespace=redhat-ods-applications  #robocop:disable
   IF    not ${status}   Fail    Notebook image is deleted after the upgrade
