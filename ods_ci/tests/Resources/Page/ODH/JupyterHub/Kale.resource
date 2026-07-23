*** Settings ***
Documentation    Keywords to interact with Kale in JupyterLab
Resource         ../../LoginPage.robot
Resource         JupyterLabLauncher.robot
Resource         ../ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource         ../ODHDashboard/ODHDashboard.robot
Resource         ../../../CLI/DataSciencePipelines/DataSciencePipelinesBackend.resource
Library          SeleniumLibrary
Library          String
Library          Collections


*** Variables ***
${KALE_EXTENSION_NAME} =    jupyterlab-kubeflow-kale
${KALE_PANEL_ID} =    jupyterlab-kubeflow-kale/kubeflowDeployment
${KALE_SIDEBAR_ICON_XP} =    //li[@data-id="jupyterlab-kubeflow-kale/kubeflowDeployment"] | //div[contains(@class,"jp-ActivityBar")]//li[contains(@title,"Kubeflow") or contains(@title,"Kale") or contains(@title,"Deployment")] | //div[contains(@class,"jp-ActivityBar")]//button[contains(@aria-label,"Kale") or contains(@aria-label,"Kubeflow")]
${KALE_PANEL_XP} =    //div[contains(@class, "kale-panel")]
${KALE_ENABLE_SWITCH_XP} =    ${KALE_PANEL_XP}//input[@name="enableKale" and @type="checkbox"]
# Visible control wrapping the (often hidden) enableKale checkbox input
${KALE_ENABLE_SWITCH_CLICK_XP} =    ${KALE_ENABLE_SWITCH_XP}/ancestor::label[1] | ${KALE_ENABLE_SWITCH_XP}/..
${KALE_PIPELINE_NAME_INPUT_XP} =    ${KALE_PANEL_XP}//label[contains(translate(., "PIPELINE NAME", "pipeline name"), "pipeline name")]/..//input | ${KALE_PANEL_XP}//input[contains(@name,"pipeline") or contains(@id,"pipeline") or contains(@placeholder,"ipeline")]
${KALE_COMPILE_AND_RUN_BTN_XP} =    ${KALE_PANEL_XP}//button[contains(., "Compile and Run")]
${KALE_UNSAVED_CHANGES_DIALOG_XP} =    //dialog[contains(@class, "jp-Dialog")]//*[contains(@class, "jp-Dialog-header")][contains(., "Unsaved Changes")]
${KALE_UNSAVED_CHANGES_YES_BTN_XP} =    //dialog[contains(@class, "jp-Dialog")]//button[contains(@class, "jp-mod-accept")]
${KALE_NOTEBOOK_TAB} =    candies_sharing.ipynb


*** Keywords ***
Enable Kale Extension
    [Documentation]    Some workbench images have Kale installed but its JupyterLab extension
    ...    disabled by default. Checks whether the Kale icon is present in the left sidebar and,
    ...    if not, enables the extension via ``oc exec`` when a workbench is provided, otherwise
    ...    by running ``jupyter labextension enable`` in a temporary notebook.
    ...    The page is then reloaded so the extension becomes active in JupyterLab.
    ...    ${notebook_path} (optional) is reopened after the reload.
    [Arguments]    ${notebook_path}=${NONE}    ${extension_name}=${KALE_EXTENSION_NAME}
    ...    ${workbench_title}=${NONE}    ${project_title}=${NONE}
    ${enabled} =    Run Keyword And Return Status
    ...    Page Should Contain Element    xpath=${KALE_SIDEBAR_ICON_XP}
    IF    not ${enabled}
        Log    Kale icon not found in sidebar, attempting to enable "${extension_name}"    console=True
        IF    '${workbench_title}' != '${NONE}' and '${project_title}' != '${NONE}'
            Enable Kale Extension Via Oc Exec    ${workbench_title}    ${project_title}    ${extension_name}
            Wait Until Workbench Pod Is Ready    ${project_title}    ${workbench_title}
            # Pod recreate kills the JupyterLab session; Reload Page alone hangs on a dead route.
            Reconnect To JupyterLab After Workbench Restart
        ELSE
            Enable Kale Extension Via CLI In Throwaway Notebook    ${extension_name}
            Reload Page
            Wait Until Page Contains Element    xpath://div[@id="jp-top-panel"]    timeout=120s
        END
        Maybe Close Popup
        IF    "${notebook_path}" != "${NONE}"
            Open Notebook From Path    ${notebook_path}
        END
        Wait Until Page Contains Element    xpath=${KALE_SIDEBAR_ICON_XP}    timeout=120s
    END

