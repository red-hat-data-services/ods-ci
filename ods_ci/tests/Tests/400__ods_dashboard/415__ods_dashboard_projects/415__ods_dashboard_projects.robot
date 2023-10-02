*** Settings ***
Documentation      Suite to test Data Science Projects (a.k.a DSG) feature
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../../Resources/OCP.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Storages.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown
Test Setup         Launch Data Science Project Main Page
Test Teardown      Close All Browsers

*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project
${PRJ_TITLE1}=    ODS-CI DS Project1
${PRJ_RESOURCE_NAME}=   ods-ci-ds-project-test
${PRJ_DESCRIPTION}=   ${PRJ_TITLE} is a test project for validating DS Projects feature
${NB_IMAGE}=        Minimal Python
${WORKBENCH_TITLE}=   ODS-CI Workbench 1
${WORKBENCH_DESCRIPTION}=   ODS-CI Workbench 1 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_2_TITLE}=   ODS-CI Workbench 2
${WORKBENCH_2_DESCRIPTION}=   ODS-CI Workbench 2 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_3_TITLE}=   ODS-CI Workbench 3
${WORKBENCH_3_DESCRIPTION}=   ODS-CI Workbench 3 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_4_TITLE}=   ODS-CI Workbench 4 - envs
${WORKBENCH_4_DESCRIPTION}=   ODS-CI Workbench 4 - envs is a test workbench
${WORKBENCH_5_TITLE}=   ODS-CI Workbench 5 - XL
${WORKBENCH_5_DESCRIPTION}=   ODS-CI Workbench 5 - XL is a test workbench
...    using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_6_TITLE}=   ODS-CI Workbench 6 - event log
${WORKBENCH_6_DESCRIPTION}=   ODS-CI Workbench 6 - event log is a test workbench
...    using ${NB_IMAGE} image to test DS Projects feature
${PV_BASENAME}=         ods-ci-pv
${PV_DESCRIPTION}=         ods-ci-pv is a PV created to test DS Projects feature
# PV size are in GB
${PV_SIZE}=         2
${DC_S3_NAME}=    ods-ci-s3
${DC_2_S3_NAME}=    ods-ci-s3-connected
${DC_S3_AWS_SECRET_ACCESS_KEY}=    custom dummy secret access key
${DC_S3_AWS_ACCESS_KEY}=    custom dummy access key id
${DC_S3_ENDPOINT}=    custom.endpoint.s3.com
${DC_S3_REGION}=    ods-ci-region
${DC_S3_TYPE}=    Object storage
@{IMAGE_LIST}    Minimal Python    CUDA   PyTorch    Standard Data Science    TensorFlow
${ENV_SECRET_FILEPATH}=    ods_ci/tests/Resources/Files/env_vars_secret.yaml
${ENV_CM_FILEPATH}=    ods_ci/tests/Resources/Files/env_vars_cm.yaml
${NEW_PRJ_DESCRIPTION}=   ${PRJ_TITLE} is a New edited test project for validating DS Projects feature
${NEW_PRJ_TITLE}=   ODS-CI DS Project Updated

*** Test Cases ***
Verify Data Science Projects Page Is Accessible
    [Documentation]    Verifies "Data Science Projects" page is accessible from
    ...                the navigation menu on the left
    [Tags]    Smoke    Sanity
    ...       Tier1
    ...       ODS-1876
    Open Data Science Projects Home Page
    Page Should Contain Element     ${PROJECT_CREATE_BTN_XP}

Verify User Can Access Jupyter Launcher From DS Project Page
    [Documentation]    Verifies Data Science Projects home page contains
    ...                a link to Jupyter Spawner and it is working
    [Tags]    Smoke    Sanity
    ...       Tier1
    ...       ODS-1877
    Open Data Science Projects Home Page
    Page Should Contain Element     ${SPAWNER_LINK}
    Click Element    ${SPAWNER_LINK}
    Wait Until JupyterHub Spawner Is Ready

Verify Workbench Images Have Multiple Versions
    [Documentation]    Verifies that workbench images have an additional
    ...                dropdown which supports N/N-1 image versions.
    [Tags]    Smoke    Sanity
    ...       Tier1
    ...       ODS-2131
    Launch Data Science Project Main Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${EMPTY}
    Click Element    ${WORKBENCH_CREATE_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_NAME_INPUT_XP}
    Run Keyword And Continue On Failure     Element Should Be Disabled    ${WORKBENCH_CREATE_BTN_2_XP}
    FOR    ${img}    IN    @{IMAGE_LIST}
        Select Workbench Jupyter Image    image_name=${img}    version=previous
        Select Workbench Jupyter Image    image_name=${img}    version=default
    END
    [Teardown]    Project Suite Teardown

