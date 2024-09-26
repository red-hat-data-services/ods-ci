*** Settings ***
Library             SeleniumLibrary
Resource            ../../../../Resources/Page/OCPLogin/OCPLogin.resource
Resource            ../../../../Resources/OCP.resource
Resource            ../../../../Resources/Page/ODH/AiApps/AiApps.resource
Resource            ../../../../Resources/RHOSi.resource

Suite Setup         Pachyderm Suite Setup
Suite Teardown      Pachyderm Suite Teardown

Test Tags           ExcludeOnODH


*** Variables ***
${pachyderm_container_name}     Pachyderm
${pachyderm_operator_name}      Pachyderm
${pachyderm_appname}            pachyderm
${pachyderm_ns}                 pachyderm


*** Test Cases ***
Verify Pachyderm Can Be Installed And Deployed
    [Documentation]     Check if it is possible to install and deploy pachyderm.
    [Tags]      Tier2
    ...         ODS-1137    ODS-1138
    Pass Execution      Passing test, as suite setup ensures Pachyderm operator is installed correctly.

Verify Pachyderm Pipeline Can Be Created
    [Documentation]     Checks if it is possible to create sample pipline using jupyterlab.
    [Tags]      Tier2
    ...         ODS-1161
    Go To    ${OCP_CONSOLE_URL}
    ${pachctl_version}=     Get Pachd Version
    Go To RHODS Dashboard
    Verify Service Is Enabled    Pachyderm
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=science-notebook
    Create Pachyderm Pipeline Using JupyterLab     ${pachctl_version}
    Verify Pipeline Pod Creation
    [Teardown]  Delete Pipeline And Stop JupyterLab Server


*** Keywords ***
Pachyderm Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Open OCP Console
    Login to OCP
    Wait Until OpenShift Console Is Loaded
    Check And Install Operator in Openshift    ${pachyderm_container_name}    ${pachyderm_appname}
    Run    oc new-project ${pachyderm_ns}
    Create Pachyderm AWS-Secret
    Create Tabname Instance For Installed Operator        ${pachyderm_container_name}   ${pachyderm_container_name}     ${pachyderm_appname}
    Wait Until Status Is Running
    Go To RHODS Dashboard
    Verify Service Is Enabled    Pachyderm

Pachyderm Suite Teardown
    Go To    ${OCP_CONSOLE_URL}
    Oc Delete    kind=Pachyderm  name=pachyderm-sample  namespace=${pachyderm_ns}
    Move To Installed Operator Page Tab In Openshift    operator_name=${pachyderm_operator_name}
    ...    tab_name=Pachyderm    namespace=${pachyderm_ns}
    Uninstall Operator    ${pachyderm_operator_name}
    Oc Delete    kind=Project    name=${pachyderm_ns}
    Sleep    30s
    ...    reason=There is a bug in dashboard showing an error message after ISV uninstall
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=${pachyderm_appname}
    Close All Browsers

Wait Until Status Is Running
    [Documentation]     Checks if the status changes from Initializing to Running.
    Wait Until Keyword Succeeds     120     1       Element Text Should Be    //span[@data-test="status-text"]      Running

Get Pachd Version
    [Documentation]     Checks and returns the version of pachd.
    Menu.Navigate To Page       Operators       Installed Operators
    Select Project By Name      ${pachyderm_appname}
    Click On Searched Operator      ${pachyderm_operator_name}
    Switch To New Tab       ${pachyderm_operator_name}
    Wait Until Page Contains Element    //a[@data-test-operand-link="pachyderm-sample"]
    Click Element   //a[@data-test-operand-link="pachyderm-sample"]
    Wait Until Page Contains Element    (//dd[@data-test-selector="details-item-value__Version"])[1]
    ${version}=     Get Text        (//dd[@data-test-selector="details-item-value__Version"])[1]
    ${seperator}=   Set Variable    v
    ${res_version}=     Fetch From Right    ${version}      ${seperator}
    RETURN    ${res_version}

Create Pachyderm AWS-Secret
    [Documentation]     Creates a Pachyderm AWS Secret.
    Run     oc create secret generic pachyderm-aws-secret -n pachyderm --from-literal=access-id=${S3.AWS_ACCESS_KEY_ID} --from-literal=access-secret=${S3.AWS_SECRET_ACCESS_KEY} --from-literal=region=us-east-1 --from-literal=bucket=ods-ci-pachyderm

Verify Pipeline Pod Creation
    [Documentation]     Checks pipeline pod has been created in workloads.
    ${status}=    Check If POD Exists    pachyderm      app=pipeline-edges-v1
    IF    '${status}'=='FAIL'    FAIL
    ...    PODS with Label '${label_selector}' is not present in '${namespace}' namespace
    Wait Until Keyword Succeeds     120     5   Verify Operator Pod Status  pachyderm   app=pipeline-edges-v1

Create Command In Multiple Lines
    ${command_string}=  Catenate    SEPARATOR=${\n}
    ...     !pachctl get file images@master:liberty.png -o original_liberty.png
    ...     from IPython.display import Image, display
    ...     Image(filename='original_liberty.png')
    Log     ${command_string}
    RETURN    ${command_string}

Create Pachyderm Pipeline Using JupyterLab
    [Documentation]     Creates pachyderm pipeline by running multiple commands on jupyterlab.
    [Arguments]     ${pachctl_version}
    Run Cell And Check For Errors   !curl -o /tmp/pachctl.tar.gz -L https://github.com/pachyderm/pachyderm/releases/download/v${pachctl_version}/pachctl_${pachctl_version}_linux_amd64.tar.gz && tar -xvf /tmp/pachctl.tar.gz -C /tmp && cp /tmp/pachctl_${pachctl_version}_linux_amd64/pachctl /opt/app-root/bin/
    Run Cell And Check For Errors   !echo '{"pachd_address":"pachd.pachyderm.svc.cluster.local:30650"}' | pachctl config set context pachyderm --overwrite
    Run Cell And Check For Errors   !pachctl config set active-context pachyderm
    Run Cell And Check For Errors   !pachctl config get active-context
    Run Cell And Check For Errors   !pachctl version
    Run Cell And Check For Errors   !pachctl create repo images
    Run Cell And Check For Errors   !pachctl list repo
    Run Cell And Check For Errors   !pachctl put file images@master:liberty.png -f http://imgur.com/46Q8nDz.png
    Run Cell And Check For Errors   !pachctl list repo
    Run Cell And Check For Errors   !pachctl list commit images
    ${command_string}=      Create Command In Multiple Lines
    Run Cell And Check For Errors   ${command_string}
    Run Cell And Check For Errors   !pachctl create pipeline -f https://raw.githubusercontent.com/pachyderm/pachyderm/master/examples/opencv/edges.json
    Run Cell And Check For Errors   !pachctl list job