Reconnect To JupyterLab After Workbench Restart
    [Documentation]    Re-opens JupyterLab after the workbench pod was recreated.
    ...    Waits until the notebook route serves JupyterLab again (not "Application is not available").
    ${url}=    Get Location
    Wait Until Keyword Succeeds    24 times    5s
    ...    JupyterLab Is Reachable At Url    ${url}

JupyterLab Is Reachable At Url
    [Documentation]    Navigates to ${url} and authenticates into JupyterLab if needed
    [Arguments]    ${url}
    Go To    ${url}
    ${app_not_available}=    Run Keyword And Return Status
    ...    Page Should Contain    Application is not available
    IF    ${app_not_available}
        Fail    Workbench route not ready yet
    END
    # Keep login/retry logic local to Kale so shared Access To Workbench / LoginPage stay untouched.
    Access Kale Workbench    username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}

Access Kale Workbench
    [Documentation]    Authenticates into JupyterLab after a workbench route is up.
    ...    Handles IdP selection and the htpasswd password form without changing LoginPage.
    [Arguments]    ${username}    ${password}    ${auth_type}
    Run Keyword And Warn On Failure    Wait Until Page Contains    Log in with OpenShift    timeout=15s
    ${oauth_prompt_visible}=    Is OpenShift OAuth Login Prompt Visible
    IF    ${oauth_prompt_visible}    Click Button    Log in with OpenShift
    ${select_auth_type}=    Run Keyword And Return Status
    ...    Wait Until Page Contains    Log in with    timeout=5s
    IF    ${select_auth_type}
        Select Login Authentication Type    ${auth_type}
    END
    ${password_form}=    Run Keyword And Return Status
    ...    Wait Until Page Contains    Log in to your account    timeout=10s
    IF    ${password_form}
        Input Text    id=inputUsername    ${username}
        Input Text    id=inputPassword    ${password}
        Click Button    //*[@type="submit"]
        Wait Until Page Does Not Contain    Log in to your account    timeout=30s
    END
    Wait Until Page Contains Element    xpath://div[@id="jp-top-panel"]    timeout=90s
    Maybe Close Popup

Ensure Kale Project Can Pull Red Hat Images
    [Documentation]    CLI-created projects only get the default dockercfg pull secret. DSPA MariaDB/
    ...    Service Mesh images come from registry.redhat.io and need the cluster pull-secret
    ...    (same as namespaces created/configured for RhoAI). Copies openshift-config/pull-secret
    ...    into the project and links it to the default SA. Idempotent.
    [Arguments]    ${namespace}
    ${rc}=    Run And Return Rc    oc get secret rh-pull-secret -n ${namespace}
    IF    ${rc} != ${0}
        Run And Verify Command    oc get secret pull-secret -n openshift-config -o json | jq 'del(.metadata.uid,.metadata.resourceVersion,.metadata.creationTimestamp,.metadata.namespace,.metadata.annotations."kubernetes.io/service-account.name",.metadata.annotations."kubernetes.io/service-account.uid") | .metadata.name="rh-pull-secret" | .metadata.namespace="${namespace}" | .type="kubernetes.io/dockerconfigjson"' | oc apply -f -
    END
    Run And Verify Command    oc secrets link default rh-pull-secret --for=pull -n ${namespace}