Verify DS Projects Home Page Shows The Right Number Of Items The User Has Selected
    [Documentation]    Verifies that correct number of data science projects appear when
    ...                multiple data science projects are added
    [Tags]    ODS-2015    Sanity    Tier1
    [Teardown]    Delete Multiple Data Science Projects    title=ds-project-ldap-user    number=20
    ${all_projects}=    Create Multiple Data Science Projects    title=ds-project-ldap-user     description=${EMPTY}
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

Verify User Cannot Create Project With Empty Fields
    [Tags]    Sanity   ODS-1783
    [Documentation]    Verifies users is not allowed to create a project with Empty title
    Create Project With Empty Title And Expect Error
    Close Generic Modal If Present

Verify User Cannot Create Project Using Special Chars In Resource Name
    [Tags]    Sanity    Tier1    ODS-1875
    [Documentation]    Verifies users is not allowed to create a project with a custom resource name
    ...                containing special characters like "@" or "!"
    Create Project With Special Chars In Resource Name And Expect Error
    Close Generic Modal If Present

Verify User Can Access Only Its Owned Projects
    [Tags]    Sanity    Tier1    ODS-1868
    [Documentation]    Verifies each user can access only thei owned projects. Except for
    ...                cluster and dedicated admins which should be able to fetch all the DS Projects
    [Setup]    Set Variables For User Access Test
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_1_USER3}    description=${EMPTY}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_1_USER3}
    Project's Owner Should Be   expected_username=${TEST_USER_3.USERNAME}   project_title=${PRJ_1_USER3}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_2_USER3}    description=${EMPTY}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_2_USER3}
    Project's Owner Should Be   expected_username=${TEST_USER_3.USERNAME}   project_title=${PRJ_2_USER3}
    Launch Data Science Project Main Page    username=${TEST_USER_4.USERNAME}    password=${TEST_USER_4.PASSWORD}
    Create Data Science Project    title=${PRJ_A_USER4}    description=${EMPTY}
    Open Data Science Projects Home Page
    Number Of Displayed Projects Should Be    expected_number=1
    Project Should Be Listed    project_title=${PRJ_A_USER4}
    Project's Owner Should Be   expected_username=${TEST_USER_4.USERNAME}   project_title=${PRJ_A_USER4}
    Project Should Not Be Listed    project_title=${PRJ_1_USER3}
    Project Should Not Be Listed    project_title=${PRJ_2_USER3}
    Switch Browser    1
    Open Data Science Projects Home Page
    Number Of Displayed Projects Should Be    expected_number=2
    Project Should Not Be Listed    project_title=${PRJ_A_USER4}
    Project Should Be Listed    project_title=${PRJ_1_USER3}
    Project Should Be Listed    project_title=${PRJ_2_USER3}
    Launch Data Science Project Main Page    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    Capture Page Screenshot
    Number Of Displayed Projects Should Be    expected_number=3
    Project Should Be Listed    project_title=${PRJ_1_USER3}
    Project Should Be Listed    project_title=${PRJ_2_USER3}
    Project Should Be Listed    project_title=${PRJ_A_USER4}
    Launch Data Science Project Main Page    username=${OCP_ADMIN_USER.USERNAME}    password=${OCP_ADMIN_USER.PASSWORD}
    ...    ocp_user_auth_type=${OCP_ADMIN_USER.AUTH_TYPE}
    Capture Page Screenshot
    Number Of Displayed Projects Should Be    expected_number=3
    Project Should Be Listed    project_title=${PRJ_1_USER3}
    Project Should Be Listed    project_title=${PRJ_2_USER3}
    Project Should Be Listed    project_title=${PRJ_A_USER4}

Verify User Can Create A Data Science Project
    [Tags]    Smoke    Sanity    ODS-1775
    [Documentation]    Verifies users can create a DS project
    [Setup]   Launch Data Science Project Main Page
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    resource_name=${PRJ_RESOURCE_NAME}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_TITLE}
    Project's Owner Should Be   expected_username=${TEST_USER_3.USERNAME}   project_title=${PRJ_TITLE}
    ${ns_name}=    Check Corresponding Namespace Exists    project_title=${PRJ_TITLE}

Verify User Can Edit A Data Science Project
    [Tags]    Sanity    Tier1    ODS-2112
    [Documentation]    Verifies users can edit a DS project
    [Setup]   Launch Data Science Project Main Page
    [Teardown]    Delete Data Science Project    project_title=${NEW_PRJ_TITLE}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE1}    description=${PRJ_DESCRIPTION}
    ...    resource_name=${NONE}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE1}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_TITLE1}
    Run Keyword And Continue On Failure         Check Resource Name Should Be Immutable    project_title=${PRJ_TITLE1}
    Run Keyword And Continue On Failure         Check Name And Description Should Be Editable
    ...    project_title=${PRJ_TITLE1}    new_title=${NEW_PRJ_TITLE}    new_description=${NEW_PRJ_DESCRIPTION}
    ${ns_newname}=    Get Openshift Namespace From Data Science Project   project_title=${NEW_PRJ_TITLE}
    Should Be Equal As Strings  ${ns_name}  ${ns_newname}


