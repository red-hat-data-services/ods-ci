*** Settings ***
Documentation    Tests for the NB culler
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          ../../../libs/Helpers.py
Library          JupyterLibrary
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
${DEFAULT_CULLER_TIMEOUT} =    31536000
${CUSTOM_CULLER_TIMEOUT} =     300


*** Test Cases ***
Verify Default Culler Timeout
    [Documentation]    Checks default culler timeout
    [Tags]  Sanity
    ${current_timeout} =  Get Culler Timeout
    Should Be Equal  ${DEFAULT_CULLER_TIMEOUT}  ${current_timeout}

Verify Culler Timeout Can Be Updated
    [Documentation]    Verifies culler timeout can be updated
    [Tags]  Sanity
    Modify Culler Timeout    ${CUSTOM_CULLER_TIMEOUT}
    # Try out invalid timeouts? 
    # Verify UI default == configmap default?
    ${current_timeout} =  Get Culler Timeout
    Should Not Be Equal  ${current_timeout}  ${DEFAULT_CULLER_TIMEOUT}
    Should Be Equal   ${current_timeout}  ${CUSTOM_CULLER_TIMEOUT}
    # Run  oc exec ${CULLER_POD} -n redhat-ods-applications -- printenv CULLER_TIMEOUT
    # jupyterhub-idle-culler-[0-9]+-[a-zA-Z0-9]{5}
    # What if multiple returned? name1name2 attached together, check length of name
    # length should be 30 or 31 chars (double digit on the rollout ID) [IF USING -z OPTION FOR GREP]
    # [WITHOUT -z OPTION] both names returned on two lines, can do "split lines" or similar and check no. of items (probably better)
    # ${CULLER_POD} =  Run  oc get pod -l app=jupyterhub-idle-culler -n redhat-ods-applications | grep -zoP jupyterhub-idle-culler-[0-9]+-[a-zA-Z0-9]{5}

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
    Run Keyword And Expect Error  Pods not found in search  Search Pods  ${notebook_pod_name}  namespace=rhods-notebooks
    # Verify User Pod Is Not Running
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
    Add and Run JupyterLab Code Cell in Active Notebook    import time;print("Hello");time.sleep(${${CUSTOM_CULLER_TIMEOUT}*2});print("Goodbye")
    Open With JupyterLab Menu    File    Save Notebook
    Close Browser
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+60}
    ${pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    Search Pods  ${notebook_pod_name}  namespace=rhods-notebooks
    # Verify User Pod Is Running
    # Verify Culler Logs ?

# Verify Do Not Stop Idle Notebooks
    # Unclear what this UI option will do

*** Keywords ***
Spawn Minimal Image
    [Documentation]    Spawn a minimal image
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=s2i-minimal-notebook  size=Default

Get Culler Pod
    [Documentation]    Finds the current culler pod and returns the name
    ${culler_pod_name} =  Run  oc get pod -l app=jupyterhub-idle-culler -n redhat-ods-applications | grep -zoP jupyterhub-idle-culler-[0-9]+-[a-zA-Z0-9]{5}
    [Return]  ${culler_pod_name}

Get Culler Timeout
    [Documentation]    Gets the current culler timeout
    #${current_timeout} =  Run  oc describe configmap jupyterhub-cfg -n redhat-ods-applications | grep -zoP "(culler_timeout:${\n}----${\n})\d+${\n}" | grep -zoP "\d+"
    ${current_timeout} =  Run  oc describe configmap jupyterhub-cfg -n redhat-ods-applications
    Log  ${current_timeout}
    # 	Name:         jupyterhub-cfg
    #Namespace:    redhat-ods-applications
    #Labels:       app=jupyterhub
    #Annotations:  <none>
    #
    #Data
    #====
    #jupyterhub_admins:
    #----
    #admin
    #jupyterhub_config.py:
    #----
    #
    #notebook_destination:
    #----
    #rhods-notebooks
    #singleuser_pvc_size:
    #----
    #20Gi
    #culler_timeout:
    #----
    #300
    #gpu_mode:
    #----
    #
    #
    #BinaryData
    #====
    #
    #Events:  <none>
    
    # jupyterhub-idle-culler-[0-9]+-[a-zA-Z0-9]{5}
    # What if multiple returned? name1name2 attached together, check length of name
    # length should be 30 or 31 chars (double digit on the rollout ID) [IF USING -z OPTION FOR GREP]
    # [WITHOUT -z OPTION] both names returned on two lines, can do "split lines" or similar and check no. of items (probably better)
    ${CULLER_POD} =  Get Culler Pod
    ${culler-env-timeout} =  Run  oc exec ${CULLER_POD} -n redhat-ods-applications -- printenv CULLER_TIMEOUT
    Should Be Equal  ${current_timeout}  ${culler-env-timeout}
    [Return]  ${current_timeout}

Modify Culler Timeout
    [Documentation]    Modifies the culler timeout via UI
    [Arguments]    ${new_timeout}
    Open Dashboard Cluster Settings
    ${hours}  ${minutes} =  Convert To Hours And Minutes  ${new_timeout}
    Set Timeout To  ${hours}  ${minutes}

Open Dashboard Cluster Settings
    Begin Web Test
    Sleep  5
    ${settings_hidden} =  Run Keyword And Return Status  Page Should Contain Element  xpath://section[@aria-labelledby="settings"][@hidden=""]
    IF  ${settings_hidden}==True
        Click Element  xpath://button[@id="settings"]
        Click Element  xpath://a[.="Cluster settings"]
    END

Set Timeout To
    [Documentation]    Helper to modify culler timeout via UI
    [Arguments]    ${hours}    ${minutes}
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status  Page Should Contain Element  //input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==True
        Click Element  xpath://input[@id="culler-timeout-limited"]
    END
    Input Text  //input[@id="hour-input"]  ${hours}
    Input Text  //input[@id="minute-input"]  ${minutes}

Set Default Culler Timeout
    [Documentation]    Sets the default culler timeout via UI
    # Modify Culler Timeout  ${DEFAULT_CULLER_TIMEOUT}
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status  Page Should Contain Element  //input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==False
        Click Element  xpath://input[@id="culler-timeout-unlimited"]
    END

Teardown
    [Documentation]    Teardown for the test
    Set Default Culler Timeout
    End Web Test
