*** Settings ***
Library             SeleniumLibrary
Resource            ../../../Resources/Page/OCPLogin/OCPLogin.resource
Resource            ../../../Resources/OCP.resource
Resource            ../../../Resources/Page/ODH/AiApps/AiApps.resource
Test Setup          Dashboard Test Setup
Test Teardown       Dashboard Test Teardown


*** Variables ***
${pachyderm_container_name}     Pachyderm
${pachyderm_operator_name}      Pachyderm
${pachyderm_appname}            pachyderm


*** Test Cases ***
Verify Pachyderm Can Be Installed Using OpenShift Console
    [Documentation]     Check if it is possible to install and deploy pachyderm server successfully.
    [Tags]      Tier2
    ...         ODS-1137    ODS-1138
    Check And Install Operator in Openshift    ${pachyderm_container_name}    ${pachyderm_appname}
    Create Project      pachyderm
    Create Pachyderm AWS-Secret
    Create Tabname Instance For Installed Operator        ${pachyderm_container_name}   ${pachyderm_container_name}     pachyderm
    Wait Until Status Is Running
    Go To RHODS Dashboard
    Verify Service Is Enabled    Pachyderm
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook
    Create Pachyderm Pipeline Using JupyterLab
    Verify Pipline Pod Creation
    [Teardown]  Uninstall Pachyderm Operator

*** Keywords ***
Dashboard Test Setup
    Set Library Search Order    SeleniumLibrary
    Open Browser    ${OCP_CONSOLE_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login to OCP
    Wait Until OpenShift Console Is Loaded

Dashboard Test Teardown
    Close All Browsers

Wait Until Status Is Running
    [Documentation]     Checks if the status changes from Initializing to Running.
    Wait Until Keyword Succeeds     120     1       Element Text Should Be    //span[@data-test="status-text"]      Running

Create Pachyderm AWS-Secret
    [Documentation]     Creates a Pachyderm AWS Secret.
    Run     oc create secret generic pachyderm-aws-secret -n pachyderm --from-literal=access-id=${S3.AWS_ACCESS_KEY_ID} --from-literal=access-secret=${S3.AWS_SECRET_ACCESS_KEY} --from-literal=region=us-east-1 --from-literal=bucket=ods-ci-pachyderm
    Menu.Navigate To Page       Workloads   Secrets
    Wait Until Page Contains Element        //input[@data-test-id="item-filter"]
    Input Text      //input[@data-test-id="item-filter"]    pachyderm-aws-secret
    Wait Until Page Contains Element        //a[@data-test-id="pachyderm-aws-secret"]       10

Verify Pipline Pod Creation
    ${status}=    Check If POD Exists    pachyderm      app=pipeline-edges-v1
    Run Keyword IF    '${status}'=='FAIL'    FAIL
    ...    PODS with Label '${label_selector}' is not present in '${namespace}' namespace
    Wait Until Keyword Succeeds     120     5   Verify Operator Pod Status  pachyderm   app=pipeline-edges-v1

Create Command In Multiple Lines
    ${command_string}=  Catenate    SEPARATOR=${\n}
    ...     !pachctl get file images@master:liberty.png -o original_liberty.png
    ...     from IPython.display import Image, display
    ...     Image(filename='original_liberty.png')
    Log     ${command_string}
    [Return]    ${command_string}

Create Pachyderm Pipeline Using JupyterLab
    Run Cell And Check For Errors   !git clone https://github.com/Jooho/pachyderm-operator-manifests
    Run Cell And Check For Errors   !curl -o /tmp/pachctl.tar.gz -L https://github.com/pachyderm/pachyderm/releases/download/v2.0.5/pachctl_2.0.5_linux_amd64.tar.gz && tar -xvf /tmp/pachctl.tar.gz -C /tmp && cp /tmp/pachctl_2.0.5_linux_amd64/pachctl /opt/app-root/bin/
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

