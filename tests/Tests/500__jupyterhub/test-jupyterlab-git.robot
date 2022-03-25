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
${REPO_URL} =    ****
${dir_name} =  Python
${FILE_PATH} =   Python/file.ipynb
${user_name} =   ****
${email_id} =  ****
${commit_page} =  ****
${name} =  Pranav
${commit_msg} =  commit msg2
${token} =  ****

*** Test Cases ***
# Have a remote repository configured
# File -> save all changes
# Click git -> simple staging
# Click git -> push to remote

Verify Pushing Project Changes Remote Repository
    [Tags]  ODS-326
    ...     Tier1
    sleep  5s
    Clone Git Repository And Open    ${REPO_URL}    ${FILE_PATH}
    Sleep    5s
    Run Cell And Get Output  print("Hi Hello")
    Sleep    5s
    Log to Console  After Run JupyterLab Code Cell
    Wait Until JupyterLab Code Cell Is Not Active
    Log to Console  Wait Until JupyterLab
    Open With JupyterLab Menu  File  Save Notebook
    Log to Console  Open with Jl Menu File Save Nb
    Open With JupyterLab Menu  Git  Simple staging
    Log to Console  Open with JL Menu Git Simple Staging

    # Click on git icon
    Click Element   xpath=//*[@id="tab-key-6"]/div[1]
    Log to Console  After clicking on git icon
    #-------------------

    ${randnum}=  Generate Random String  9  [NUMBERS]

    Input Text    xpath=//*[@id="jp-git-sessions"]/div/form/input[1]    ${commit_msg} ${randnum}
    #click on commit button
    Sleep    2s
    Click Button    xpath=//*[@id="jp-git-sessions"]/div/form/input[2]

    Wait Until Page Contains  Who is committing?

    Input Text    //input[@class='jp-mod-styled'][1]    ${name}
    Input Text    //input[@class='jp-mod-styled'][2]    ${email_id}


    Click Element    //button[@class='jp-Dialog-button jp-mod-accept jp-mod-styled']//div[2]    #click on submit
    Sleep    5s
    #click on push to remote
    Open With JupyterLab Menu    Git    Push to Remote
    Log To Console    after clicking on push to remote
    Wait Until Page Contains    Git credentials required  timeout=200s

    # enter the credentials username and password

    Input Text    //input[@class='jp-mod-styled'][1]    ${user_name}
    Input Text    //input[@class='jp-mod-styled'][2]    ${token}
    Click Element    //button[@class='jp-Dialog-button jp-mod-accept jp-mod-styled']//div[2]    #click on submit

    Sleep  5s
    Open With JupyterLab Menu  Git  Simple staging
    Close All JupyterLab Tabs
    sleep  2s
    Open With JupyterLab Menu  File  New  Notebook
    Sleep  5s
    Maybe Close Popup
    Wait Until JupyterLab Code Cell Is Not Active

    Add and Run JupyterLab Code Cell in Active Notebook  !git log --name-status HEAD^..HEAD
    ${output}=  Run Cell And Get Output    !git log --name-status HEAD^..HEAD
    Log To Console    output ${output}
    Maybe Close Popup
    ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
    Log To Console    output ${output}

    sleep  2s
    ${contains}=  Evaluate   "${commit_msg} ${randnum}" in """${output}"""
    Should Be Equal     ${True}    ${contains}
    Clean Up User Notebook    ${OCP_ADMIN_USER.USERNAME}    ${TEST_USER.USERNAME}

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
  ${ouput1}=  Run Cell And Get Output    !git log --name-status HEAD^..HEAD
  Log To Console    output 1.1 ${ouput1}
  ${ouput1}=  Run Cell And Get Output    !git log --name-status HEAD^..HEAD
  Log To Console    output 1.2 ${ouput1}
  Log To Console    ---------

  Add and Run JupyterLab Code Cell in Active Notebook  ! mkdir ../folder/
  Log To Console    After !mkdir ../folder/
  Add and Run JupyterLab Code Cell in Active Notebook  ! ls
  Log To Console    After !ls
  Sleep    5s
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  folder
  Click Element  xpath://div[.="Open"]
  Sleep    5s
  #now do here some changes
  Push Some Changes to Repo    ${user_name}  ${token}    folder/${FILE_PATH}    ${REPO_URL}    ${commit_msg}
  #go to previous dir
  Close All JupyterLab Tabs
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  ${dir_name}
  Click Element  xpath://div[.="Open"]
  Sleep    1s
  Open With JupyterLab Menu    Git    Pull from Remote
  Sleep    2s
  Open With JupyterLab Menu    File    New    Notebook
  Sleep    2s
  Maybe Close Popup
  Close Other JupyterLab Tabs
  Maybe Close Popup
  Sleep    1
  ${output2}=  Run Cell And Get Output    !git log --name-status HEAD^..HEAD
  Log To Console    output2.2 ${ouput2}



