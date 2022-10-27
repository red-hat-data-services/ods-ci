*** Settings ***
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Storages.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Suite Setup        Project Suite Setup
# Suite Teardown     Project Suite Teardown
Test Setup         Launch Data Science Project Main Page
Test Teardown      Close All Browsers


*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project
${PRJ_DESCRIPTION}=   ODS-CI DS Project is a test for validating DSG feature
${NB_IMAGE}=        Minimal Python
${WORKBENCH_TITLE}=   ODS-CI Workspace 1
${WORKBENCH_DESCRIPTION}=   ODS-CI Workspace 1 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_2_TITLE}=   ODS-CI Workspace 2
${WORKBENCH_2_DESCRIPTION}=   ODS-CI Workspace 2 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_3_TITLE}=   ODS-CI Workspace 3
${WORKBENCH_3_DESCRIPTION}=   ODS-CI Workspace 3 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${PV_BASENAME}=         ods-ci-pv
${PV_DESCRIPTION}=         ods-ci-pv is a PV created to test DS Projects feature
# PV size are in GB
${PV_SIZE}=         2
${DC_S3_NAME}=    ods-ci-s3
${DC_S3_ENDPOINT}=    custom.endpoint.s3.com
${DC_S3_REGION}=    ods-ci-region
${DC_S3_TYPE}=    Object storage


*** Test Cases ***
Verify User Cannot Create Project Without Title
    [Tags]    ODS-1783
    [Setup]   Launch Data Science Project Main Page
    Create Project With Empty Title And Expect Error
    # add close modal
    
Verify User Can Create A Data Science Project
    [Tags]    ODS-1775
    [Setup]   Launch Data Science Project Main Page
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_TITLE}
    Project's Owner Should Be   expected_username=${OCP_ADMIN_USER.USERNAME}   project_title=${PRJ_TITLE}
    # Project's Owner Should Be   expected_username=${TEST_USER_3.USERNAME}   project_title=${PRJ_TITLE}
    ${ns_name}=    Check Corresponding Namespace Exists    project_title=${PRJ_TITLE}

