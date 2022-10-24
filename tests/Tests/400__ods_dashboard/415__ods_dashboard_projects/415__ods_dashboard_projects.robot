*** Settings ***
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workspaces.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Storage.resource
Suite Setup        Project Suite Setup
# Suite Teardown     Project Suite Teardown
Test Setup         Launch Data Science Project Main Page


*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project
${PRJ_DESCRIPTION}=   ODS-CI DS Project is a test for validating DSG feature
# ${PRJ_TITLE_2}=   ODS-CI DS Project 2
# ${PRJ_DESCRIPTION_2}=   ODS-CI DS Project 2 is a test for validating DSG feature
${NB_IMAGE}=        Minimal Python
${WRKSP_TITLE}=   ODS-CI Workspace 1
${WRKSP_DESCRIPTION}=   ODS-CI Workspace 1 is a test workspace using ${NB_IMAGE} image to test DS Projects feature
${WRKSP_2_TITLE}=   ODS-CI Workspace 2
${WRKSP_2_DESCRIPTION}=   ODS-CI Workspace 2 is a test workspace using ${NB_IMAGE} image to test DS Projects feature
${WRKSP_3_TITLE}=   ODS-CI Workspace 2
${WRKSP_3_DESCRIPTION}=   ODS-CI Workspace 3 is a test workspace using ${NB_IMAGE} image to test DS Projects feature
${PV_NAME}=         ods-ci-pv
${PV_DESCRIPTION}=         ods-ci-pv is a PV created to test DS Projects feature
# PV size are in GB
${PV_SIZE}=         1


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
    Create Workspace    wrksp_title=${EMPTY}  wrksp_description=${EMPTY}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Ephemeral  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}  start=${FALSE}  press_cancel=${TRUE}
    Create Workspace    wrksp_title=${WRKSP_TITLE}  wrksp_description=${WRKSP_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Ephemeral  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}  start=${FALSE}
    Workspace Should Be Listed      workspace_title=${WRKSP_TITLE}
    Workspace Status Should Be      workspace_title=${WRKSP_TITLE}      status=${WRKSP_STATUS_STOPPED}
    
    Check Corresponding Notebook CR Exists      workspace_title=${WRKSP_TITLE}   namespace=${ns_name}
    Start Workspace     workspace_title=${WRKSP_TITLE}
    Workspace Status Should Be      workspace_title=${WRKSP_TITLE}      status=${WRKSP_STATUS_RUNNING}
    [Teardown]    Close All Browsers

Verify User Can Create And Start A Workspace With Existent PV Storage
    [Tags]    ODS-1814
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workspace    wrksp_title=${WRKSP_2_TITLE}  wrksp_description=${WRKSP_2_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Persistent  pv_existent=${TRUE}   
    ...                 pv_name=${PV_NAME}  pv_description=${NONE}  pv_size=${NONE}  start=${TRUE}
    Workspace Should Be Listed      workspace_title=${WRKSP_2_TITLE}
    Workspace Status Should Be      workspace_title=${WRKSP_2_TITLE}      status=${WRKSP_STATUS_STARTING}
    Wait Until Workspace Is Started     workspace_title=${WRKSP_2_TITLE}
    # Workspace Status Should Be      workspace_title=${WRKSP_2_TITLE}      status=${WRKSP_STATUS_STOPPED}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Check Corresponding Notebook CR Exists      workspace_title=${WRKSP_2_TITLE}   namespace=${ns_name}
    [Teardown]   Close All Browsers

Verify User Can Create And Start A Workspace Adding A New PV Storage
    [Tags]    ODS-1816
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workspace    wrksp_title=${WRKSP_3_TITLE}  wrksp_description=${WRKSP_3_DESCRIPTION}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Persistent  pv_existent=${FALSE}
    ...                 pv_name=${PV_NAME}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}  start=${TRUE}
    Workspace Should Be Listed      workspace_title=${WRKSP_3_TITLE}
    Reload Page
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Workspace Status Should Be      workspace_title=${WRKSP_3_TITLE}      status=${WRKSP_STATUS_STARTING}
    # the continue on failure should be temporary
    Run Keyword And Continue On Failure    Wait Until Workspace Is Started     workspace_title=${WRKSP_3_TITLE}
    Check Corresponding Notebook CR Exists      workspace_title=${WRKSP_3_TITLE}   namespace=${ns_name}
    Reload Page
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    ${connected_woksps}=    Create List    ${WRKSP_3_TITLE}
    Storage Should Be Listed    storage_title=${PV_NAME}    storage_description=${PV_DESCRIPTION}
    ...                         storage_type=Persistent storage    connected_wrksp=${connected_woksps}
    Storage Size Should Be    title=${PV_NAME}    namespace=${ns_name}  size=${PV_SIZE}
    [Teardown]   Close All Browsers

Verify User Can Launch A Workspace
    [Tags]    ODS-1815
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Start Workspace     workspace_title=${WRKSP_TITLE}
    Launch Workspace    workspace_title=${WRKSP_TITLE}
    Check Launched Workspace Is The Correct One     workspace_title=${WRKSP_TITLE}     image=${NB_IMAGE}    namespace=${ns_name}
    Switch Window      Open Data Hub
    [Teardown]   Close All Browsers

Verify User Can Start And Launch A Workspace From Projects Home Page
    [Tags]    ODS-1818
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    ${_}    ${workspace_cr_name}=    Get Openshift Notebook CR From Workspace    workspace_title=${WRKSP_TITLE}    namespace=${ns_name}
    Start Workspace From Projects Home Page     workspace_title=${WRKSP_TITLE}   project_title=${PRJ_TITLE}  workspace_cr_name=${workspace_cr_name}    namespace=${ns_name}
    Launch Workspace From Projects Home Page    workspace_title=${WRKSP_TITLE}  project_title=${PRJ_TITLE}
    Check Launched Workspace Is The Correct One     workspace_title=${WRKSP_TITLE}     image=${NB_IMAGE}    namespace=${ns_name}
    Switch Window      Open Data Hub
    [Teardown]   Close All Browsers


Verify User Can Stop A Workspace
    [Tags]    ODS-1817
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Stop Workspace    workspace_title=${WRKSP_TITLE}    press_cancel=${TRUE}
    Stop Workspace    workspace_title=${WRKSP_TITLE}
    # add checks on notebook pod is terminated
    [Teardown]   Close All Browsers
    

Verify User Can Delete A Workspace
    [Tags]    ODS-1813
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Delete Workspace    workspace_title=${WRKSP_TITLE}    press_cancel=${TRUE}
    Delete Workspace    workspace_title=${WRKSP_TITLE}
    Check Workspace Resources Are Deleted    workspace_title=${WRKSP_TITLE}   namespace=${ns_name}
    [Teardown]   Close All Browsers


Verify User Can Delete A Data Science Project
    [Tags]    ODS-1784
    Delete Data Science Project   project_title=${PRJ_TITLE}
    # check workspaces and resources get deleted too


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
    [Arguments]     ${workspace_title}  ${namespace}
    ${res}  ${response}=    Get Openshift Notebook CR From Workspace   workspace_title=${workspace_title}  namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=Notebook CR not found for ${workspace_title} in ${namespace} NS
    END

Check Workspace Resources Are Deleted
    [Arguments]    ${workspace_title}   ${namespace}
    ${status}=      Run Keyword And Return Status    Check Corresponding Notebook CR Exists   workspace_title=${workspace_title}   namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The notebook CR for ${workspace_title} is still present, while it should have been deleted.        
    END

