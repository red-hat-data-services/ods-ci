*** Settings ***
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource            ../../../Resources/RHOSi.resource
Library             DebugLibrary
Test Teardown       Clean Up Server
Suite Setup         Server Setup
Suite Teardown      End Web Test


*** Variables ***
${REPO_URL}         https://github.com/ods-qe-test/ODS-QE-Github-Test.git
${DIR_NAME}         ODS-QE-Github-Test
${FILE_PATH}        ODS-QE-Github-Test/test-file.ipynb
${COMMIT_MSG}       commit msg2


*** Test Cases ***
Verify Pushing Project Changes Remote Repository
    [Documentation]    Verifies that changes has been pushed successfully to remote repository
    [Tags]    ODS-326
    ...       Tier1
    Set Simple Staging Status    status=OFF
    ${randnum}=    Generate Random String    9    [NUMBERS]
    ${commit_message}=    Catenate    ${COMMIT_MSG}    ${randnum}
    Run Keyword And Return Status    Open New Notebook
    Push Some Changes to Repo
    ...    ${GITHUB_USER.USERNAME}
    ...    ${GITHUB_USER.TOKEN}
    ...    ${FILE_PATH}
    ...    ${REPO_URL}
    ...    ${commit_message}

Verify Updating Project With Changes From Git Repository
    [Documentation]    Verifies that changes has been pulled successfully to local repository
    [Tags]    ODS-324
    ...       Tier1
    Set Simple Staging Status    status=OFF
    Clone Git Repository And Open    ${REPO_URL}    ${FILE_PATH}
    Sleep    1s
    Open New Notebook
    Add And Run JupyterLab Code Cell In Active Notebook
    ...    import os;path="/opt/app-root/src/ODS-QE-Github-Test";os.chdir(path)
    ${commit_msg1}=    Get Last Commit Message
    Add And Run JupyterLab Code Cell In Active Notebook    !mkdir ../folder/
    Add And Run JupyterLab Code Cell In Active Notebook    !git config --global user.name "${GITHUB_USER.USERNAME}"
    Add And Run JupyterLab Code Cell In Active Notebook    !git config --global user.email ${GITHUB_USER.EMAIL}
    Sleep    2s
    Open Folder or File    folder
    ${randnum}=    Generate Random String    9    [NUMBERS]
    ${commit_message}=    Catenate    ${COMMIT_MSG}    ${randnum}
    Push Some Changes to Repo
    ...    ${GITHUB_USER.USERNAME}
    ...    ${GITHUB_USER.TOKEN}
    ...    folder/${FILE_PATH}
    ...    ${REPO_URL}
    ...    ${commit_message}
    Close All JupyterLab Tabs
    Open Folder or File    ${DIR_NAME}
    Open With JupyterLab Menu    Git    Pull from Remote
    Sleep    2s
    Open New Notebook
    ${commit_msg2}=    Get Last Commit Message
    Should Not Be Equal    ${commit_msg2}    ${commit_msg1}


*** Keywords ***
Server Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=minimal-notebook    size=Small

Push Some Changes To Repo
    [Documentation]    Make some changes in ${filepath} and push to remote repo
    [Arguments]    ${github username}    ${token}    ${filepath}    ${githublink}    ${commitmsgg}
    Clone Git Repository In Current Folder    ${githublink}
    Close All JupyterLab Tabs
    Open Folder or File    ${filepath}
    Open With JupyterLab Menu    Edit    Select All Cells
    Open With JupyterLab Menu    Edit    Delete Cells
    Enter Text In File And Save    code=print("Hi Hello ${commitmsgg}")
    Set Simple Staging Status    status=ON
    Commit Changes    commit_message=${commitmsgg}    name=${GITHUB_USER.USERNAME}    email_id=${GITHUB_USER.EMAIL}
    Push Changes To Remote    github_username=${GITHUB_USER.USERNAME}    token=${GITHUB_USER.TOKEN}
    Set Simple Staging Status    status=OFF
    Close All JupyterLab Tabs
    Sleep    2s
    Open New Notebook
    ${output}=    Get Last Commit Message
    Should Be Equal    ${commitmsgg}    ${output}

Open Folder Or File
    [Documentation]    Opens the folder or file
    [Arguments]    ${path}
    Open With JupyterLab Menu    File    Open from Path…
    Input Text    xpath=//input[@placeholder="/path/relative/to/jlab/root"]    ${path}
    Click Element    xpath://div[.="Open"]
    Sleep    2s
    Maybe Close Popup
    Sleep    2s

