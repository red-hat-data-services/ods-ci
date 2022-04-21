*** Comments ***
# this is temporary file to test 'Clone Git Repository' keyword
# Once it get verified then will remove it


*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             OpenShiftCLI
Library             DebugLibrary

Suite Setup         Server Setup
Suite Teardown      End Web Test


*** Variables ***
${link}=    ****


*** Test Cases ***
Test1
    [Documentation]    When repo is already cloned
    [Tags]    XXXX
    Clone Repo    ${link}
    Clone Git Repository
    Clean Up Server

Test2
    [Documentation]    When repo is not cloned
    [Tags]    XXXX
    Clone Git Repository
    Clean Up Server


*** Keywords ***
Server Setup
    [Documentation]    Suite Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default

Did error occur
    [Documentation]    Returns error when it fails to clones and Fails when error doesn't occur
    ${err_msg} =    Set Variable    No error
    Wait Until Page Contains    Failed to clone    timeout=3s
    Click Button    //div[@class="MuiSnackbar-root MuiSnackbar-anchorOriginBottomRight"]/div/div/button    #click show
    ${err_msg} =    Get Text    //div/div/span[@class="lm-Widget p-Widget jp-Dialog-body"]    #get error text
    #dismiss button
    Click Button
    ...    //div/div/button[@class="jp-Dialog-button jp-mod-accept jp-mod-warn jp-mod-styled"]
    RETURN    ${err_msg}

Get Directory
    [Documentation]    Returns directory name from repo link
    [Arguments]    ${link}
    @{ans} =    Split Path    ${link}
    ${ans} =    Remove String    ${ans}[1]    .git
    RETURN    ${ans}

Remove Local Git Repo
    [Documentation]    Removes locally present repository
    [Arguments]    ${repo_link}
    Open With JupyterLab Menu    File    New    Notebook
    Sleep    2s
    Maybe Close Popup
    Close Other JupyterLab Tabs
    Maybe Close Popup
    ${dir_name} =    Get Directory    ${repo_link}
    Add and Run JupyterLab Code Cell in Active Notebook    !rm -rf "${dir_name}"
    Sleep    2s

Clone Git Repository
    ${status}    ${err_msg} =    Run Keyword and Ignore Error    Clone Repo and Return Error Message
    IF    "${status}" == "PASS"
        Remove Local Git Repo    ${link}
        ${status}    ${err_msg} =    Run Keyword and Ignore Error    Clone Repo and Return Error Message
        IF    "${status}" == "PASS"
            Log    Error Message : ${err_msg}
            FAIl
        END
    ELSE
        Wait Until Page Contains    Successfully cloned    timeout=200s
    END

Clone Repo and Return Error Message
    Clone Repo    ${link}
    Wait Until Page Contains    Cloning...    timeout=5s
    ${err_msg} =    Did error occur
    RETURN    ${err_msg}

Clone Repo
    [Documentation]    Clones git repo
    [Arguments]    ${REPO_URL}
    Navigate Home (Root folder) In JupyterLab Sidebar File Browser
    Open With JupyterLab Menu    Git    Clone a Repository
    Input Text    //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input    ${REPO_URL}
    Click Element    xpath://div[.="CLONE"]