Wait Until Kale Pipeline Server Is Deployed
    [Documentation]    Same check as DataSciencePipelinesBackend.Wait Until Pipeline Server Is Deployed,
    ...    with a longer timeout suitable for first-time DSPA image pulls on slow clusters.
    [Arguments]    ${namespace}
    Wait Until Keyword Succeeds    36 times    10s
    ...    DataSciencePipelinesBackend.Verify Pipeline Server Deployments    namespace=${namespace}

Maybe Patch Kale Pipeline Server Images
    [Documentation]    Optional DSPA image overrides from test-variables (PIPELINE_MARIADB_IMAGE /
    ...    PIPELINE_MLMD_ENVOY_IMAGE). No-op when those variables are unset.
    [Arguments]    ${namespace}
    ${mariadb_image}=    Get Variable Value    ${PIPELINE_MARIADB_IMAGE}    ${EMPTY}
    ${mlmd_envoy_image}=    Get Variable Value    ${PIPELINE_MLMD_ENVOY_IMAGE}    ${EMPTY}
    IF    '${mariadb_image}' == '${EMPTY}' and '${mlmd_envoy_image}' == '${EMPTY}'
        RETURN
    END
    ${patch_parts}=    Create List
    IF    '${mariadb_image}' != '${EMPTY}'
        Append To List    ${patch_parts}    "database":{"mariaDB":{"image":"${mariadb_image}"}}
    END
    IF    '${mlmd_envoy_image}' != '${EMPTY}'
        Append To List    ${patch_parts}    "mlmd":{"deploy":true,"envoy":{"image":"${mlmd_envoy_image}"}}
    END
    ${patch_body}=    Evaluate    ','.join($patch_parts)
    ${patch}=    Set Variable    {"spec":{${patch_body}}}
    Wait Until Keyword Succeeds    5x    15s
    ...    Run And Verify Command    oc patch dspa dspa -n ${namespace} --type=merge -p '${patch}'
    Sleep    10s    reason=Allow DSPA operator to reconcile image overrides

Dismiss Open Patternfly Menus
    [Documentation]    Closes leftover PatternFly listboxes that intercept later clicks
    ...    (common after selecting a workbench image on PF6).
    Press Keys    None    ESCAPE
    Run Keyword And Ignore Error
    ...    Wait Until Page Does Not Contain Element
    ...    xpath=//ul[@role='listbox' and contains(@class,'menu__list')]
    ...    timeout=5s

Create Kale Workbench
    [Documentation]    Same flow as Create Workbench, but dismisses open PF menus after image
    ...    selection and clicks the hardware profile via JS so shared Workbenches/Spawner
    ...    keywords do not need PF6 menu fixes.
    [Arguments]    ${workbench_title}    ${workbench_description}    ${prj_title}    ${image_name}
    ...    ${hardware_profile}    ${storage}    ${pv_existent}    ${pv_name}    ${pv_description}
    ...    ${pv_size}    ${version}=${NONE}    ${envs}=${NONE}
    Open Data Science Project Details Page    project_title=${prj_title}    tab_id=workbenches
    Wait Until Element Is Enabled    ${WORKBENCH_CREATE_BTN_XP}
    Click Element    ${WORKBENCH_CREATE_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_NAME_INPUT_XP}
    Input Text    ${WORKBENCH_NAME_INPUT_XP}    ${workbench_title}
    Input Text    ${WORKBENCH_DESCR_TXT_XP}    ${workbench_description}
    Select Workbench Image    image_name=${image_name}    version=${version}
    Dismiss Open Patternfly Menus
    IF    "${hardware_profile}" != "${NONE}"
        Wait Until Page Contains Element    ${WORKBENCH_SIZE_SIDE_MENU_BTN}
        Click Element    ${WORKBENCH_SIZE_SIDE_MENU_BTN}
        Dismiss Open Patternfly Menus
        Select Kale Hardware Profile    ${hardware_profile}
    END
    IF    "${envs}" != "${NONE}"
        ${envs_copy}=    Copy List    ${envs}    deepcopy=${TRUE}
        Add Environment Variables In Workbench    env_variables=${envs_copy}
    END
    IF    "${storage}" == "Persistent"
        IF    ${pv_existent} == ${FALSE}
            Delete PVC In Project From CLI    pvc_title=${pv_name}    project_title=${prj_title}
            Click Element    //a[@href="#cluster-storage"]
            Click Element    //*[@data-testid="create-storage-button"]
            Fill In New PV Data    name=${pv_name}    size=${pv_size}    description=${pv_description}
            Click Button    ${STORAGE_SUBMIT_BTN_XP}
        END
    END
    Wait Until Element Is Enabled    ${WORKBENCH_CREATE_BTN_2_XP}
    Click Button    ${WORKBENCH_CREATE_BTN_2_XP}
    Wait Until Element Is Not Visible    //form    10s
    Open Data Science Project Details Page    project_title=${prj_title}    tab_id=workbenches

