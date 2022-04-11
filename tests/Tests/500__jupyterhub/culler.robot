*** Settings ***
Documentation    Tests for the NB culler
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Library          ../../../libs/Helpers.py
Library          OpenShiftLibrary
#Library         JupyterLibrary
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
${DEFAULT_CULLER_TIMEOUT} =    31536000
${CUSTOM_CULLER_TIMEOUT} =     300


*** Test Cases ***
Verify Default Culler Timeout
    [Documentation]    Checks default culler timeout
    [Tags]  Sanity
    Disable Culler
    ${current_timeout} =  Get Culler Timeout
    Should Be Equal  ${DEFAULT_CULLER_TIMEOUT}  ${current_timeout}
    Close Browser

Verify Culler Timeout Can Be Updated
    [Documentation]    Verifies culler timeout can be updated
    [Tags]  Sanity
    Modify Culler Timeout    ${CUSTOM_CULLER_TIMEOUT}
    ${current_timeout} =  Get Culler Timeout
    Should Not Be Equal  ${current_timeout}  ${DEFAULT_CULLER_TIMEOUT}
    Should Be Equal   ${current_timeout}  ${CUSTOM_CULLER_TIMEOUT}
    Close Browser

Verify Culler Kills Inactive Server
    [Documentation]    Verifies that the culler kills an inactive 
    ...    server after timeout has passed.
    [Tags]  Sanity
    Spawn Minimal Image
    Run Cell And Check Output  print("Hello World")  Hello World
    Open With JupyterLab Menu    File    Save Notebook
    Close Browser
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+60}
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    Run Keyword And Expect Error  Pods not found in search  OpenShiftLibrary.Search Pods  ${notebook_pod_name}  namespace=rhods-notebooks
    # Verify Culler Logs ?
    # [I 220331 15:02:13 __init__:191] Culling server ${username} (inactive for 00:02:09)
    #    ^date  ^timestamp                            ^not jh naming            ^strictly greater than ${CUSTOM_CULLER_TIMEOUT}
    # from datetime import timedelta;td=timedelta(seconds=${CUSTOM_CULLER_TIMEOUT});print(td) -> gets timeout in hh:mm:ss
    # grep from log -> td2 = timedelta(hours=HH, minutes=MM, seconds=SS); td2>td 

Verify Culler Does Not Kill Active Server
    [Documentation]    Verifies that the culler does not kill an active 
    ...    server even after timeout has passed.
    [Tags]  Sanity
    Spawn Minimal Image
    # Need to update with nb that keeps printing otherwise it's considered inactive
    Add and Run JupyterLab Code Cell in Active Notebook    import time;print("Hello");time.sleep(${${CUSTOM_CULLER_TIMEOUT}*2});print("Goodbye")
    Open With JupyterLab Menu    File    Save Notebook
    Close Browser
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+60}
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    OpenShiftLibrary.Search Pods  ${notebook_pod_name}  namespace=rhods-notebooks
    # Verify Culler Logs ?

Verify Do Not Stop Idle Notebooks
    Disable Culler
    Close Browser
    Spawn Minimal Image
    Run Cell And Check Output  print("Hello World")  Hello World
    Open With JupyterLab Menu    File    Save Notebook
    Close Browser
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+60}
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    OpenShiftLibrary.Search Pods  ${notebook_pod_name}  namespace=rhods-notebooks

*** Keywords ***
Spawn Minimal Image
    [Documentation]    Spawn a minimal image
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=s2i-minimal-notebook  size=Default

Get Culler Pod
    [Documentation]    Finds the current culler pod and returns the name
    #${culler_pod_name} =  Run  oc get pod -l app=jupyterhub-idle-culler -n redhat-ods-applications | grep -zoP jupyterhub-idle-culler-[0-9]+-[a-zA-Z0-9]{5}
    ${culler_pod} =  OpenShiftLibrary.Oc Get  kind=Pod  label_selector=app=jupyterhub-idle-culler  namespace=redhat-ods-applications
    ${length} =  Get Length  ${culler_pod}
    # Only 1 culler pod, correct one
    IF  ${length}==1
        ${culler_pod_name} =  Set Variable  ${culler_pod[0]}[metadata][name]
    ELSE
    # There can be more than one during rollout
        Sleep  10s
        ${culler_pod_name} =  Get Culler Pod
        #FOR  ${pod}  IN  @{culler_pod}
        #    Log  ${pod}
        #    IF  ${pod}[status][phase]=='Running'
        #        ${culler_pod_name} =  Set Variable  ${pod}[metadata][name]
        #    END
        #END
    END
    Log  ${culler_pod}
    Log  ${culler_pod_name}
    [Return]  ${culler_pod_name}

Get Culler Timeout
    [Documentation]    Gets the current culler timeout
    ${current_timeout} =  OpenShiftLibrary.Oc Get  kind=ConfigMap  name=jupyterhub-cfg  namespace=redhat-ods-applications  fields=['data.culler_timeout']
    ${current_timeout} =  Set Variable  ${current_timeout[0]['data.culler_timeout']}
    Log  ${current_timeout}
    Log To Console  ${current_timeout}
    ${CULLER_POD} =  Get Culler Pod
    ${culler-env-timeout} =  Run  oc exec ${CULLER_POD} -n redhat-ods-applications -- printenv CULLER_TIMEOUT
    Should Be Equal  ${current_timeout}  ${culler-env-timeout}
    [Return]  ${current_timeout}

Modify Culler Timeout
    [Documentation]    Modifies the culler timeout via UI
    [Arguments]    ${new_timeout}
    Open Dashboard Cluster Settings
    Set Timeout To  ${new_timeout}
    # Enough time to start the rollout
    Sleep  60s

Open Dashboard Cluster Settings
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Sleep  5
    ${settings_hidden} =  Run Keyword And Return Status  Page Should Contain Element  xpath://section[@aria-labelledby="settings"][@hidden=""]
    IF  ${settings_hidden}==True
        Click Element  xpath://button[@id="settings"]
    END
    Click Element  xpath://a[.="Cluster settings"]

Set Timeout To
    [Documentation]    Helper to modify culler timeout via UI
    [Arguments]    ${new_timeout}
    ${hours}  ${minutes} =  Convert To Hours And Minutes  ${new_timeout}
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status  Page Should Contain Element  //input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==True
        Click Element  xpath://input[@id="culler-timeout-limited"]
    END
    Input Text  //input[@id="hour-input"]  ${hours}
    Input Text  //input[@id="minute-input"]  ${minutes}

Disable Culler
    [Documentation]    Disables the culler (i.e. sets the default timeout of 1 year)
    # Modify Culler Timeout  ${DEFAULT_CULLER_TIMEOUT}
    Open Dashboard Cluster Settings
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status  Page Should Contain Element  //input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==False
        Click Element  xpath://input[@id="culler-timeout-unlimited"]
    END

Teardown
    [Documentation]    Teardown for the test
    Disable Culler
    Launch JupyterHub Spawner From Dashboard
    End Web Test
