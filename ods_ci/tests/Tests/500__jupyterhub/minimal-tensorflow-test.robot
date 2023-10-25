*** Settings ***
Documentation    Test Suite for Tensorflow image
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Resource         ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Library          Screenshot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Verify Tensorflow Image Suite Setup
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
${NOTEBOOK_IMAGE} =         tensorflow
${EXPECTED_CUDA_VERSION} =  12.2


*** Test Cases ***
Verify Tensorflow Image Can Be Spawned
    [Documentation]    Spawns tensorflow image
    [Tags]  Sanity
    ...     PLACEHOLDER  # Category tags
    ...     ODS-1155
    Pass Execution    Passing tests, as suite setup ensures that image can be spawned

Tensorflow Workload Test
    [Documentation]    Runs tensorflow workload
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1156
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible

Verify Tensorboard Is Accessible
    [Documentation]  Verifies that tensorboard is accessible
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1413
    Close Previous Server
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small
    Run Keyword And Ignore Error  Clone Git Repository And Run  https://github.com/redhat-rhods-qe/ods-ci-notebooks-main
    ...    ods-ci-notebooks-main/notebooks/500__jupyterhub/tensorboard/tensorflow/tensorboard_profiling_tensorflow.ipynb  10m
    Select Frame    xpath://iframe[contains(@id, "tensorboard-frame")]
    Page Should Contain Element    xpath://html//mat-toolbar/span[.="TensorBoard"]
    Unselect Frame

Verify Tensorflow Image Can Be Spawned With GPU
    [Documentation]    Spawns PyTorch image with 1 GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1151
    Close Previous Server
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small  gpus=1

Verify Tensorflow Image Includes Expected CUDA Version
    [Documentation]    Checks CUDA version
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1152
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION}

Verify Tensorflow Library Can See GPUs In Tensorflow Image
    [Documentation]    Verifies Tensorlow can see the GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1153
    Verify Tensorflow Can See GPU

Verify Tensorflow Image GPU Workload
    [Documentation]  Runs a workload on GPUs in Tensorflow image
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1154
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb

Verify Previous Tensorflow Notebook Image With GPU
    [Documentation]    Runs a workload after spawning the N-1 Tensorflow Notebook
    [Tags]    Tier2    LiveTesting
    ...       Resources-GPU
    ...       ODS-2130
    [Setup]    N-1 Tensorflow Setup
    Spawn Notebook With Arguments    image=${NOTEBOOK_IMAGE}    size=Small    gpus=1    version=previous
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION}
    Verify Tensorflow Can See GPU
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb
    [Teardown]    End Web Test


*** Keywords ***
Verify Tensorflow Image Suite Setup
    [Documentation]    Suite Setup, spawns tensorflow image
    ${version_check} =  Is RHODS Version Greater Or Equal Than  1.20.0
    IF    ${version_check}==False
       Wait Until All Builds Are Complete    namespace=${APPLICATIONS_NAMESPACE}    build_timeout=45m
    END
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small

Close Previous Server
    [Documentation]  Closes previous server and goes back to Spawner
    Clean Up Server
    Stop JupyterLab Notebook Server
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready

N-1 Tensorflow Setup
    [Documentation]    Closes the previous browser (if any) and starts a clean
    ...                run spawning the N-1 Tensorflow image
    End Web Test
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Sleep    30s    reason=Wait for resources to become available again
    Reload Page
    Wait Until JupyterHub Spawner Is Ready