Select Kale Hardware Profile
    [Documentation]    Selects a hardware profile via JS click (avoids PF listbox interception)
    [Arguments]    ${hardware_profile}
    ${dropdown_xpath}=    Set Variable    xpath://button[@data-testid="hardware-profile-select"]
    Wait Until Page Contains Element    ${dropdown_xpath}    timeout=10s
    Click Element    ${dropdown_xpath}
    ${profile_option_xpath}=    Set Variable
    ...    xpath://ul[@role='listbox']//span[normalize-space()="${hardware_profile}"]/ancestor::button[1]
    Wait Until Page Contains Element    ${profile_option_xpath}    timeout=10s
    ${profile_option}=    Get WebElement    ${profile_option_xpath}
    Execute Javascript    arguments[0].click();    ARGUMENTS    ${profile_option}
    Dismiss Open Patternfly Menus

Patch Workbench Notebook Image Tag Via CLI
    [Documentation]    Switches a workbench to a specific notebook image tag via oc patch.
    ...    Kale requires a 3.5+ Data Science image, but some clusters only expose older tags in the UI dropdown.
    [Arguments]    ${workbench_title}    ${project_title}    ${image_tag}
    ${ns_name}=    Get Openshift Namespace From Data Science Project    project_title=${project_title}
    ${_}    ${cr_name}=    Get Openshift Notebook CR From Workbench
    ...    workbench_title=${workbench_title}    namespace=${ns_name}
    ${image}=    Run    oc get imagestream s2i-generic-data-science-notebook -n ${APPLICATIONS_NAMESPACE} -o jsonpath='{.status.dockerImageRepository}:${image_tag}' 2>&1
    Run And Verify Command    oc patch notebook ${cr_name} -n ${ns_name} --type=json -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "${image}"}]' 2>&1

Enable Kale Extension Via Oc Exec
    [Documentation]    Enables the Kale labextension inside the running workbench pod and restarts it.
    ...    The 3.5+ Data Science image ships Kale disabled in sys-prefix page_config.json.
    ...    ``jupyter labextension enable`` only patches that ephemeral path, so a bare pod
    ...    delete undoes the change. Persist the enable under ``$HOME/.jupyter/labconfig``
    ...    (PVC-backed), then recreate the pod so JupyterLab starts with Kale enabled.
    [Arguments]    ${workbench_title}    ${project_title}    ${extension_name}=${KALE_EXTENSION_NAME}
    ${ns_name}    ${cr_name}    ${_}=    Get Workbench Pod    workbench_title=${workbench_title}
    ...    project_title=${project_title}
    ${rc}    ${extensions}=    Run And Return Rc And Output
    ...    oc exec -n ${ns_name} ${cr_name}-0 -- jupyter labextension list 2>&1
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${extensions}    ${extension_name}
    ...    msg=Kale extension "${extension_name}" is not installed in workbench image — use a 3.5+ Data Science image
    # Persist enable on the workbench PVC before restart (survives image page_config defaults)
    Run And Verify Command    oc exec -n ${ns_name} ${cr_name}-0 -- python3 -c "from pathlib import Path; import json; p=Path.home()/'.jupyter'/'labconfig'/'page_config.json'; p.parent.mkdir(parents=True, exist_ok=True); cfg=json.loads(p.read_text()) if p.exists() else {}; cfg.setdefault('disabledExtensions', {})['${extension_name}']=False; p.write_text(json.dumps(cfg, indent=2)+chr(10))"
    Run And Verify Command    oc exec -n ${ns_name} ${cr_name}-0 -- jupyter labextension enable ${extension_name} 2>&1
    ${rc}    ${enabled}=    Run And Return Rc And Output
    ...    oc exec -n ${ns_name} ${cr_name}-0 -- jupyter labextension list 2>&1 | grep -i ${extension_name}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${enabled}    enabled
    Run And Verify Command    oc delete pod ${cr_name}-0 -n ${ns_name} --wait=true 2>&1

