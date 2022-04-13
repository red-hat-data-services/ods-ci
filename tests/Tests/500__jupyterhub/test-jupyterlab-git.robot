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
${REPO_URL}         ****
${DIR_NAME}         Python
${FILE_PATH}        Python/file.ipynb
${COMMIT_MSG}       commit msg2


*** Test Cases ***
Verify Pushing Project Changes Remote Repository
    [Tags]    ODS-326
    ...       Tier1
    ${randnum}=    Generate Random String    9    [NUMBERS]
    ${commit_message}=    Catenate    ${COMMIT_MSG}    ${randnum}
    Push Some Changes to Repo
    ...    ${GITHUB_USER.USERNAME}
    ...    ${GITHUB_USER.TOKEN}
    ...    ${FILE_PATH}
    ...    ${REPO_URL}
    ...    ${commit_message}
    Clean Up Server

Verify updating your project with changes from a git repository
    [Tags]    ODS-324
    ...       Tier1
    Clone Git Repository And Open    ${REPO_URL}    ${FILE_PATH}
    Sleep    1s
    Open With JupyterLab Menu    File    New    Notebook
    Sleep    2s
    Maybe Close Popup
    Close Other JupyterLab Tabs
    Maybe Close Popup
    Sleep    1
    ${commit_msg1}=    Run Cell And Get Output    !git log --name-status HEAD^..HEAD | sed -n 5p
    Add and Run JupyterLab Code Cell in Active Notebook    ! mkdir ../folder/

    Sleep    4s

    Open Folder or File    folder

    ${randnum}=    Generate Random String    9    [NUMBERS]
    ${commit_message}=    Catenate    ${COMMIT_MSG}    ${randnum}
    #now do here some changes
    Push Some Changes to Repo
    ...    ${GITHUB_USER.USERNAME}
    ...    ${GITHUB_USER.TOKEN}
    ...    folder/${FILE_PATH}
    ...    ${REPO_URL}
    ...    ${commit_message}

    #go to previous dir
    Close All JupyterLab Tabs

    Open Folder or File    ${DIR_NAME}

    Open With JupyterLab Menu    Git    Pull from Remote
    Sleep    2s
    Open With JupyterLab Menu    File    New    Notebook
    Sleep    2s
    Maybe Close Popup
    Close Other JupyterLab Tabs
    Maybe Close Popup
    Sleep    1
    ${commit_msg2}=    Run Cell And Get Output    !git log --name-status HEAD^..HEAD | sed -n 5p
    Should Not Be Equal    ${commit_msg2}    ${commit_msg1}
    Clean Up Server


*** Keywords ***
Server Setup
    [Documentation]    Suite Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default

Push Some Changes to Repo
    [Arguments]    ${github username}    ${token}    ${filepath}    ${githublink}    ${commitmsgg}

    Clone Git Repository In Current Folder    ${githublink}
    Open Folder or File    ${filepath}
    Maybe Close Popup
    Sleep    2s
    Wait Until JupyterLab Code Cell Is Not Active
    Sleep    2s
    Run Cell And Get Output    print("Hi \\n Hello")
    Sleep    1s
    Add and Run JupyterLab Code Cell in Active Notebook    print("Hi Hello")
    Sleep    2s
    Open With JupyterLab Menu    File    Save Notebook
    Sleep    1s
    Open With JupyterLab Menu    Git    Simple staging

    Commit Changes    commit_message=${commitmsgg}    name=${GITHUB_USER.USERNAME}     email_id=${GITHUB_USER.EMAIL}

    #click on push to remote

    Push Changes To Remote     github_username=${GITHUB_USER.USERNAME}    token=${GITHUB_USER.TOKEN}

    Sleep    5s
    Open With JupyterLab Menu    Git    Simple staging
    Close All JupyterLab Tabs
    sleep    2s

    Open With JupyterLab Menu    File    New    Notebook
    Sleep    2s
    Maybe Close Popup
    Wait Until JupyterLab Code Cell Is Not Active

    Add and Run JupyterLab Code Cell in Active Notebook    !git log --name-status HEAD^..HEAD | sed -n 5p
    ${output}=    Run Cell And Get Output    !git log --name-status HEAD^..HEAD | sed -n 5p
    sleep    2s
    Should Be Equal    ${commitmsgg.strip()}    ${output.strip()}

Open Folder or File
    [Arguments]    ${path}
    Open With JupyterLab Menu    File    Open from Path…
    Input Text    xpath=//input[@placeholder="/path/relative/to/jlab/root"]    ${path}
    Click Element    xpath://div[.="Open"]
    Sleep    2s

Clone Git Repository In Current Folder
    [Arguments]    ${github_link}
    Open With JupyterLab Menu    File    New    Notebook
    Sleep    2s
    Maybe Close Popup
    Close Other JupyterLab Tabs
    Maybe Close Popup
    Sleep    1
    Run Cell And Get Output    !git clone ${github_link}
    Sleep    15

Commit Changes
    [Documentation]    It does the git commit
    [Arguments]    ${commit_message}    ${name}    ${email_id}
    Click Element    xpath=//*[@id="tab-key-6"]/div[1]    #Git Icon
    Input Text    xpath=//*[@id="jp-git-sessions"]/div/form/input[1]    ${commit_message}
    Sleep    2s
    Click Button    xpath=//*[@id="jp-git-sessions"]/div/form/input[2]    #click on commit button
    Wait Until Page Contains    Who is committing?
    Input Text    //input[@class='jp-mod-styled'][1]    ${name}
    Input Text    //input[@class='jp-mod-styled'][2]    ${email_id}
    Click Element    //button[@class='jp-Dialog-button jp-mod-accept jp-mod-styled']//div[2]    #click on submit
    Sleep    4s

Push Changes To Remote
    [Arguments]    ${github_username}    ${token}
    Open With JupyterLab Menu    Git    Push to Remote
    Wait Until Page Contains    Git credentials required    timeout=200s

    # enter the credentials username and token

    Input Text    //input[@class='jp-mod-styled'][1]    ${github_username}
    Input Text    //input[@class='jp-mod-styled'][2]    ${token}
    Click Element    //button[@class='jp-Dialog-button jp-mod-accept jp-mod-styled']//div[2]    #click on submit

