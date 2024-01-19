*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             DebugLibrary

Suite Setup         Server Setup
Suite Teardown      End Web Test
Test Tags          JupyterHub


*** Variables ***
${TEST_ALERT_PVC90_NOTEBOOK_PATH}       SEPARATOR=
...                                     /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/
...                                     203__alerts/notebook-pvc-usage/fill-notebook-pvc-over-90.ipynb

${PATH_TO_FILE}         SEPARATOR=
...                     ods-ci-notebooks-main/notebooks/200__monitor_and_manage/
...                     203__alerts/notebook-pvc-usage/fill-notebook-pvc-to-complete-100.ipynb
${LINK_OF_GITHUB}       https://github.com/redhat-rhods-qe/ods-ci-notebooks-main.git
${FILE_NAME}            fill-notebook-pvc-to-complete-100.ipynb


*** Test Cases ***
Verify Users Get Notifications If Storage Capacity Limits Get Exceeded
    [Documentation]    Runs a jupyter notebook to fill the user PVC to 100% and verifies that
    ...    a "No space left on device" OSError and a "File Save Error" dialog are shown
    [Tags]    Sanity
    ...       ODS-539

    ${error} =    Run Git Repo And Return Last Cell Error Text    ${LINK_OF_GITHUB}    ${PATH_TO_FILE}
    Cell Error Message Should Be    OSError: [Errno 28] No space left on device    ${error}
    Wait Until Page Contains    File Save Error for ${FILE_NAME}    timeout=150s
    Maybe Close Popup
    Clean Up User Notebook    ${OCP_ADMIN_USER.USERNAME}    ${TEST_USER.USERNAME}


*** Keywords ***
Server Setup
    [Documentation]    Suite Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=minimal-notebook    size=Small


Cell Error Message Should Be
  [Documentation]    It checks for the expected error and test error
  [Arguments]    ${expected_error}    ${error_of_cell}
  ${error} =    Split String    ${error_of_cell}    \n\n
  Should Be Equal    ${expected_error}    ${error[-1]}

