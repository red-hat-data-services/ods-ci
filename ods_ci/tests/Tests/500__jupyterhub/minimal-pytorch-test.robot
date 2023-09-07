*** Settings ***
Documentation    Test Suite for PyTorch image
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Resource         ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Verify PyTorch Image Suite Setup
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
${NOTEBOOK_IMAGE} =         pytorch
${EXPECTED_CUDA_VERSION} =  12.2


*** Test Cases ***
Verify PyTorch Image Can Be Spawned
    [Documentation]    Spawns pytorch image
    [Tags]  Sanity
    ...     PLACEHOLDER  # category tags
    ...     ODS-1149
    Pass Execution    Passing tests, as suite setup ensures that image can be spawned

PyTorch Image Workload Test
    [Documentation]    Runs a pytorch workload
    [Tags]  Sanity
    ...     PLACEHOLDER  # category tags
    ...     ODS-1150
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible

Verify Tensorboard Is Accessible
    [Documentation]  Verifies that tensorboard is accessible
    [Tags]  Sanity
    ...     PLACEHOLDER
    ...     ODS-1414
    Close Previous Server
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small
    Run Keyword And Ignore Error  Clone Git Repository And Run  https://github.com/redhat-rhods-qe/ods-ci-notebooks-main
    ...    ods-ci-notebooks-main/notebooks/500__jupyterhub/tensorboard/pytorch/tensorboard_profiling_pytorch.ipynb  10m
    Select Frame    xpath://iframe[contains(@id, "tensorboard-frame")]
    Page Should Contain Element    xpath://html//mat-toolbar/span[.="TensorBoard"]
    Unselect Frame

Verify PyTorch Image Can Be Spawned With GPU
    [Documentation]    Spawns PyTorch image with 1 GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1145
    Clean Up Server
    Stop JupyterLab Notebook Server
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small  gpus=1

Verify PyTorch Image Includes Expected CUDA Version
    [Documentation]    Checks CUDA version
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1146
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION}

Verify PyTorch Library Can See GPUs In PyTorch Image
    [Documentation]    Verifies PyTorch can see the GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1147
    Verify Pytorch Can See GPU

Verify PyTorch Image GPU Workload
    [Documentation]  Runs a workload on GPUs in PyTorch image
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1148
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/fgsm_tutorial.ipynb

Verify Previous PyTorch Notebook Image With GPU
    [Documentation]    Runs a workload after spawning the N-1 PyTorch Notebook
    [Tags]    Tier2    LiveTesting
    ...       Resources-GPU
    ...       ODS-2129
    [Setup]    N-1 PyTorch Setup
    Spawn Notebook With Arguments    image=${NOTEBOOK_IMAGE}    size=Small    gpus=1    version=previous
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION}
    Verify PyTorch Can See GPU
    Run Repo And Clean    https://github.com/lugi0/notebook-benchmarks    notebook-benchmarks/pytorch/fgsm_tutorial.ipynb
    [Teardown]    End Web Test


*** Keywords ***
Verify PyTorch Image Suite Setup
    [Documentation]    Suite Setup, spawns pytorch image
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

N-1 PyTorch Setup
    [Documentation]    Closes the previous browser (if any) and starts a clean
    ...                run spawning the N-1 PyTorch image
    End Web Test
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Sleep    30s    reason=Wait for resources to become available again
    SeleniumLibrary.Reload Page
    Wait Until JupyterHub Spawner Is Ready
