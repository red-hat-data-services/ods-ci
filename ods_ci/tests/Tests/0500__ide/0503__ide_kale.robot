*** Settings ***
Documentation    Test Suite for Kale pipelines in workbenches
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/Kale.resource
Resource         ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Storages.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Pipelines.resource
Resource         ../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesBackend.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Library          Screenshot
Library          String
Library          DebugLibrary
Library          JupyterLibrary
Test Tags        DataSciencePipelines-IDE
Suite Setup      Kale Pipelines Suite Setup
Suite Teardown   Kale Pipelines Suite Teardown


*** Variables ***
${NOTEBOOKS_REPO_URL} =    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main
${KALE_NOTEBOOK_PATH} =    ods-ci-notebooks-main/notebooks/500__jupyterhub/pipelines/v2/kale/candies_sharing.ipynb
${PRJ_TITLE} =    kale-test
${PRJ_DESCRIPTION} =    testing Kale pipeline functionality
${PV_NAME} =    ods-ci-pv-kale
${PV_DESCRIPTION} =    ods-ci-pv-kale is a PV created to test Kale in workbenches
${PV_SIZE} =    2
${ENVS_LIST} =    ${NONE}
${DC_NAME} =    kale-s3


*** Test Cases ***
Verify Pipelines Integration With Kale When Using Standard Data Science Image
    [Documentation]    Verifies that a workbench using the Jupyter | Data Science | CPU | Python 3.12 Image can be used to
    ...    compile and run a Kale pipeline from an annotated notebook
    [Tags]    Smoke
    [Timeout]    25m
    Verify Pipelines Integration With Kale Running Candies Pipeline Test
    ...    img=Jupyter | Data Science | CPU | Python 3.12
    ...    pipeline_name=standard-data-science-candies-pipeline
    ...    workbench_timeout=600s

