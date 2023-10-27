*** Settings ***
Documentation      Suite to test additional scenarios for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/OCP.resource
Resource           ../../../Resources/ODS.robot
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource           ../../../Resources/Page/ODH/JupyterHub/GPU.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown
Test Teardown      Close All Browsers


*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project 2
${PRJ_TITLE_GPU}=   ODS-CI DS Project GPU
${PRJ_RESOURCE_NAME}=   ods-ci-ds-project-test-additional
${PRJ_DESCRIPTION}=   ${PRJ_TITLE} is a test project for validating DS Project feature
${TOLERATIONS}=    workbench-tolerations
${TOLERATIONS_2}=    workbench-tolerations-two
${DEFAULT_TOLERATIONS}=    NotebooksOnly
${WORKBENCH_TITLE_TOL_1}=   ODS-CI Workbench Tol
${WORKBENCH_TITLE_TOL_2}=   ODS-CI Workbench Tol 2
${WORKBENCH_DESCRIPTION}=   a test workbench to check tolerations are applied
${WORKBENCH_TITLE_GPU}=   ODS-CI Workbench GPU
${WORKBENCH_DESCRIPTION_GPU}=   ${WORKBENCH_TITLE_GPU} is a test workbench using GPU
${NB_IMAGE}=        Minimal Python
${NB_IMAGE_GPU}=        PyTorch
${PV_NAME_TOL_1}=         ods-ci-tolerations
${PV_NAME_TOL_2}=         ods-ci-tolerations-2
${PV_NAME_GPU}=         ods-ci-gpu
${PV_DESCRIPTION}=         it is a PV created to test DS Projects feature
${PV_SIZE}=         1


*** Test Cases ***
Verify Notebook Tolerations Are Applied To Workbenches
    [Documentation]    Verifies workbenches get the custom tolerations set by
    ...  admins in "Cluster Settings" page. It checks 3 scenarios:
    ...  -tolerations changes applied to workbench created after the changes (value from null to A)
    ...  -tolerations change applied to existent workbench, after restart (value from null to A)
    ...  -tolerations change applied to existent workbench, after restart (value from A to A)
    ...  -tolerations get removed from existent workbench, after restart (check in teardown)
    [Tags]    Tier1    Sanity
    ...       ODS-1969    ODS-2057
    Create Workbench    workbench_title=${WORKBENCH_TITLE_TOL_1}
    ...                 workbench_description=${WORKBENCH_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_existent=${FALSE}    pv_name=${PV_NAME_TOL_1}
    ...                 pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    Run Keyword And Continue On Failure
    ...    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_TOL_1}
    Open Settings And Set Tolerations To    ${TOLERATIONS}
    Open Data Science Projects Home Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Sleep   40s    reason=Wait enough time for letting Dashboard to fetch the latest toleration settings
    Create Workbench    workbench_title=${WORKBENCH_TITLE_TOL_2}  workbench_description=${WORKBENCH_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_existent=${FALSE}    pv_name=${PV_NAME_TOL_2}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    Verify Workbench Has The Expected Tolerations    workbench_title=${WORKBENCH_TITLE_TOL_2}
    ...    toleration=${TOLERATIONS}
    Verify Workbench Does Not Have The Given Tolerations
    ...    workbench_title=${WORKBENCH_TITLE_TOL_1}    tolerations_text=${TOLERATIONS}
    Stop Workbench    workbench_title=${WORKBENCH_TITLE_TOL_1}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Stopped     workbench_title=${WORKBENCH_TITLE_TOL_1}
    Start Workbench    workbench_title=${WORKBENCH_TITLE_TOL_1}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_TOL_1}
    Verify Workbench Has The Expected Tolerations    workbench_title=${WORKBENCH_TITLE_TOL_1}
    ...    toleration=${TOLERATIONS}
    Open Settings And Set Tolerations To    ${TOLERATIONS_2}
    Sleep   40s    reason=Wait enough time for letting Dashboard to fetch the latest toleration settings
    Open Data Science Projects Home Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Stop Workbench    workbench_title=${WORKBENCH_TITLE_TOL_1}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Stopped     workbench_title=${WORKBENCH_TITLE_TOL_1}
    Start Workbench    workbench_title=${WORKBENCH_TITLE_TOL_1}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_TOL_1}
    Verify Workbench Has The Expected Tolerations    workbench_title=${WORKBENCH_TITLE_TOL_1}
    ...    toleration=${TOLERATIONS_2}
    Verify Workbench Does Not Have The Given Tolerations
    ...    workbench_title=${WORKBENCH_TITLE_TOL_1}    tolerations_text=${TOLERATIONS}
    [Teardown]    Restore Tolerations Settings And Clean Project

