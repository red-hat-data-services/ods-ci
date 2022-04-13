*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          OpenShiftCLI
Library          DebugLibrary
Suite Setup      Server Setup
Suite Teardown   End Web Test


*** Variables ***
${REPO_URL} =    *****
${DIR_NAME} =  Python
${FILE_PATH} =   Python/file.ipynb
${EMAIL_ID} =  user@gmail.com
${NAME} =  user
${COMMIT_MSG} =  commit msg2


*** Test Cases ***

Verify Pushing Project Changes Remote Repository
    [Tags]  ODS-326
    ...     Tier1
    ${randnum}=  Generate Random String  9  [NUMBERS]
    ${commit_message} =    Catenate    ${COMMIT_MSG}    ${randnum}
    Push Some Changes to Repo    ${GITHUB_USER.USERNAME}  ${GITHUB_USER.TOKEN}   ${FILE_PATH}    ${REPO_URL}    ${commit_message}

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

  ${commit_msg1}=  Run Cell And Get Output    !git log --name-status HEAD^..HEAD | sed -n 5p
  

  Add and Run JupyterLab Code Cell in Active Notebook  ! mkdir ../folder/
  

  Sleep    5s

  Open Folder or File    folder
  
  ${randnum}=  Generate Random String  9  [NUMBERS]
  ${commit_message} =    Catenate    ${COMMIT_MSG}    ${randnum}
  #now do here some changes
  Push Some Changes to Repo    ${GITHUB_USER.USERNAME}    ${GITHUB_USER.TOKEN}    folder/${FILE_PATH}    ${REPO_URL}    ${commit_message}
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
  ${commit_msg2}=  Run Cell And Get Output    !git log --name-status HEAD^..HEAD | sed -n 5p
  Should Not Be Equal    ${commit_msg2}    ${commit_msg1}



*** Keywords ***
Server Setup
    [Documentation]    Suite Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default


Push Some Changes to Repo
    [Arguments]  ${github username}  ${token}   ${filepath}    ${githublink}    ${commitmsgg}

    Clone Git Repository In Current Folder      ${githublink}

    Open Folder or File    ${filepath}

    Maybe Close Popup
    Sleep    2s
    Wait Until JupyterLab Code Cell Is Not Active
    Run Cell And Get Output  print("Hi \\n Hello")
    Sleep    1s
    Add and Run JupyterLab Code Cell in Active Notebook  print("Hi Hello")
    Sleep    2s
    Open With JupyterLab Menu  File  Save Notebook
    Sleep    1s
    Open With JupyterLab Menu  Git  Simple staging
    Click Element   xpath=//*[@id="tab-key-6"]/div[1]
    Log to Console  After clicking on git icon
    #-------------------

    Input Text    xpath=//*[@id="jp-git-sessions"]/div/form/input[1]    ${commitmsgg}
    #click on commit button
    Sleep    2s
    Click Button    xpath=//*[@id="jp-git-sessions"]/div/form/input[2]
    Log to Console  After putting commit message and clicking on commit

    Wait Until Page Contains  Who is committing?

    Input Text    //input[@class='jp-mod-styled'][1]    ${NAME}
    Input Text    //input[@class='jp-mod-styled'][2]    ${EMAIL_ID}


    Click Element    //button[@class='jp-Dialog-button jp-mod-accept jp-mod-styled']//div[2]    #click on submit
    Sleep   5s
    #click on push to remote
    Open With JupyterLab Menu    Git    Push to Remote
    Log To Console    after clicking on push to remote
    Wait Until Page Contains    Git credentials required  timeout=200s

    # enter the credentials username and password

    Input Text    //input[@class='jp-mod-styled'][1]    ${github username}
    Input Text    //input[@class='jp-mod-styled'][2]    ${token}
    Click Element    //button[@class='jp-Dialog-button jp-mod-accept jp-mod-styled']//div[2]    #click on submit

    Sleep  5s
    Open With JupyterLab Menu  Git  Simple staging
    Close All JupyterLab Tabs
    sleep  2s

    Open With JupyterLab Menu  File  New  Notebook
    Sleep  2s
    Maybe Close Popup
    Wait Until JupyterLab Code Cell Is Not Active

    Add and Run JupyterLab Code Cell in Active Notebook    !git log --name-status HEAD^..HEAD | sed -n 5p
    ${output}=  Run Cell And Get Output    !git log --name-status HEAD^..HEAD | sed -n 5p
    sleep  2s
    Should Be Equal     ${commitmsgg.strip()}    ${output.strip()}


Open Folder or File
    [Arguments]    ${path}
    Open With JupyterLab Menu  File  Open from Path…
    Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  ${path}
    Click Element  xpath://div[.="Open"]
    Sleep    2s

Clone Git Repository In Current Folder
    [Aguments]     ${github_link}
    Open With JupyterLab Menu    File    New    Notebook
    Sleep    2s
    Maybe Close Popup
    Close Other JupyterLab Tabs
    Maybe Close Popup
    Sleep    1
    Run Cell And Get Output    !git clone ${githublink}
    Sleep  15