Wait Until Workbench Pod Is Ready
    [Documentation]    Waits until the workbench pod is running and its main container is ready
    [Arguments]    ${project_title}    ${workbench_title}
    ${ns_name}    ${cr_name}    ${_}=    Get Workbench Pod    workbench_title=${workbench_title}
    ...    project_title=${project_title}
    Wait Until Keyword Succeeds    30 times    10s
    ...    Workbench Pod Container Is Ready    ${ns_name}    ${cr_name}

Workbench Pod Container Is Ready
    [Documentation]    Verifies the workbench pod main container reports ready=true
    [Arguments]    ${namespace}    ${cr_name}
    ${rc}    ${ready}=    Run And Return Rc And Output
    ...    oc get pod ${cr_name}-0 -n ${namespace} -o jsonpath='{.status.containerStatuses[?(@.name=="${cr_name}")].ready}' 2>&1
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal As Strings    ${ready}    true

Enable Kale Extension Via CLI In Throwaway Notebook
    [Documentation]    Enables the Kale labextension without modifying the pipeline notebook.
    ...    Shell commands must use the ``!`` prefix because they run in a Jupyter code cell, not a terminal.
    [Arguments]    ${extension_name}=${KALE_EXTENSION_NAME}
    Open New Notebook
    Maybe Close Popup
    Run Cell And Check Output    !jupyter labextension enable ${extension_name} 2>&1
    ...    Enabling: ${extension_name}
    Close JupyterLab Selected Tab
    Maybe Close Popup
    Wait Until ${KALE_NOTEBOOK_TAB} JupyterLab Tab Is Selected

Open Notebook From Path
    [Documentation]    Opens an already-cloned notebook given its path relative to the JupyterLab root,
    ...    without cloning the git repository again. Used to reopen a notebook after a page reload.
    [Arguments]    ${notebook_path}
    Open With JupyterLab Menu    File    Open from Path…
    Input Text    xpath=//input[@placeholder="/path/relative/to/jlab/root"]    ${notebook_path}
    Click Element    xpath://div[.="Open"]
    Maybe Close Popup
    Wait Until ${KALE_NOTEBOOK_TAB} JupyterLab Tab Is Selected

Verify Kale Notebook Elements
    [Documentation]    Verifies that the Kale candies_sharing sample notebook is open and contains
    ...    the expected annotated cells before pipeline compilation
    Wait Until ${KALE_NOTEBOOK_TAB} JupyterLab Tab Is Selected
    Wait Until Page Contains    Kale base example    timeout=30s
    Page Should Contain    CANDIES = 20
    Page Should Contain    def get_handful
    Page Should Contain    Let's put in a bag

Open Kale Panel
    [Documentation]    Opens the Kale sidebar panel in JupyterLab
    ${panel_visible} =    Run Keyword And Return Status
    ...    Page Should Contain Element    xpath=${KALE_PANEL_XP}
    IF    not ${panel_visible}
        Click Element    xpath=${KALE_SIDEBAR_ICON_XP}
    END
    Wait Until Page Contains Element    xpath=${KALE_PANEL_XP}    timeout=30s
    Wait Until Page Contains    Pipeline Metadata    timeout=30s

