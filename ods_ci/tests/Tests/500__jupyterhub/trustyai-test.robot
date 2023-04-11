*** Settings ***
Documentation    Test Suite for TrustyAI image
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Resource         ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Library          Screenshot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Verify TrustyAI Image Suite Setup
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
${NOTEBOOK_IMAGE} =         odh-trustyai-notebook
${EXPECTED_CUDA_VERSION} =  12.0


*** Test Cases ***
Verify TrustyAI Image Can Be Spawned
    [Documentation]    Spawns trustyAI image
    [Tags]  Sanity
    ...     PLACEHOLDER  # Category tags
    #...     ODS-1155
    Pass Execution    Passing tests, as suite setup ensures that image can be spawned

TrustyAI Workload Test
    [Documentation]    Runs tensorflow workload
    [Tags]  Sanity
    ...     PLACEHOLDER  # category tags
    #...     ODS-1156
    Run Repo And Clean  https://github.com/trustyai-explainability/trustyai-explainability-python-examples
    ...   trustyai-explainability-python-examples/examples/SHAP.ipynb
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible


#Verify TrustyAI Is Accessible
#    [Documentation]  Verifies that TrustyAI is accessible
#    [Tags]  Sanity
#    ...     PLACEHOLDER
#    #...     ODS-1413
#    Close Previous Server
#    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small
#    Run Keyword And Ignore Error  Clone Git Repository And Run  https://github.com/redhat-rhods-qe/ods-ci-notebooks-main
#    ...    ods-ci-notebooks-main/notebooks/500__jupyterhub/tensorboard/tensorflow/tensorboard_profiling_tensorflow.ipynb  10m
#    Select Frame    xpath://iframe[contains(@id, "tensorboard-frame")]
#    Page Should Contain Element    xpath://html//mat-toolbar/span[.="TensorBoard"]
#    Unselect Frame

Verify TrustyAI Image Can Be Spawned With GPU
    [Documentation]    Spawns PyTorch image with 1 GPU
    [Tags]  Sanity
    ...     Resources-GPU
    #...     ODS-1151
    Close Previous Server
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small  gpus=1

Verify Tensorflow Library Can See GPUs In Tensorflow Image
    [Documentation]    Verifies Tensorlow can see the GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1153
    Verify Tensorflow Can See GPU

#Verify Tensorflow Image GPU Workload
#    [Documentation]  Runs a workload on GPUs in Tensorflow image
#    [Tags]  Sanity
#    ...     Resources-GPU
#    ...     ODS-1154
#    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb
#    JupyterLab Code Cell Error Output Should Not Be Visible


*** Keywords ***
Verify TrustyAI Image Suite Setup
    [Documentation]    Suite Setup, spawns trustyAI image
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small

Close Previous Server
    [Documentation]  Closes previous server and goes back to Spawner
    Clean Up Server
    Stop JupyterLab Notebook Server
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