Verify User Can Create And Start A Workbench With Ephemeral Storage
    [Tags]    ODS-1812
    [Documentation]    Verifies users can create workbench using Ephemeral storage
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.20.0
    IF  ${version_check}==True
        Skip     msg=Skipping because ODS-1812 is not applicable to version >= 1.20.0
    END
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${EMPTY}  workbench_description=${EMPTY}  prj_title=${PRJ_TITLE}
    ...                 image_name=${NB_IMAGE}   deployment_size=Small  storage=Ephemeral  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}  press_cancel=${TRUE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE}  workbench_description=${WORKBENCH_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Ephemeral  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}
    Workbench Should Be Listed      workbench_title=${WORKBENCH_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE}
    Check Corresponding Notebook CR Exists      workbench_title=${WORKBENCH_TITLE}   namespace=${ns_name}

Verify User Can Create And Start A Workbench With Existent PV Storage
    [Tags]    Smoke    Sanity    ODS-1814
    [Documentation]    Verifies users can create a workbench and connect an existent PersistenVolume
    ${pv_name}=    Set Variable    ${PV_BASENAME}-existent
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create PersistentVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${NONE}    project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_2_TITLE}  workbench_description=${WORKBENCH_2_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_existent=${TRUE}    pv_name=${pv_name}  pv_description=${NONE}  pv_size=${NONE}
    Workbench Should Be Listed      workbench_title=${WORKBENCH_2_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_2_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_2_TITLE}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Check Corresponding Notebook CR Exists      workbench_title=${WORKBENCH_2_TITLE}   namespace=${ns_name}

Verify User Can Create A PV Storage
    [Tags]    Sanity    Tier1    ODS-1819
    [Documentation]    Verifies users can Create PersistentVolume Storage
    ${pv_name}=    Set Variable    ${PV_BASENAME}-A
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    ${workbenches}=    Create Dictionary    ${WORKBENCH_2_TITLE}=mount-data
    Create PersistentVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${NONE}     press_cancel=${TRUE}
    ...                               project_title=${PRJ_TITLE}
    Create PersistentVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${workbenches}   project_title=${PRJ_TITLE}
    Storage Should Be Listed    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                         type=Persistent storage    connected_workbench=${workbenches}
    Check Corresponding PersistentVolumeClaim Exists    storage_name=${pv_name}    namespace=${ns_name}
    Storage Size Should Be    name=${pv_name}    namespace=${ns_name}  size=${PV_SIZE}

Verify User Can Create And Start A Workbench Adding A New PV Storage
    [Tags]    Smoke    Sanity    ODS-1816
    [Documentation]    Verifies users can create a workbench and connect a new PersistenVolume
    ${pv_name}=    Set Variable    ${PV_BASENAME}-new
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_3_TITLE}  workbench_description=${WORKBENCH_3_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_existent=${FALSE}
    ...                 pv_name=${pv_name}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    Workbench Should Be Listed      workbench_title=${WORKBENCH_3_TITLE}
    Reload Page
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_3_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_3_TITLE}
    Check Corresponding Notebook CR Exists      workbench_title=${WORKBENCH_3_TITLE}   namespace=${ns_name}
    Reload Page
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    ${connected_woksps}=    Create List    ${WORKBENCH_3_TITLE}
    Storage Should Be Listed    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                         type=Persistent storage    connected_workbench=${connected_woksps}
    Storage Size Should Be    name=${pv_name}    namespace=${ns_name}  size=${PV_SIZE}

Verify User Can Stop A Workbench
    [Tags]    Smoke    Sanity    ODS-1817
    [Documentation]    Verifies users can stop a running workbench from project details page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Stop Workbench    workbench_title=${WORKBENCH_3_TITLE}    press_cancel=${TRUE}
    Stop Workbench    workbench_title=${WORKBENCH_3_TITLE}
    # add checks on notebook pod is terminated but CR is present

Verify User Can Launch A Workbench
    [Tags]    Smoke    Sanity    ODS-1815
    [Documentation]    Verifies users can launch/open a running workbench from project details page
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Start Workbench     workbench_title=${WORKBENCH_2_TITLE}
    Launch And Access Workbench    workbench_title=${WORKBENCH_2_TITLE}
    ...    username=${TEST_USER_3.USERNAME}     password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}
    Check Launched Workbench Is The Correct One     workbench_title=${WORKBENCH_2_TITLE}
    ...    image=${NB_IMAGE}    namespace=${ns_name}