Enable Kale
    [Documentation]    Enables Kale pipeline mode in the Kale sidebar.
    ...    The enable control is a styled switch; the checkbox input itself is often
    ...    not interactable, so toggle it via JavaScript.
    Open Kale Panel
    Wait Until Page Contains Element    xpath=${KALE_ENABLE_SWITCH_XP}    timeout=30s
    ${is_enabled} =    Execute Javascript
    ...    return !!(document.querySelector('div.kale-panel input[name="enableKale"]')||{}).checked
    IF    not ${is_enabled}
        Execute Javascript
        ...    (function(){var el=document.querySelector('div.kale-panel input[name="enableKale"]'); if(!el){throw new Error('enableKale input not found');} if(!el.checked){el.click();} })()
        Wait Until Keyword Succeeds    10x    1s
        ...    Kale Enable Switch Should Be On
    END
    Wait Until Element Is Enabled    xpath=${KALE_COMPILE_AND_RUN_BTN_XP}    timeout=60s

Kale Enable Switch Should Be On
    [Documentation]    Asserts the Kale enable checkbox is checked (via JS; avoids Selenium interactability issues)
    ${is_enabled} =    Execute Javascript
    ...    return !!(document.querySelector('div.kale-panel input[name="enableKale"]')||{}).checked
    Should Be True    ${is_enabled}

Set Kale Pipeline Name
    [Documentation]    Sets the pipeline name in the Kale sidebar before compile/run.
    ...    Kale uses an MUI TextField labeled "Pipeline Name" (React-controlled). Selenium
    ...    cannot type into it reliably, so the value is set via the native input value
    ...    setter + input event. Execute Javascript must use a top-level ``return`` or
    ...    Selenium returns ``None``.
    [Arguments]    ${pipeline_name}
    Wait Until Keyword Succeeds    15x    1s
    ...    Kale Pipeline Name Field Should Be Present
    ${value}=    Execute Javascript
    ...    return (function(name){
    ...      var panel=document.querySelector('div.kale-panel');
    ...      if(!panel){throw new Error('kale panel not found');}
    ...      var labels=Array.from(panel.querySelectorAll('label'));
    ...      var input=null;
    ...      for (var i=0;i<labels.length;i++){
    ...        var t=(labels[i].textContent||'').replace(/\\s+/g,' ').trim().toLowerCase();
    ...        if(t==='pipeline name' || (t.indexOf('pipeline name')!==-1 && t.indexOf('description')===-1)){
    ...          var scope=labels[i].closest('.MuiFormControl-root')||labels[i].parentElement;
    ...          input=scope?scope.querySelector('input'):null;
    ...          if(input){break;}
    ...        }
    ...      }
    ...      if(!input){
    ...        var info=labels.map(function(l){return (l.textContent||'').trim();});
    ...        throw new Error('pipeline name input not found; labels='+JSON.stringify(info));
    ...      }
    ...      input.focus();
    ...      var proto=window.HTMLInputElement.prototype;
    ...      var nativeSet=Object.getOwnPropertyDescriptor(proto,'value').set;
    ...      var tracker=input._valueTracker;
    ...      if(tracker){tracker.setValue('');}
    ...      nativeSet.call(input, name);
    ...      input.dispatchEvent(new Event('input',{bubbles:true}));
    ...      input.dispatchEvent(new Event('change',{bubbles:true}));
    ...      return String(input.value||'');
    ...    })(arguments[0]);
    ...    ARGUMENTS    ${pipeline_name}
    Should Be Equal As Strings    ${value}    ${pipeline_name}
    # React state update is async; confirm the controlled value stuck
    Wait Until Keyword Succeeds    10x    0.5s
    ...    Kale Pipeline Name Should Equal    ${pipeline_name}