*** Keywords ***
Server Setup
    [Documentation]    Suite Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default


Push Some Changes to Repo
    [Arguments]  ${gitusername}  ${gittoken}   ${filepath}    ${githublink}    ${commitmsg}
    Sleep    1s
    Open With JupyterLab Menu    File    New    Notebook
    Sleep    2s
    Maybe Close Popup
    Close Other JupyterLab Tabs
    Maybe Close Popup
    Sleep    1
    ${ouput1}=  Run Cell And Get Output    !git clone ${githublink}
    Sleep  15
    Open With JupyterLab Menu  File  Open from Path…
    Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  ${filepath}
    Click Element  xpath://div[.="Open"]

    #
    Sleep    1s
    Maybe Close Popup
    Sleep    1s
    Wait Until JupyterLab Code Cell Is Not Active
    Run Cell And Get Output  print("Hi Hello")
    Add and Run JupyterLab Code Cell in Active Notebook  print("Hi Hello")
    Sleep    2s
    Open With JupyterLab Menu  File  Save Notebook
    Sleep    1s
    Open With JupyterLab Menu  Git  Simple staging
    Click Element   xpath=//*[@id="tab-key-6"]/div[1]
    Log to Console  After clicking on git icon
    #-------------------
    ${randnum}=  Generate Random String  9  [NUMBERS]
    Input Text    xpath=//*[@id="jp-git-sessions"]/div/form/input[1]    ${commitmsg} ${randnum}
    #click on commit button
    Sleep    2s
    Click Button    xpath=//*[@id="jp-git-sessions"]/div/form/input[2]   #or //*[@class='f58vw4a']
    Log to Console  After putting commit message and clicking on commit

    Wait Until Page Contains  Who is committing?

    Input Text    //input[@class='jp-mod-styled'][1]    ${name}
    Input Text    //input[@class='jp-mod-styled'][2]    ${email_id}


    Click Element    //button[@class='jp-Dialog-button jp-mod-accept jp-mod-styled']//div[2]    #click on submit
    Sleep   5s
    #click on push to remote
    Open With JupyterLab Menu    Git    Push to Remote
    Log To Console    after clicking on push to remote
    Wait Until Page Contains    Git credentials required  timeout=200s

    # enter the credentials username and password

    Input Text    //input[@class='jp-mod-styled'][1]    ${gitusername}
    Input Text    //input[@class='jp-mod-styled'][2]    ${gittoken}
    Click Element    //button[@class='jp-Dialog-button jp-mod-accept jp-mod-styled']//div[2]    #click on submit

    Sleep  5s
    Open With JupyterLab Menu  Git  Simple staging
    Close All JupyterLab Tabs
    sleep  2s
#    Close Other JupyterLab Tabs
    Open With JupyterLab Menu  File  New  Notebook
    Sleep  5s
    Maybe Close Popup
    Wait Until JupyterLab Code Cell Is Not Active

    Add and Run JupyterLab Code Cell in Active Notebook  !git log --name-status HEAD^..HEAD
    ${output}=  Run Cell And Get Output    !git log --name-status HEAD^..HEAD

    sleep  2s
    ${contains}=  Evaluate   "${commitmsg} ${randnum}" in """${output}"""
    Should Be Equal     ${True}    ${contains}