Verify User Can Create A S3 Data Connection And Connect It To Workbenches
    [Tags]    Sanity    Tier1
    ...       ODS-1825    ODS-1972
    [Documentation]    Verifies users can add a Data connection to AWS S3
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}
    ...                          aws_access_key=${DC_S3_AWS_SECRET_ACCESS_KEY}
    ...                          aws_secret_access=${DC_S3_AWS_SECRET_ACCESS_KEY}
    ...                          aws_s3_endpoint=${DC_S3_ENDPOINT}    aws_region=${DC_S3_REGION}
    Data Connection Should Be Listed    name=${DC_S3_NAME}    type=${DC_S3_TYPE}    connected_workbench=${NONE}
    Check Corresponding Data Connection Secret Exists    dc_name=${DC_S3_NAME}    namespace=${ns_name}
    ${workbenches}=    Create List    ${WORKBENCH_2_TITLE}    ${WORKBENCH_3_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_2_S3_NAME}
    ...                          aws_access_key=${DC_S3_AWS_SECRET_ACCESS_KEY}
    ...                          aws_secret_access=${DC_S3_AWS_SECRET_ACCESS_KEY}
    ...                          aws_s3_endpoint=${DC_S3_ENDPOINT}    aws_region=${DC_S3_REGION}
    ...                          connected_workbench=${workbenches}
    Data Connection Should Be Listed    name=${DC_2_S3_NAME}    type=${DC_S3_TYPE}    connected_workbench=${workbenches}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_2_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_3_TITLE}      status=${WORKBENCH_STATUS_STOPPED}

Verify User Can Stop A Workbench From Projects Home Page
    [Tags]    Sanity    Tier1    ODS-1823
    [Documentation]    Verifies users can stop a running workbench from Data Science Projects home page
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    ${_}    ${workbench_cr_name}=    Get Openshift Notebook CR From Workbench    workbench_title=${WORKBENCH_2_TITLE}
    ...    namespace=${ns_name}
    Stop Workbench From Projects Home Page     workbench_title=${WORKBENCH_2_TITLE}   project_title=${PRJ_TITLE}
    ...    workbench_cr_name=${workbench_cr_name}    namespace=${ns_name}
    Workbench Launch Link Should Be Disabled    workbench_title=${WORKBENCH_2_TITLE}  project_title=${PRJ_TITLE}
    # add checks on notebook pod is terminated but CR is present

Verify User Can Start And Launch A Workbench From Projects Home Page
    [Tags]    Sanity    Tier1    ODS-1818
    [Documentation]    Verifies users can launch/open a running workbench from Data Science Projects home page
    Open Data Science Projects Home Page
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    ${_}    ${workbench_cr_name}=    Get Openshift Notebook CR From Workbench    workbench_title=${WORKBENCH_2_TITLE}
    ...    namespace=${ns_name}
    Start Workbench From Projects Home Page     workbench_title=${WORKBENCH_2_TITLE}   project_title=${PRJ_TITLE}
    ...    workbench_cr_name=${workbench_cr_name}    namespace=${ns_name}
    Launch And Access Workbench From Projects Home Page    workbench_title=${WORKBENCH_2_TITLE}
    ...    project_title=${PRJ_TITLE}    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}    auth_type=${TEST_USER_3.AUTH_TYPE}
    Check Launched Workbench Is The Correct One     workbench_title=${WORKBENCH_2_TITLE}
    ...    image=${NB_IMAGE}    namespace=${ns_name}

Verify User Can Delete A Workbench
    [Tags]    Smoke    Sanity    ODS-1813
    [Documentation]    Verifies users can delete a workbench
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Delete Workbench    workbench_title=${WORKBENCH_2_TITLE}    press_cancel=${TRUE}
    Delete Workbench    workbench_title=${WORKBENCH_2_TITLE}
    Workbench Should Not Be Listed    workbench_title=${WORKBENCH_2_TITLE}
    Check Workbench CR Is Deleted    workbench_title=${WORKBENCH_2_TITLE}   namespace=${ns_name}

Verify User Can Delete A Persistent Storage
    [Tags]    Sanity    Tier1    ODS-1824
    [Documentation]    Verifies users can delete a PersistenVolume
    ${pv_name}=    Set Variable    ${PV_BASENAME}-TO-DELETE
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create PersistentVolume Storage    name=${pv_name}    description=${PV_DESCRIPTION}
    ...                               size=${PV_SIZE}    connected_workbench=${NONE}   project_title=${PRJ_TITLE}
    Delete Storage    name=${pv_name}    press_cancel=${TRUE}
    Delete Storage    name=${pv_name}    press_cancel=${FALSE}
    Storage Should Not Be Listed    name=${pv_name}
    Check Storage PersistentVolumeClaim Is Deleted    storage_name=${pv_name}    namespace=${ns_name}