Verify User Can Add GPUs To Workbench
    [Documentation]    Verifies user can add GPUs to an already started workbench
    [Tags]    Tier1    Sanity
    ...       ODS-2013    Resources-GPU
    Launch Data Science Project Main Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE_GPU}  workbench_description=${EMPTY}
    ...    prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE_GPU}   deployment_size=Small
    ...    storage=Persistent  pv_existent=${FALSE}    pv_name=${PV_NAME_GPU}
    ...    pv_description=${EMPTY}  pv_size=${PV_SIZE}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_GPU}
    Edit GPU Number    workbench_title=${WORKBENCH_TITLE_GPU}    gpus=1
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Restarting    workbench_title=${WORKBENCH_TITLE_GPU}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_GPU}
    ...    timeout=60s
    Verify Workbench Pod Has Limits And Requests For GPU    workbench_title=${WORKBENCH_TITLE_GPU}
    ...    project_title=${PRJ_TITLE}    exp_gpu_value=1
    Launch And Access Workbench    workbench_title=${WORKBENCH_TITLE_GPU}
    Open New Notebook In Jupyterlab Menu
    Verify Pytorch Can See GPU
    [Teardown]    Clean Project And Sleep    workbench_title=${WORKBENCH_TITLE_GPU}
    ...    pvc_title=${PV_NAME_GPU}    project_title=${PRJ_TITLE}

Verify User Can Remove GPUs From Workbench
    [Documentation]    Verifies user can remove GPUs from an already started workbench
    [Tags]    Tier1    Sanity
    ...       ODS-2014    Resources-GPU
    Launch Data Science Project Main Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE_GPU}  workbench_description=${EMPTY}
    ...    prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE_GPU}   deployment_size=Small
    ...    storage=Persistent  pv_existent=${FALSE}    pv_name=${PV_NAME_GPU}
    ...    pv_description=${EMPTY}  pv_size=${PV_SIZE}    gpus=1
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_GPU}
    Sleep    10s     reason=There is some delay in updating the GPU availability in Dashboard
    Stop Workbench    workbench_title=${WORKBENCH_TITLE_GPU}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Stopped     workbench_title=${WORKBENCH_TITLE_GPU}
    Wait Until Keyword Succeeds    10 times    5s
    ...    Edit GPU Number    workbench_title=${WORKBENCH_TITLE_GPU}    gpus=0
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Start Workbench    workbench_title=${WORKBENCH_TITLE_GPU}
    Verify Workbench Pod Does Not Have Limits And Requests For GPU    workbench_title=${WORKBENCH_TITLE_GPU}
    ...    project_title=${PRJ_TITLE}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_GPU}
    Launch And Access Workbench    workbench_title=${WORKBENCH_TITLE_GPU}
    Open New Notebook In Jupyterlab Menu
    Run Keyword And Expect Error    'Using cpu device' does not match 'Using cuda device'    Verify Pytorch Can See GPU
    [Teardown]    Clean Project And Sleep    workbench_title=${WORKBENCH_TITLE_GPU}
    ...    pvc_title=${PV_NAME_GPU}    project_title=${PRJ_TITLE}

Verify DS Projects Home Page Shows The Right Number Of Items The User Has Selected
    [Documentation]    Verifies that correct number of data science projects appear when
    ...                multiple data science projects are added
    [Tags]    ODS-2015    Sanity    Tier1
    [Setup]    Launch Data Science Project Main Page    username=${TEST_USER_4.USERNAME}
    ${all_projects}=    Create Multiple Data Science Projects    title=ds-project-ldap-user     description=numbered project -
    ...    number=20
    Number Of Displayed Projects Should Be    expected_number=10
    ${curr_page_projects}=    Get All Displayed Projects
    ${remaining_projects}=    Remove Current Page Projects From All Projects
    ...                        ${all_projects}    ${curr_page_projects}
    Check Pagination Is Correct On The Current Page    page=1    total=20
    Go To Next Page Of Data Science Projects
    Number Of Displayed Projects Should Be    expected_number=10
    ${curr_page_projects}=    Get All Displayed Projects
    ${remaining_projects}=    Remove Current Page Projects From All Projects
    ...                       ${all_projects}    ${curr_page_projects}
    Check Pagination Is Correct On The Current Page    page=2    total=20
    Should Be Empty    ${remaining_projects}
    [Teardown]    Run Keywords
    ...    SeleniumLibrary.Close All Browsers
    ...    AND
    ...    Delete Multiple Data Science Projects    title=ds-project-ldap-user    number=20