Kale Pipeline Name Field Should Be Present
    [Documentation]    Waits until the Kale "Pipeline Name" MUI field is mounted
    ${present}=    Execute Javascript
    ...    return (function(){
    ...      var panel=document.querySelector('div.kale-panel');
    ...      if(!panel){return false;}
    ...      return Array.from(panel.querySelectorAll('label')).some(function(l){
    ...        var t=(l.textContent||'').replace(/\\s+/g,' ').trim().toLowerCase();
    ...        return t.indexOf('pipeline name')!==-1 && t.indexOf('description')===-1;
    ...      });
    ...    })();
    Should Be True    ${present}

Kale Pipeline Name Should Equal
    [Documentation]    Reads the Kale Pipeline Name controlled input value via JS
    [Arguments]    ${pipeline_name}
    ${value}=    Execute Javascript
    ...    return (function(){
    ...      var panel=document.querySelector('div.kale-panel');
    ...      if(!panel){return null;}
    ...      var labels=Array.from(panel.querySelectorAll('label'));
    ...      for (var i=0;i<labels.length;i++){
    ...        var t=(labels[i].textContent||'').replace(/\\s+/g,' ').trim().toLowerCase();
    ...        if(t.indexOf('pipeline name')!==-1 && t.indexOf('description')===-1){
    ...          var scope=labels[i].closest('.MuiFormControl-root')||labels[i].parentElement;
    ...          var input=scope?scope.querySelector('input'):null;
    ...          return input?String(input.value||''):null;
    ...        }
    ...      }
    ...      return null;
    ...    })();
    Should Be Equal As Strings    ${value}    ${pipeline_name}

Compile And Run Kale Pipeline
    [Documentation]    Compiles the annotated notebook into a pipeline and submits a run to the pipeline server
    [Arguments]    ${pipeline_name}
    Set Kale Pipeline Name    ${pipeline_name}
    Save Kale Notebook
    # File/menu interactions switch the left sidebar away from Kale; reopen before compile.
    Open Kale Panel
    Wait Until Keyword Succeeds    30x    2s
    ...    Kale Compile And Run Button Should Be Enabled
    Click Kale Compile And Run
    Maybe Confirm Kale Unsaved Changes Dialog
    Wait For Kale Deploy To Complete

Save Kale Notebook
    [Documentation]    Saves the active notebook so Kale does not block compile/run on unsaved changes.
    ...    Prefer Ctrl+S over the File menu: opening menus switches the left sidebar to the
    ...    file browser and can leave overlays that make the Kale Compile button unclickable.
    Wait Until ${KALE_NOTEBOOK_TAB} JupyterLab Tab Is Selected
    Press Keys    None    ESCAPE
    Press Keys    css:body    CTRL+s
    Sleep    1s    reason=Allow JupyterLab save to finish

Kale Compile And Run Button Should Be Enabled
    [Documentation]    Asserts the Kale panel Compile and Run button exists and is not disabled
    ${enabled}=    Execute Javascript
    ...    return (function(){
    ...      var panel=document.querySelector('div.kale-panel');
    ...      if(!panel){return false;}
    ...      var btn=Array.from(panel.querySelectorAll('button')).find(function(b){
    ...        return (b.textContent||'').indexOf('Compile and Run')!==-1;
    ...      });
    ...      return !!(btn && !btn.disabled && !btn.getAttribute('disabled'));
    ...    })();
    Should Be True    ${enabled}

Click Kale Compile And Run
    [Documentation]    Clicks Compile and Run via JS (avoids Selenium interactability issues)
    Execute Javascript
    ...    (function(){
    ...      var panel=document.querySelector('div.kale-panel');
    ...      if(!panel){throw new Error('kale panel not found');}
    ...      var btn=Array.from(panel.querySelectorAll('button')).find(function(b){
    ...        return (b.textContent||'').indexOf('Compile and Run')!==-1;
    ...      });
    ...      if(!btn){throw new Error('Compile and Run button not found');}
    ...      if(btn.disabled){throw new Error('Compile and Run button is disabled');}
    ...      btn.click();
    ...    })();