Clone Git Repository In Current Folder
    [Documentation]    Clones git repository in current folder
    [Arguments]    ${github_link}
    Open New Notebook
    Run Cell And Get Output    !git clone ${github_link}
    Sleep    15

Commit Changes
    [Documentation]    It does the git commit with commit message
    [Arguments]    ${commit_message}    ${name}    ${email_id}
    Click Element    xpath=//li[@title="Git"]
    Input Text    xpath=//*[@id="jp-git-sessions"]//input[contains(@placeholder, "Summary")]    ${commit_message}
    Sleep    2s
    ${attr} =    Get Element Attribute    xpath=//div[contains(@class, "CommitBox")]//button[.="Commit"]    title
    IF    '''${attr}''' == 'Disabled: No files are staged for commit'
        Set Simple Staging Status    status=OFF
        Set Simple Staging Status    status=ON
    END
    Click Button    xpath=//div[contains(@class, "CommitBox")]//button[.="Commit"]
    ${identity} =    Run Keyword And Return Status    Wait Until Page Contains    Who is committing?    timeout=10s
    IF  ${identity}
        Input Text    xpath=//input[@placeholder="Name"]    ${name}
        Input Text    xpath=//input[@placeholder="Email"]    ${email_id}
        Click Ok Button JupyterLab Version Agnostic
    ELSE
        Page Should Contain Element    xpath=//button[@title="Disabled: No files are staged for commit"]
    END

Push Changes To Remote
    [Documentation]    Push changes to remote directory
    [Arguments]    ${github_username}    ${token}
    Open With JupyterLab Menu    Git    Push to Remote
    Wait Until Page Contains    Git credentials required    timeout=200s
    Input Text    xpath=//input[@placeholder="username"]    ${github_username}
    Input Text    xpath=//input[@placeholder="personal access token"]    ${token}
    Click Ok Button JupyterLab Version Agnostic
    Wait Until Page Contains    Successfully pushed    timeout=10s

Click Ok Button JupyterLab Version Agnostic
    [Documentation]    Click the Ok button so it works in both JupyterLab 3.6 and JupyterLab 4.2
    ...    JupyterLab 4.2 was introduced in images 2024.2.
    # In JupyterLab 3.6 (that uses codemirror 5) the button is "OK"
    # In JupyterLab 4.2.5 (that uses codemirror 6) the button is "Ok"
    Click Element    xpath=//button[.="Ok" or .="OK"]

Get Last Commit Message
    [Documentation]    Return the last cpmmit message
    ${output}=    Run Cell And Get Output    !git log --format=%B -n 1 HEAD^..HEAD
    RETURN    ${output}

Simple Staging Is Enabled
    [Documentation]    Ensures that Simple Staging is disabled
    Open With JupyterLab Menu    Git
    ${simple_staging_element}=    Set Variable
    ...    //li[@role="menuitem" and @data-command="git:toggle-simple-staging" and contains(@class, "lm-mod-toggled")]
    Run Keyword And Continue On Failure
    ...    Wait Until Page Contains Element    xpath=${simple_staging_element}    timeout=3s
    # Close the menu again
    Open With JupyterLab Menu    Git

Set Simple Staging Status
    [Documentation]    Sets the staging status
    [Arguments]    ${status}
    ${curr_status}=    Run Keyword And Return Status    Simple Staging Is Enabled
    IF    "${curr_status}"=="False" and "${status}"=="ON"
        Open With JupyterLab Menu    Git    Simple staging
    ELSE IF    "${curr_status}"=="True" and "${status}"=="OFF"
        Open With JupyterLab Menu    Git    Simple staging
    END

Open New Notebook
    [Documentation]    Opens new notebook
    Open With JupyterLab Menu    File    New    Notebook
    Sleep    2s
    Maybe Close Popup
    Close Other JupyterLab Tabs
    Maybe Close Popup
    Sleep    1

Enter Text In File And Save
    [Documentation]    Enters text in current opened file
    [Arguments]    ${code}
    Wait Until JupyterLab Code Cell Is Not Active
    Sleep    2s
    Run Cell And Get Output    ${code}
    Sleep    2s
    Open With JupyterLab Menu    File    Save Notebook
    Sleep    2s