*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects.
    ...                It creates some test variables and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup
    Launch Data Science Project Main Page
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    resource_name=${PRJ_RESOURCE_NAME}

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown

Verify Workbench Has The Expected Tolerations
    [Documentation]    Verifies notebook pod created as workbench
    ...                contains toleration
    [Arguments]    ${workbench_title}    ${toleration}
    ...            ${project_title}=${PRJ_TITLE}
    ${expected}=    Set Variable    ${toleration}:NoSchedule op=Exists
    ${namespace}=        Get Openshift Namespace From Data Science Project    project_title=${project_title}
    ${_}  ${workbench_cr_name}=    Get Openshift Notebook CR From Workbench    workbench_title=${workbench_title}
    ...    namespace=${namespace}
    ${received}=    Get Pod Tolerations    ${workbench_cr_name}-0
    ...    ns=${namespace}
    Run Keyword And Continue On Failure    List Should Contain Value  ${received}  ${expected}
    ...    msg=Unexpected Pod Toleration

Verify Workbench Does Not Have The Given Tolerations
    [Documentation]    Verifies notebook pod created as workbench does not
    ...                contain the given toleration
    [Arguments]    ${workbench_title}    ${tolerations_text}
    ...            ${project_title}=${PRJ_TITLE}
    Run Keyword And Continue On Failure
    ...    Run Keyword And Expect Error    Unexpected Pod Toleration
    ...    Verify Workbench Has The Expected Tolerations
    ...    workbench_title=${workbench_title}
    ...    toleration=${tolerations_text}    project_title=${project_title}

Restore Tolerations Settings And Clean Project
    [Documentation]    Reset the notebook tolerations after testing
    Open Settings And Disable Tolerations
    Open Data Science Projects Home Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Stop Workbench    workbench_title=${WORKBENCH_TITLE_TOL_1}
    Stop Workbench    workbench_title=${WORKBENCH_TITLE_TOL_2}
    Sleep    40s
    ...    reason=waiting for dashboard to fetch the latest tolerations settings
    Start Workbench    workbench_title=${WORKBENCH_TITLE_TOL_1}
    Start Workbench    workbench_title=${WORKBENCH_TITLE_TOL_2}
    Verify Workbench Does Not Have The Given Tolerations
    ...    workbench_title=${WORKBENCH_TITLE_TOL_1}    tolerations_text=${DEFAULT_TOLERATIONS}
    Verify Workbench Does Not Have The Given Tolerations
    ...    workbench_title=${WORKBENCH_TITLE_TOL_2}    tolerations_text=${DEFAULT_TOLERATIONS}
    Verify Workbench Does Not Have The Given Tolerations
    ...    workbench_title=${WORKBENCH_TITLE_TOL_1}    tolerations_text=${TOLERATIONS}
    Verify Workbench Does Not Have The Given Tolerations
    ...    workbench_title=${WORKBENCH_TITLE_TOL_2}    tolerations_text=${TOLERATIONS}
    Verify Workbench Does Not Have The Given Tolerations
    ...    workbench_title=${WORKBENCH_TITLE_TOL_1}    tolerations_text=${TOLERATIONS_2}
    Verify Workbench Does Not Have The Given Tolerations
    ...    workbench_title=${WORKBENCH_TITLE_TOL_2}    tolerations_text=${TOLERATIONS_2}
    Clean Project From Workbench Resources    workbench_title=${WORKBENCH_TITLE_TOL_1}
    ...    pvc_title=${PV_NAME_TOL_1}    project_title=${PRJ_TITLE}
    Clean Project From Workbench Resources    workbench_title=${WORKBENCH_TITLE_TOL_2}
    ...    pvc_title=${PV_NAME_TOL_2}    project_title=${PRJ_TITLE}

Clean Project And Sleep
    [Documentation]    Deletes resources from a test project to free up
    ...                resources or re-use titles
    [Arguments]    ${workbench_title}    ${pvc_title}
    ...            ${project_title}
    Clean Project From Workbench Resources    workbench_title=${workbench_title}
    ...    pvc_title=${pvc_title}    project_title=${project_title}
    Sleep    10s    reason=There is some delay in updating the GPU availability in Dashboard