Verify User Can Create And Start A Workspace With Ephimeral Storage
    [Tags]    ODS-1812
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workspace    workbench_title=${EMPTY}  workbench_description=${EMPTY}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Ephemeral  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}  press_cancel=${TRUE}
    Create Workspace    workbench_title=${WORKBENCH_TITLE}  workbench_description=${WORKBENCH_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Ephemeral  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}
    Workspace Should Be Listed      workbench_title=${WORKBENCH_TITLE}
    Workspace Status Should Be      workbench_title=${WORKBENCH_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    # the continue on failure should be temporary
    Run Keyword And Continue On Failure    Wait Until Workspace Is Started     workbench_title=${WORKBENCH_3_TITLE}
    Check Corresponding Notebook CR Exists      workbench_title=${WORKBENCH_TITLE}   namespace=${ns_name}

Verify User Can Create A PV Storage
    [Tags]    ODS-1819
    ${pv_name}=    Set Variable    ${PV_BASENAME}-A
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    ${workbenchs}=    Create Dictionary    ${WORKBENCH_TITLE}=mount-data
    Create PersistenVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${NONE}     press_cancel=${TRUE}    project_title=${PRJ_TITLE}
    Create PersistenVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${workbenchs}   project_title=${PRJ_TITLE}
    Storage Should Be Listed    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                         type=Persistent storage    connected_workbench=${workbenchs}
    Check Corresponding PersistentVolumeClaim Exists    storage_name=${pv_name}    namespace=${ns_name}
    Storage Size Should Be    name=${pv_name}    namespace=${ns_name}  size=${PV_SIZE}

Verify User Can Create And Start A Workspace With Existent PV Storage
    [Tags]    ODS-1814
    ${pv_name}=    Set Variable    ${PV_BASENAME}-existent
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create PersistenVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${NONE}    project_title=${PRJ_TITLE}
    Create Workspace    workbench_title=${WORKBENCH_2_TITLE}  workbench_description=${WORKBENCH_2_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Persistent  pv_existent=${TRUE}   
    ...                 pv_name=${pv_name}  pv_description=${NONE}  pv_size=${NONE}
    Workspace Should Be Listed      workbench_title=${WORKBENCH_2_TITLE}
    Workspace Status Should Be      workbench_title=${WORKBENCH_2_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    Wait Until Workspace Is Started     workbench_title=${WORKBENCH_2_TITLE}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Check Corresponding Notebook CR Exists      workbench_title=${WORKBENCH_2_TITLE}   namespace=${ns_name}

Verify User Can Create And Start A Workspace Adding A New PV Storage
    [Tags]    ODS-1816
    ${pv_name}=    Set Variable    ${PV_BASENAME}-new
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workspace    workbench_title=${WORKBENCH_3_TITLE}  workbench_description=${WORKBENCH_3_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Persistent  pv_existent=${FALSE}
    ...                 pv_name=${pv_name}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    Workspace Should Be Listed      workbench_title=${WORKBENCH_3_TITLE}
    Reload Page
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Workspace Status Should Be      workbench_title=${WORKBENCH_3_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    # the continue on failure should be temporary
    Run Keyword And Continue On Failure    Wait Until Workspace Is Started     workbench_title=${WORKBENCH_3_TITLE}
    Check Corresponding Notebook CR Exists      workbench_title=${WORKBENCH_3_TITLE}   namespace=${ns_name}
    Reload Page
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    ${connected_woksps}=    Create List    ${WORKBENCH_3_TITLE}
    Storage Should Be Listed    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                         type=Persistent storage    connected_workbench=${connected_woksps}
    Storage Size Should Be    name=${pv_name}    namespace=${ns_name}  size=${PV_SIZE}

Verify User Can Stop A Workspace
    [Tags]    ODS-1817
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Stop Workspace    workbench_title=${WORKBENCH_TITLE}    press_cancel=${TRUE}
    Stop Workspace    workbench_title=${WORKBENCH_TITLE}
    # add checks on notebook pod is terminated but CR is present

Verify User Can Launch A Workspace
    [Tags]    ODS-1815
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Start Workspace     workbench_title=${WORKBENCH_TITLE}
    Launch Workspace    workbench_title=${WORKBENCH_TITLE}
    Check Launched Workspace Is The Correct One     workbench_title=${WORKBENCH_TITLE}     image=${NB_IMAGE}    namespace=${ns_name}
    Switch Window      Open Data Hub

Verify User Can Stop A Workspace From Projects Home Page
    [Tags]    ODS-1823
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    ${_}    ${workbench_cr_name}=    Get Openshift Notebook CR From Workspace    workbench_title=${WORKBENCH_TITLE}    namespace=${ns_name}
    Stop Workspace From Projects Home Page     workbench_title=${WORKBENCH_TITLE}   project_title=${PRJ_TITLE}  workbench_cr_name=${workbench_cr_name}    namespace=${ns_name}
    Workbench Launch Link Should Be Disabled    workbench_title=${WORKBENCH_TITLE}  project_title=${PRJ_TITLE}
    # add checks on notebook pod is terminated but CR is present

Verify User Can Start And Launch A Workspace From Projects Home Page
    [Tags]    ODS-1818
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    ${_}    ${workbench_cr_name}=    Get Openshift Notebook CR From Workspace    workbench_title=${WORKBENCH_TITLE}    namespace=${ns_name}
    Start Workspace From Projects Home Page     workbench_title=${WORKBENCH_TITLE}   project_title=${PRJ_TITLE}  workbench_cr_name=${workbench_cr_name}    namespace=${ns_name}
    Launch Workspace From Projects Home Page    workbench_title=${WORKBENCH_TITLE}  project_title=${PRJ_TITLE}
    Check Launched Workspace Is The Correct One     workbench_title=${WORKBENCH_TITLE}     image=${NB_IMAGE}    namespace=${ns_name}
    Switch Window      Open Data Hub

 Verify User Can Delete A Workspace
    [Tags]    ODS-1813
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Delete Workspace    workbench_title=${WORKBENCH_TITLE}    press_cancel=${TRUE}
    Delete Workspace    workbench_title=${WORKBENCH_TITLE}
    Check Workspace CR Is Deleted    workbench_title=${WORKBENCH_TITLE}   namespace=${ns_name}

Verify User Can Delete A Persistent Storage
    [Tags]    ODS-1824
    ${pv_name}=    Set Variable    ${PV_BASENAME}-TO-DELETE
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create PersistenVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${NONE}   project_title=${PRJ_TITLE}
    Delete Storage    name=${pv_name}    press_cancel=${TRUE}
    Delete Storage    name=${pv_name}    press_cancel=${FALSE}
    Storage Should Not Be Listed    name=${pv_name}
    Check Storage PersistentVolumeClaim Is Deleted    storage_name=${pv_name}    namespace=${ns_name}

Verify User Cand Add A S3 Data Connection
    [Tags]    ODS-1825
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}    aws_access_key=${S3.AWS_ACCESS_KEY_ID}
    ...                          aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}    aws_s3_endpoint=${DC_S3_ENDPOINT}    aws_region=${DC_S3_REGION}
    Data Connection Should Be Listed    name=${DC_S3_NAME}    type=${DC_S3_TYPE}    connected_workbench=${NONE}
    Check Corresponding Data Connection Secret Exists    dc_name=${DC_S3_NAME}    namespace=${ns_name}

Verify User Can Delete A Data Connection
    [Tags]    ODS-1826
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Delete Data Connection    name=${DC_S3_NAME}   press_cancel=${True}
    Delete Data Connection    name=${DC_S3_NAME}
    Check Data Connection Secret Is Deleted    dc_name=${DC_S3_NAME}    namespace=${ns_name}

Verify User Can Delete A Data Science Project
    [Tags]    ODS-1784
    Delete Data Science Project   project_title=${PRJ_TITLE}
    # check workbenchs and resources get deleted too


*** Keywords ***
Project Suite Setup
    Set Library Search Order    SeleniumLibrary
    # RHOSi Setup

Project Suite Teardown
    Close All Browsers
    Delete All Data Science Projects From CLI

Launch Data Science Project Main Page
    [Arguments]     ${username}=${TEST_USER_3.USERNAME}     ${password}=${TEST_USER_3.PASSWORD}
    Launch Dashboard    ocp_user_name=${username}  ocp_user_pw=${TEST_USER_3.PASSWORD}  browser_options=${BROWSER.OPTIONS}
    Open Data Science Projects Home Page

Create Project With Empty Title And Expect Error
    ${error_rgx}=   Set Variable    Element[ a-zA-Z=\(\)\[\]"'\/\s]+was not enabled[ a-zA-Z=\(\)\[\]"'\/\s0-9.]+
    Run Keyword And Expect Error    Element*was not enabled*   Create Data Science Project    title=${EMPTY}  description=${EMPTY}

Check Corresponding Namespace Exists
    [Arguments]     ${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    Oc Get      kind=Project    name=${ns_name}
    [Return]    ${ns_name}

Check Corresponding Notebook CR Exists
    [Arguments]     ${workbench_title}  ${namespace}
    ${res}  ${response}=    Get Openshift Notebook CR From Workspace   workbench_title=${workbench_title}  namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=Notebook CR not found for ${workbench_title} in ${namespace} NS
    END

Check Workspace CR Is Deleted
    [Arguments]    ${workbench_title}   ${namespace}    ${timeout}=10s
    Wait Until Keyword Succeeds    ${timeout}    2s    Check Corresponding Notebook CR Exists   workbench_title=${workbench_title}   namespace=${namespace}
    ${status}=      Run Keyword And Return Status    Check Corresponding Notebook CR Exists   workbench_title=${workbench_title}   namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The notebook CR for ${workbench_title} is still present, while it should have been deleted.        
    END

Check Corresponding Data Connection Secret Exists
    [Arguments]     ${dc_name}  ${namespace}
    ${res}  ${response}=    Get Openshift Secret From Data Connection   dc_name=${dc_name}  namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=Secret not found for ${dc_name} in ${namespace} NS
    END

Check Data Connection Secret Is Deleted
    [Arguments]    ${dc_name}   ${namespace}    ${timeout}=10s
    ${status}=      Run Keyword And Return Status    Check Corresponding Data Connection Secret Exists    dc_name=${dc_name}    namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The secret for ${dc_name} data connection is still present, while it should have been deleted.        
    END

Check Corresponding PersistentVolumeClaim Exists
    [Arguments]     ${storage_name}  ${namespace}
    ${res}  ${response}=    Get Openshift PVC From Storage   name=${storage_name}  namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=PVC not found for ${storage_name} in ${namespace} NS
    END

Check Storage PersistentVolumeClaim Is Deleted
    [Arguments]    ${storage_name}   ${namespace}    ${timeout}=10s
    ${status}=      Run Keyword And Return Status    Check Corresponding PersistentVolumeClaim Exists    storage_name=${storage_name}    namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The PVC for ${storage_name} storage is still present, while it should have been deleted.        
    END
