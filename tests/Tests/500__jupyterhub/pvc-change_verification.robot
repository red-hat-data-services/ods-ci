*** Settings ***
Documentation    PVC_CHANGE_VERIFICATION
...                 Verify  if we can modfiy default PVC size
...
...
...                 = Variables =
...                 | Namespace | Required |    Jupyterhub conifguration namespace|
...                 | S_size    | Required |    Supported size |
...                 | Ns_size   | Required  |   Not Supported PVC size |
...                 | Size_code | Required |    Python code to check size in notebook |
#
Library         SeleniumLibrary
Library         JupyterLibrary
Resource         ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource

Test Teardown   PVC Size Test Teardown


*** Variables ***
${NAMESPACE}    redhat-ods-applications
${S_SIZE}       15
${SIZE_CODE}    import subprocess;
...    int(subprocess.check_output(['df','-h', '/opt/app-root/src']).split()[8].decode('utf-8')[:-1])
${NS_SIZE}    0


*** Test Cases ***
Verify User Can Spawn Notebook With PVC Change
    [Documentation]   Verify if user can spawn notebook
    ...    for supported PVC change
    [Tags]    Smoke
    ...       Sanity
    ...       ODS-1228
    ...       Resources-PVC
    Check If PVC Change Is Permanent    ${S_SIZE}Gi
    Roll Out Jupyter Deployement Config
    Run Keyword And Continue On Failure   Verify Notebook Size     600s    ${S_SIZE}
    ${pvc_size}   Get Notebook PVC Size        username=${TEST_USER.USERNAME}   namespace=rhods-notebooks
    Verify PVC Size     ${S_SIZE}       ${pvc_size}

Verify User Can Not Spawn Notebbok With Unsupported Size
    [Documentation]   Verify if user should not able to
    ...    spawn notebook for supported PVC change
    [Tags]    Tier2
    ...       ODS-1229
    ...       Resources-PVC
    Check If PVC Change Is Permanent     ${NS_SIZE}Gi
    Roll Out Jupyter Deployement Config
    ${status}     Run Keyword And Return Status   Verify Notebook Size   60s   ${NS_SIZE}
    Page Should Contain    Server request failed to start
    Run Keyword IF    '${status}'=='FAIL'   Log   Unable to Spawn Notebook
    ...   for unsupported values