Verify Workbench Pod Has Limits And Requests For GPU
    [Documentation]    Checks if the notebook/workbench pod has all the limits/requests
    ...                set, including the ones for GPUs
    [Arguments]    ${workbench_title}    ${project_title}    ${exp_gpu_value}
    ${ns_name}    ${cr_name}    ${pod_info}=    Get Workbench Pod    workbench_title=${workbench_title}
    ...    project_title=${project_title}
    Check Limits And Requests For Every Workbench Pod Container
    ...    containers_info=${pod_info[0]['spec']['containers']}
    ...    wb_cr_name=${cr_name}    gpu_present=${TRUE}    exp_gpu_value=${exp_gpu_value}

Verify Workbench Pod Does Not Have Limits And Requests For GPU
    [Documentation]    Checks if the notebook/workbench pod has all the limits/requests
    ...                set, including the ones for GPUs
    [Arguments]    ${workbench_title}    ${project_title}
    ${ns_name}    ${cr_name}    ${pod_info}=    Get Workbench Pod    workbench_title=${workbench_title}
    ...    project_title=${project_title}
    Check Limits And Requests For Every Workbench Pod Container
    ...    containers_info=${pod_info[0]['spec']['containers']}
    ...    wb_cr_name=${cr_name}    gpu_present=${FALSE}

Check Limits And Requests For Every Workbench Pod Container
    [Documentation]    Loops through each container inside a workbench
    ...                to check if limits and requests are set
    [Arguments]    ${containers_info}    ${wb_cr_name}    ${gpu_present}=${TRUE}    ${exp_gpu_value}=1
    FOR    ${container_info}    IN    @{containers_info}
        ${container_name}=    Set Variable    ${container_info['name']}
        IF    "${container_name}" == "${wb_cr_name}"
            Verify CPU And Memory Requests And Limits Are Defined For Pod Container    ${container_info}
            ...    nvidia_gpu=${gpu_present}
            ${requests}=    Set Variable     ${container_info['resources']['requests']}
            ${limits}=    Set Variable     ${container_info['resources']['limits']}
            IF    ${gpu_present} == ${TRUE}
                Run Keyword And Continue On Failure
                ...    Should Be Equal     ${requests['nvidia.com/gpu']}    ${exp_gpu_value}
                Run Keyword And Continue On Failure
                ...    Should Be Equal     ${limits['nvidia.com/gpu']}    ${exp_gpu_value}
            ELSE
                Run Keyword And Continue On Failure
                ...    Dictionary Should Not Contain Key    ${requests}    nvidia.com/gpu
                Run Keyword And Continue On Failure
                ...    Dictionary Should Not Contain Key    ${limits}    nvidia.com/gpu
            END
        ELSE
            Verify CPU And Memory Requests And Limits Are Defined For Pod Container    ${container_info}
            ...    nvidia_gpu=${FALSE}
        END
    END

Open Settings And Set Tolerations To
    [Documentation]    Opens the "Cluster Settings" page in RHODS Dashboard
    ...                and set the tolerations settings to the given one
    [Arguments]    ${tolerations_text}
    Open Dashboard Settings    settings_page=Cluster settings
    Set Pod Toleration Via UI    ${tolerations_text}
    Save Changes In Cluster Settings

Open Settings And Disable Tolerations
    [Documentation]    Opens the "Cluster Settings" page in RHODS Dashboard
    ...                and disable the tolerations settings.
    ...                Before disabling the setting, it restores the default value
    Open Dashboard Settings    settings_page=Cluster settings
    Set Pod Toleration Via UI    ${DEFAULT_TOLERATIONS}
    Disable Pod Toleration Via UI
    Save Changes In Cluster Settings

Create Multiple Data Science Projects
    [Documentation]    Create a given number of data science projects based on title and description
    [Arguments]    ${title}     ${description}    ${number}
    ${all_projects}=    Create List
    FOR    ${counter}    IN RANGE    1    ${number}+1    1
        Create Data Science Project    title=${title}${counter}    description=${description}-${number}
        Open Data Science Projects Home Page
        Append To List    ${all_projects}    ${title}${counter}
    END
    RETURN    ${all_projects}

Delete Multiple Data Science Projects
    [Arguments]    ${title}     ${number}
    FOR    ${counter}    IN RANGE    1    ${number}+1    1
        ${rc}  ${output}=    Run And Return Rc And Output    oc delete project ${title}${counter}
    END