Verify Pipelines Integration With Kale When Using Standard Data Science Based Images
    [Documentation]    Verifies that a workbench using an image based on the Jupyter | Data Science | CPU | Python 3.12 Image
    ...    can be used to compile and run a Kale pipeline from an annotated notebook
    ...    Note: Kale must be installed in the workbench image under test
    ...    Note: this is a templated test case
    ...    (more info at https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#test-templates)
    [Template]    Verify Pipelines Integration With Kale Running Candies Pipeline Test
    [Tags]    Tier1
    [Timeout]    40m
    Jupyter | PyTorch | CUDA | Python 3.12       pytorch-candies-pipeline      600s
    Jupyter | TensorFlow | CUDA | Python 3.12    tensorflow-candies-pipeline   600s
    Jupyter | TrustyAI | CPU | Python 3.12       trustyai-candies-pipeline     600s


*** Keywords ***
Kale Pipelines Suite Setup    # robocop: off=too-many-calls-in-keyword
    [Documentation]    Suite Setup — mirrors Elyra (CLI project create + pipeline server)
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Set Suite Variable    ${USERNAME}    ${TEST_USER_3.USERNAME}
    Set Suite Variable    ${PASSWORD}    ${TEST_USER_3.PASSWORD}
    Launch Data Science Project Main Page    username=${USERNAME}    password=${PASSWORD}
    ${project_name_complete}=    Create Data Science Project From CLI    name=${PRJ_TITLE}
    ...    description=${PRJ_DESCRIPTION}    randomize_name=${TRUE}    as_user=${USERNAME}
    Set Suite Variable    ${PRJ_TITLE}            ${project_name_complete}
    Set Suite Variable    ${PROJECT_TO_DELETE}    ${project_name_complete}
    Ensure Kale Project Can Pull Red Hat Images    ${PRJ_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-ds-pipelines
    Pipelines.Create Pipeline Server    dc_name=${DC_NAME}
    ...    project_title=${PRJ_TITLE}
    # Optional: set KALE_PATCH_PIPELINE_IMAGES=${TRUE} plus PIPELINE_*_IMAGE vars to override DSPA images.
    ${patch_pipeline_images}=    Get Variable Value    ${KALE_PATCH_PIPELINE_IMAGES}    ${FALSE}
    IF    ${patch_pipeline_images}
        Maybe Patch Kale Pipeline Server Images    ${PRJ_TITLE}
    END
    Wait Until Kale Pipeline Server Is Deployed    namespace=${PRJ_TITLE}
    Sleep    15s    reason=Wait until pipeline server is detected by dashboard

Kale Pipelines Suite Teardown
    [Documentation]    Closes the browser and deletes the test project
    Delete Project Via CLI By Display Name    displayed_name=${PROJECT_TO_DELETE}
    Close All Browsers

Verify Pipelines Integration With Kale Running Candies Pipeline Test     # robocop: off=too-many-calls-in-keyword
    [Documentation]    Creates and starts a workbench using ${img}, opens the candies_sharing Kale sample notebook,
    ...    compiles and runs the pipeline, then verifies the run completes in the dashboard
    [Arguments]    ${img}    ${pipeline_name}    ${workbench_timeout}=600s
    ${skip_workbench_version_check}=    Get Variable Value    ${SKIP_WORKBENCH_VERSION_CHECK}    ${FALSE}
    ${kale_workbench_image_version}=    Get Variable Value    ${KALE_WORKBENCH_IMAGE_VERSION}    ${NONE}
    # SKIP_WORKBENCH_VERSION_CHECK=${TRUE} skips the default/previous version dropdown assert
    # (needed when the UI only lists a single tag, e.g. latest-only clusters).
    ${workbench_image_version}=    Set Variable If    ${skip_workbench_version_check}    ${NONE}    default
    Create Kale Workbench    workbench_title=kale_${img}    workbench_description=Kale test
    ...                 prj_title=${PRJ_TITLE}    image_name=${img}    hardware_profile=default-profile
    ...                 storage=Persistent  pv_existent=${FALSE}    version=${workbench_image_version}
    ...                 pv_name=${PV_NAME}_${img}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    ...                 envs=${ENVS_LIST}
    # Patch before Start so the first pull uses the Kale tag (UI version picker may not list it).
    IF    '${kale_workbench_image_version}' != '${NONE}'
        Patch Workbench Notebook Image Tag Via CLI    workbench_title=kale_${img}
        ...    project_title=${PRJ_TITLE}    image_tag=${kale_workbench_image_version}
    END
    Start Workbench     workbench_title=kale_${img}    timeout=${workbench_timeout}
    ${dashboard_window}=    Launch And Access Workbench    workbench_title=kale_${img}
    Clone Git Repository And Open    ${NOTEBOOKS_REPO_URL}    ${KALE_NOTEBOOK_PATH}  # robocop: disable
    # Some images have Kale installed but its JupyterLab extension disabled by default
    Enable Kale Extension    notebook_path=${KALE_NOTEBOOK_PATH}
    ...    workbench_title=kale_${img}    project_title=${PRJ_TITLE}
    Verify Kale Notebook Elements
    Open Kale Panel
    Enable Kale
    Compile And Run Kale Pipeline    pipeline_name=${pipeline_name}
    # Workbench opens in a new browser tab; dashboard menu navigation needs the original tab.
    Switch Window    ${dashboard_window}
    # Same project-selector caveat as Elyra: sticky state may point at another project.
    Menu.Navigate To Page    Develop & train    Pipelines    Runs
    Select Kale Pipeline Project By Name    ${PRJ_TITLE}
    Verify Kale Pipeline Run Is Completed    pipeline_name=${pipeline_name}
    [Teardown]    Verify Pipelines Integration With Kale Teardown    ${img}

Verify Pipelines Integration With Kale Teardown
    [Documentation]    Closes all browsers and stops the running workbench
    [Arguments]    ${img}
    Close All Browsers
    Launch Data Science Project Main Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}    tab_id=workbenches
    Stop Workbench    workbench_title=kale_${img}