Maybe Confirm Kale Unsaved Changes Dialog
    [Documentation]    Kale prompts to save the notebook when compile/run is triggered on unsaved changes.
    ...    Confirms the dialog so compilation can proceed.
    ${dialog_visible} =    Run Keyword And Return Status
    ...    Wait Until Page Contains Element    xpath=${KALE_UNSAVED_CHANGES_DIALOG_XP}    timeout=10s
    IF    ${dialog_visible}
        Click Element    xpath=${KALE_UNSAVED_CHANGES_YES_BTN_XP}
    END

Wait For Kale Deploy To Complete
    [Documentation]    Waits until Kale finishes validating, compiling, uploading, and running the pipeline
    Wait Until Page Contains    Validating notebook    timeout=30s
    Wait Until Page Contains    Compiling notebook    timeout=2m
    Wait Until Page Contains    Uploading pipeline    timeout=2m
    Wait Until Page Contains    Running pipeline    timeout=2m
    Wait Until Page Contains Element    xpath=${KALE_COMPILE_AND_RUN_BTN_XP}    timeout=5m
    ${failed} =    Run Keyword And Return Status    Page Should Contain    Failed
    IF    ${failed}
        Capture Page Screenshot
        Fail    Kale pipeline compile/run failed — see screenshot and Kale deploy progress in the sidebar
    END

Select Kale Pipeline Project By Name
    [Documentation]    Selects ${project_name} in the dashboard Pipelines project selector
    [Arguments]    ${project_name}
    Wait Until Keyword Succeeds    5x    2s
    ...    Do Select Kale Pipeline Project By Name    ${project_name}

Do Select Kale Pipeline Project By Name
    [Documentation]    Single attempt to select a project from the Pipelines project selector
    [Arguments]    ${project_name}
    ${project_menu}=    Set Variable    xpath://*[@data-testid="project-selector-toggle"]
    Wait Until Element Is Visible    ${project_menu}    timeout=20
    ${current}=    Get Text    ${project_menu}
    IF    '${project_name}' in '''${current}'''
        RETURN
    END
    Click Element    ${project_menu}
    Wait Until Page Contains Element
    ...    xpath://*[@role="menuitem" and normalize-space(.)="${project_name}"]
    ...    timeout=10s
    Click Element    xpath://*[@role="menuitem" and normalize-space(.)="${project_name}"]
    Wait Until Keyword Succeeds    5x    1s
    ...    Element Should Contain    ${project_menu}    ${project_name}

Verify Kale Pipeline Run Is Completed
    [Documentation]    Waits until the Kale-submitted run appears on Develop & train > Pipelines > Runs
    ...    and reaches a successful end state. Kept in Kale.resource so shared Pipelines keywords
    ...    (still used by other suites) do not need UI-selector changes for the current Runs table.
    [Arguments]    ${pipeline_name}    ${timeout}=10m
    Maybe Wait For Dashboard Loading Spinner Page    timeout=30s
    Wait Until Page Contains Element
    ...    xpath://td[@data-label="Name" or @data-label="Run"]//*[contains(text(), "${pipeline_name}")]
    ...    timeout=120s
    Wait Until Page Does Not Contain Element
    ...    xpath://td[@data-label="Name" or @data-label="Run"]//*[contains(text(), "${pipeline_name}")]/ancestor::tr//td[@data-label="Duration" and (normalize-space(.)="-" or normalize-space(.)="")]
    ...    timeout=${timeout}
    Page Should Contain Element
    ...    xpath://td[@data-label="Name" or @data-label="Run"]//*[contains(text(), "${pipeline_name}")]/ancestor::tr//td[@data-label="Status"]//*[contains(translate(., "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"), "succeed") or contains(translate(., "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"), "complete") or contains(translate(@class, "SUCCESS", "success"), "success")]
    Capture Page Screenshot