Verify User Can Delete A Data Connection
    [Tags]    Sanity    Tier1    ODS-1826
    [Documentation]    Verifies users can delete a Data connection
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Delete Data Connection    name=${DC_S3_NAME}   press_cancel=${True}
    Delete Data Connection    name=${DC_S3_NAME}
    Data Connection Should Not Be Listed    name=${DC_S3_NAME}
    Check Data Connection Secret Is Deleted    dc_name=${DC_S3_NAME}    namespace=${ns_name}

Verify User Can Create A Workbench With Environment Variables
    [Tags]    Sanity    Tier1    ODS-1864
    [Documentation]    Verifies users can create a workbench and inject environment variables during creation
    ${pv_name}=    Set Variable    ${PV_BASENAME}-existent
    ${envs_var_secrets}=    Create Dictionary    secretA=TestVarA   secretB=TestVarB
    ...    k8s_type=Secret  input_type=${KEYVALUE_TYPE}
    ${envs_var_cm}=         Create Dictionary    cmA=TestVarA-CM   cmB=TestVarB-CM
    ...    k8s_type=Config Map  input_type=${KEYVALUE_TYPE}
    ${envs_list}=    Create List   ${envs_var_secrets}     ${envs_var_cm}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_4_TITLE}  workbench_description=${WORKBENCH_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_name=${NONE}  pv_existent=${NONE}
    ...                 pv_description=${NONE}  pv_size=${NONE}
    ...                 press_cancel=${FALSE}    envs=${envs_list}
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_4_TITLE}
    Launch And Access Workbench    workbench_title=${WORKBENCH_4_TITLE}
    ...    username=${TEST_USER_3.USERNAME}     password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}
    Environment Variables Should Be Available In Jupyter    exp_env_variables=${envs_list}

Verify User Can Create Environment Variables By Uploading YAML Secret/ConfigMap
    [Tags]    Tier1    Sanity
    ...       ODS-1883
    [Documentation]    Verify user can set environment varibles in their workbenches by
    ...                uploading a yaml Secret or Config Map file.
    ...                ProductBug: RHODS-8249
    ${envs_var_secret}=    Create Dictionary    filepath=${ENV_SECRET_FILEPATH}
    ...    k8s_type=Secret  input_type=${UPLOAD_TYPE}
    ${envs_var_cm}=    Create Dictionary    filepath=${ENV_CM_FILEPATH}
    ...    k8s_type=Config Map  input_type=${UPLOAD_TYPE}
    ${envs_list}=    Create List   ${envs_var_secret}     ${envs_var_cm}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Delete Workbench    workbench_title=${WORKBENCH_4_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_4_TITLE}  workbench_description=${WORKBENCH_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_name=${WORKBENCH_4_TITLE}-PV  pv_existent=${FALSE}
    ...                 pv_description=${NONE}  pv_size=${2}
    ...                 press_cancel=${FALSE}    envs=${envs_list}
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_4_TITLE}
    ${test_envs_var_secret}=    Create Dictionary    FAKE_ID=hello-id
    ...    FAKE_VALUE=hello-value    input_type=Secret
    ${test_envs_var_cm}=    Create Dictionary    MY_VAR1=myvalue1
    ...    MY_VAR2=myvalue2    input_type=Config Map
    ${test_envs_list}=    Create List   ${test_envs_var_secret}     ${test_envs_var_cm}
    Environment Variables Should Be Displayed According To Their Type
    ...    workbench_title=${WORKBENCH_4_TITLE}    exp_env_variables=${test_envs_list}
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_4_TITLE}
    Launch And Access Workbench    workbench_title=${WORKBENCH_4_TITLE}
    ...    username=${TEST_USER_3.USERNAME}     password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}
    Environment Variables Should Be Available In Jupyter    exp_env_variables=${test_envs_list}

Verify User Can Log Out And Return To Project From Jupyter Notebook    # robocop: disable
    [Tags]    Sanity    Tier1    ODS-1971    AutomationBug
    [Documentation]    Verifies user can log out and return to the project from Jupyter notebook.
    ...                Users have 2 options:
    ...                1. click "File" > "Log Out" to actually close the login session
    ...                2. click "File" > "Hub Control Panel" to return to project details page
    ...                AutomationBug: JupyterLibrary's log out keyword seems to be broken
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Open Workbench    workbench_title=${WORKBENCH_4_TITLE}
    Run Keyword And Continue On Failure
    ...    Log In Should Be Requested
    Access To Workbench    username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}
    Open JupyterLab Control Panel
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_4_TITLE}
    ...    status=${WORKBENCH_STATUS_RUNNING}
    Open Workbench    workbench_title=${WORKBENCH_4_TITLE}
    Run Keyword And Continue On Failure
    ...    Log In Should Not Be Requested
    Wait Until JupyterLab Is Loaded
    Logout JupyterLab
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_4_TITLE}
    ...    status=${WORKBENCH_STATUS_RUNNING}
    Open Workbench    workbench_title=${WORKBENCH_4_TITLE}
    Run Keyword And Continue On Failure
    ...    Log In Should Be Requested

