*** Settings ***
Documentation    Tests for the NB culler
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          JupyterLibrary
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
${DEFAULT_CULLER_TIMEOUT} =    31536000
${CUSTOM_CULLER_TIMEOUT} =     600


*** Test Cases ***
Verify Default Culler Timeout
    [Documentation]    Checks default culler timeout
    [Tags]  Sanity
    ${current_timeout} =  Get Culler Timeout
    Should Be Equal  ${DEFAULT_CULLER_TIMEOUT}  ${current_timeout}

Verify Culler Timeout Can Be Updated
    [Documentation]    Verifies culler timeout can be updated
    [Tags]  Sanity
    # Modify Culler Timeout    ${CUSTOM_CULLER_TIMEOUT}
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
    Open With JupyterLab Menu    File    Save
    Close Browser
    Sleep    ${CUSTOM_CULLER_TIMEOUT}+60
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
    Add and Run JupyterLab Code Cell in Active Notebook    import time;print("Hello");time.sleep(${CUSTOM_CULLER_TIMEOUT}*2);print("Goodbye")
    Open With JupyterLab Menu    File    Save
    Close Browser
    Sleep    ${CUSTOM_CULLER_TIMEOUT}+60
    # Verify User Pod Is Running
    # Verify Culler Logs ?

# Verify Do Not Stop Idle Notebooks
    # Unclear what this UI option will do

*** Keywords ***
Spawn Minimal Image
    [Documentation]    Spawn a minimal image
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=s2i-minimal-notebook  size=Default

Get Culler Pod
    [Documentation]    Finds the current culler pod and returns the name
    ${culler_pod_name} =  Run  oc get pod ...
    [Return]  ${culler_pod_name}

Get Culler Timeout
    [Documentation]    Gets the current culler timeout
    ${current_timeout} =  Run  oc describe configmap jupyterhub-cfg -n redhat-ods-applications | grep -zoP '(culler_timeout:\n----\n)\d+\n' | grep -zoP "\d+"
    # jupyterhub-idle-culler-[0-9]+-[a-zA-Z0-9]{5}
    # What if multiple returned? name1name2 attached together, check length of name
    # length should be 30 or 31 chars (double digit on the rollout ID) [IF USING -z OPTION FOR GREP]
    # [WITHOUT -z OPTION] both names returned on two lines, can do "split lines" or similar and check no. of items (probably better)
    # ${CULLER_POD} =  Run  oc get pod -l app=jupyterhub-idle-culler -n redhat-ods-applications | grep -zoP jupyterhub-idle-culler-[0-9]+-[a-zA-Z0-9]{5}
    ${culler-env-timeout} =  Run  oc exec ${CULLER_POD} -n redhat-ods-applications -- printenv CULLER_TIMEOUT
    Should Be Equal  ${current_timeout}  ${culler-env-timeout}
    [Return]  ${current_timeout}

Modify Culler Timeout
    [Documentation]    Modifies the culler timeout via UI
    [Arguments]    ${new_timeout}
    PASS

Set Default Culler Timeout
    [Documentation]    Sets the default culler timeout via UI
    Modify Culler Timeout  ${DEFAULT_CULLER_TIMEOUT}

Teardown
    [Documentation]    Teardown for the test
    Set Default Culler Timeout
    End Web Test
