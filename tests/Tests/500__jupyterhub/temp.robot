*** Comments ***
# this is temporary file to test 'Clone Git Repository' keyword
# Once it get verified then will remove it


*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
#Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             OpenShiftCLI
Library             DebugLibrary

Suite Setup         Server Setup
Suite Teardown      End Web Test


*** Variables ***
${link}=    https://github.com/Pranav-Code-007/Python.git


*** Test Cases ***
Test1
    [Documentation]    When repo is already cloned
    [Tags]    XXXX
    Clone Git Repository    ${link}
    Clone Git Repository    ${link}
    Clean Up Server

Test2
    [Documentation]    When repo is not cloned
    [Tags]    XXXX
    Clone Git Repository    ${link}
    Clean Up Server




*** Keywords ***
Server Setup
    [Documentation]    Suite Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default

Clone Git Repository
  [Documentation]    Clones git repository and logs error message if fails to clone
  [Arguments]  ${REPO_URL}    ${delete_existing_repo}=True
  IF    "${delete_existing_repo}" == "True"
        ${dir_name} =    Get Directory Name From Git Repo URL    ${link}
        ${curent_user} =    Get Current User
        Delete Folder In User Notebook
        ...    admin_username=${OCP_ADMIN_USER.USERNAME}
        ...    username=${curent_user}
        ...    folder=${dir_name}
  END
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu    Git    Clone a Repository
  Input Text    //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input    ${link}
  Click Element    xpath://div[.="CLONE"]
  Wait Until Page Contains    Cloning...    timeout=5s
  ${err_msg} =  Set Variable
  ${status}    ${err_msg}     Run Keyword and Ignore Error    Get Git Clone Error Message
  Log  ${err_msg}

Get Current User
  ${url} =  Get Location
  ${current_user} =  Evaluate  '${url}'.split("/")[-2]
  [Return]  ${current_user}