Verify Event Log Is Accessible While Starting A Workbench
    [Tags]    Tier1    Sanity
    ...       ODS-1970
    [Documentation]    Verify user can access event log while starting a workbench
    [Teardown]    Delete Workbench    workbench_title=${WORKBENCH_6_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_6_TITLE}  workbench_description=${WORKBENCH_6_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_name=${NONE}  pv_existent=${NONE}
    ...                 pv_description=${NONE}  pv_size=${NONE}
    ...                 press_cancel=${FALSE}    envs=${NONE}
    Workbench Status Should Be    workbench_title=${WORKBENCH_6_TITLE}
    ...    status=${WORKBENCH_STATUS_STARTING}
    Open Notebook Event Log    workbench_title=${WORKBENCH_6_TITLE}
    Page Should Contain Event Log
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_6_TITLE}
    # In 1.31 the progress does not appear to be displayed correctly, instead it moves from 0% to 100% directly
    # Needs more investigation
    Run Keyword And Warn On Failure    Page Should Contain Event Log    expected_progress_text=Pod assigned
    ...    expected_result_text=Success
    Close Event Log
    Wait Until Project Is Open    project_title=${PRJ_TITLE}

Verify Error Is Reported When Workbench Fails To Start    # robocop: disable
    [Tags]    Tier1    Sanity
    ...       ODS-1973
    ...       AutomationBug
    [Documentation]    Verify UI informs users about workbenches failed to start.
    ...                At the moment the test is considering only the scenario where
    ...                the workbench fails for Insufficient resources.
    [Teardown]    Delete Workbench    workbench_title=${WORKBENCH_5_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_5_TITLE}  workbench_description=${WORKBENCH_5_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=X Large
    ...                 storage=Persistent  pv_name=${NONE}  pv_existent=${NONE}
    ...                 pv_description=${NONE}  pv_size=${NONE}
    ...                 press_cancel=${FALSE}    envs=${NONE}
    Workbench Status Should Be    workbench_title=${WORKBENCH_5_TITLE}
    ...    status=${WORKBENCH_STATUS_STARTING}
    Start Workbench Should Fail    workbench_title=${WORKBENCH_5_TITLE}
    Open Notebook Event Log    workbench_title=${WORKBENCH_5_TITLE}
    ...    exp_preview_text=Insufficient
    Event Log Should Report The Failure    exp_progress_text=Insufficient resources to start
    ...    exp_result_text=FailedScheduling
    Close Event Log
    Wait Until Project Is Open    project_title=${PRJ_TITLE}

Verify User Can Delete A Data Science Project
    [Tags]    Smoke    Sanity    ODS-1784
    [Documentation]    Verifies users can delete a Data Science project
    Delete Data Science Project   project_title=${PRJ_TITLE}
    # check workbenches and resources get deleted too

Verify User Can Edit A S3 Data Connection
    [Tags]    Sanity    Tier1    ODS-1932
    [Documentation]    Verifies users can add a Data connection to AWS S3
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    resource_name=${PRJ_RESOURCE_NAME}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}
    ...                          aws_access_key=${DC_S3_AWS_SECRET_ACCESS_KEY}
    ...                          aws_secret_access=${DC_S3_AWS_SECRET_ACCESS_KEY}
    ...                          aws_s3_endpoint=${DC_S3_ENDPOINT}    aws_region=${DC_S3_REGION}
    Edit S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}-test    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}-test
    ...            aws_bucket_name=ods-ci-ds-pipelines-test    aws_region=${DC_S3_REGION}
    ...            aws_s3_endpoint=${DC_S3_ENDPOINT}
    ${s3_name}    ${s3_key}    ${s3_secret}    ${s3_endpoint}    ${s3_region}    ${s3_bucket}    Get Data Connection Form Values    ${DC_S3_NAME}
    Should Be Equal  ${s3_name}  ${DC_S3_NAME}
    Should Be Equal  ${s3_key}  ${S3.AWS_ACCESS_KEY_ID}-test
    Should Be Equal  ${s3_secret}  ${S3.AWS_SECRET_ACCESS_KEY}-test
    Should Be Equal  ${s3_endpoint}  ${DC_S3_ENDPOINT}
    Should Be Equal  ${s3_region}  ${DC_S3_REGION}
    Should Be Equal  ${s3_bucket}  ods-ci-ds-pipelines-test

*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing DS Projects. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    # Delete All Data Science Projects From CLI
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown

Set Variables For User Access Test
    [Documentation]    Creates titles for testing projects used in basic access testing
    Set Suite Variable    ${PRJ_1_USER3}    ${PRJ_TITLE}-${TEST_USER_3.USERNAME}-#1
    Set Suite Variable    ${PRJ_2_USER3}    ${PRJ_TITLE}-${TEST_USER_3.USERNAME}-#2
    Set Suite Variable    ${PRJ_A_USER4}    ${PRJ_TITLE}-${TEST_USER_4.USERNAME}-#A
    Append To List    ${PROJECTS_TO_DELETE}    ${PRJ_1_USER3}    ${PRJ_2_USER3}    ${PRJ_A_USER4}

Create Project With Empty Title And Expect Error
    [Documentation]    Tries to create a DS project with emtpy title and checks the Selenium error
    ${error_rgx}=   Set Variable    Element[ a-zA-Z=\(\)\[\]"'\/\s]+was not enabled[ a-zA-Z=\(\)\[\]"'\/\s0-9.]+
    Run Keyword And Expect Error    Element*was not enabled*
    ...    Create Data Science Project    title=${EMPTY}  description=${EMPTY}

Create Project With Special Chars In Resource Name And Expect Error
    [Documentation]    Tries to create a DS project by overwriting the resource name
    ...                with a custom one containing special characters, and checks the Selenium error
    ${error_rgx}=   Set Variable    Element[ a-zA-Z=\(\)\[\]"'\/\s]+was not enabled[ a-zA-Z=\(\)\[\]"'\/\s0-9.]+
    Run Keyword And Expect Error    Element*was not enabled*
    ...    Create Data Science Project    title=${PRJ_TITLE}-spec-chars
    ...    description=${EMPTY}    resource_name=ods-ci-@-project#name

Check Corresponding Namespace Exists
    [Documentation]    Checks if a DS Project has its own corresponding Openshift namespace
    [Arguments]     ${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    Oc Get      kind=Project    name=${ns_name}
    RETURN    ${ns_name}

Check Corresponding Notebook CR Exists
    [Documentation]    Checks if a workbench has its own Notebook CustomResource
    [Arguments]     ${workbench_title}  ${namespace}
    ${res}  ${response}=    Get Openshift Notebook CR From Workbench   workbench_title=${workbench_title}
    ...    namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=Notebook CR not found for ${workbench_title} in ${namespace} NS
    END

Check Workbench CR Is Deleted
    [Documentation]    Checks if when a workbench is deleted its Notebook CustomResource gets deleted too
    [Arguments]    ${workbench_title}   ${namespace}    ${timeout}=10s
    ${status}=      Run Keyword And Return Status    Check Corresponding Notebook CR Exists
    ...    workbench_title=${workbench_title}   namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The notebook CR for ${workbench_title} is still present, while it should have been deleted.
    END

Check Corresponding Data Connection Secret Exists
    [Documentation]    Checks if a S3 Data Connection has its corresponding Openshift Secret
    [Arguments]     ${dc_name}  ${namespace}
    ${res}  ${response}=    Get Openshift Secret From Data Connection   dc_name=${dc_name}  namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=Secret not found for ${dc_name} in ${namespace} NS
    END

Check Data Connection Secret Is Deleted
    [Documentation]    Checks if when a S3 Data Connection is deleted its Openshift Secret gets deleted too
    [Arguments]    ${dc_name}   ${namespace}    ${timeout}=10s
    ${status}=      Run Keyword And Return Status    Check Corresponding Data Connection Secret Exists
    ...    dc_name=${dc_name}    namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The secret for ${dc_name} data connection is still present, while it should have been deleted.
    END

Check Corresponding PersistentVolumeClaim Exists
    [Documentation]    Checks if a PV cluster storage has its corresponding Openshift PersistentVolumeClaim
    [Arguments]     ${storage_name}  ${namespace}
    ${res}  ${response}=    Get Openshift PVC From Storage   name=${storage_name}  namespace=${namespace}
    IF    "${response}" == "${EMPTY}"
        Run Keyword And Continue On Failure    Fail    msg=PVC not found for ${storage_name} in ${namespace} NS
    END

Check Storage PersistentVolumeClaim Is Deleted
    [Documentation]    Checks if when a PV cluster storage is deleted its Openshift PersistentVolumeClaim gets deleted too
    [Arguments]    ${storage_name}   ${namespace}    ${timeout}=10s
    ${status}=      Run Keyword And Return Status    Check Corresponding PersistentVolumeClaim Exists
    ...    storage_name=${storage_name}    namespace=${namespace}
    IF    ${status} == ${TRUE}
        Fail    msg=The PVC for ${storage_name} storage is still present, while it should have been deleted.
    END

Environment Variables Should Be Available In Jupyter
    [Documentation]    Runs code in JupyterLab to check if the expected environment variables are available
    [Arguments]    ${exp_env_variables}
    Open With JupyterLab Menu  File  New  Notebook
    Sleep  1s
    Maybe Close Popup
    Maybe Select Kernel
    Sleep   3s
    # Add And Run JupyterLab Code Cell In Active Notebook    import os
    FOR    ${idx}   ${env_variable_dict}    IN ENUMERATE    @{exp_env_variables}
        Remove From Dictionary    ${env_variable_dict}     k8s_type    input_type
        ${n_pairs}=    Get Length    ${env_variable_dict.keys()}
        FOR  ${pair_idx}   ${key}  ${value}  IN ENUMERATE  &{env_variable_dict}
            Log   ${pair_idx}-${key}-${value}
            Run Keyword And Continue On Failure     Run Cell And Check Output    import os;print(os.environ["${key}"])    ${value}
            Capture Page Screenshot
        END
    END
    Open With JupyterLab Menu    Edit    Select All Cells
    Open With JupyterLab Menu    Edit    Delete Cells

Environment Variables Should Be Displayed According To Their Type
    [Documentation]    Checks if the enviornment variables are displayed according
    ...                to their types (i.e., Secret vs ConfigMap) after their creation.
    ...                It goes to "Edit workbench" page and compare the environment variables
    ...                settings with the ones which were inserted during workbench creation.
    [Arguments]    ${workbench_title}    ${exp_env_variables}
    Click Action From Actions Menu    item_title=${workbench_title}    item_type=workbench    action=Edit
    # Broken in 1.33 RC1
    # Click Element    xpath://a[@href="#environment-variables"]
    Execute Javascript    document.getElementsByClassName("pf-c-drawer__content")[1].scrollBy(0,500)
    Sleep   2s
    FOR    ${idx}   ${env_variable_dict}    IN ENUMERATE    @{exp_env_variables}    start=1
        ${n_pairs}=    Get Length    ${env_variable_dict.keys()}
        ${input_type}=    Set Variable    ${env_variable_dict}[input_type]
        Remove From Dictionary    ${env_variable_dict}     input_type
        Environment Variable Type Should Be    expected_type=${input_type}    var_idx=${idx}
        FOR  ${pair_idx}   ${key}  ${value}  IN ENUMERATE  &{env_variable_dict}
            Log   ${pair_idx}-${key}-${value}
            Environment Variable Key/Value Fields Should Be Correctly Displayed    var_idx=${idx}    var_pair_idx=${pair_idx}
            ...    expected_key=${key}    expected_value=${value}    type=${input_type}
        END
    END
    Click Button    ${GENERIC_CANCEL_BTN_XP}
    Capture Page Screenshot

Environment Variable Type Should Be
    [Arguments]    ${expected_type}    ${var_idx}
    ${displayed_type}=    Get Text    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${var_idx}]//div[contains(@class,"pf-c-select")]/button//span[contains(@class,'toggle-text')]
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${displayed_type}    ${expected_type}

Environment Variable Key/Value Fields Should Be Correctly Displayed
    [Arguments]    ${var_idx}    ${var_pair_idx}    ${expected_key}    ${expected_value}    ${type}
    ${displayed_value_xp}=    Set Variable    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${var_idx}]//input[@aria-label="value of item ${var_pair_idx}"]
    ${displayed_key_xp}=    Set Variable    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${var_idx}]//input[@aria-label="key of item ${var_pair_idx}"]
    ${displayed_key}=    Get Value    ${displayed_key_xp}
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${displayed_key}    ${expected_key}
    ${displayed_val}=    Get Value    ${displayed_value_xp}
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${displayed_val}    ${expected_value}
    IF    "${type}" == "Secret"
        Run Keyword And Continue On Failure    Element Attribute Value Should Be    ${displayed_value_xp}    type    password
    ELSE
        Run Keyword And Continue On Failure    Element Attribute Value Should Be    ${displayed_value_xp}    type    text
    END

Create Multiple Data Science Projects
    [Documentation]    Create a given number of data science projects based on title and description
    [Arguments]    ${title}     ${description}    ${number}
    ${all_projects}=    Create List
    FOR    ${counter}    IN RANGE    1    ${number}+1    1
        Create Data Science Project    title=${title}${counter}    description=${EMPTY}
        Open Data Science Projects Home Page
        Append To List    ${all_projects}    ${title}${counter}
    END
    RETURN    ${all_projects}

Delete Multiple Data Science Projects
    [Arguments]    ${title}     ${number}
    FOR    ${counter}    IN RANGE    1    ${number}+1    1
        ${rc}  ${output}=    Run And Return Rc And Output    oc delete project ${title}${counter}
    END

Check Name And Description Should Be Editable
    [Documentation]    Checks and verifies if the DSG Name and Description is editable
    [Arguments]    ${project_title}     ${new_title}    ${new_description}
    Update Data Science Project Name    ${project_title}     ${new_title}
    Update Data Science Project Description    ${new_title}    ${new_description}
    Open Data Science Project Details Page       project_title=${new_title}
    Page Should Contain    ${new_description}
