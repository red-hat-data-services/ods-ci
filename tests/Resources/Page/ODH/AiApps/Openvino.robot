*** Settings ***
Library         SeleniumLibrary

*** Keywords ***
Uninstall Openvino Operator
    Go To  ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Delete Tabname Instance For Installed Operator      ${openvino_operator_name}       Notebook    redhat-ods-applications
    Uninstall Operator       ${openvino_operator_name}

Verify JupyterHub Can Spawn Openvino Notebook
    Launch JupyterHub Spawner From Dashboard
    Wait Until Page Contains Element  xpath://input[@name="OpenVINO™ Toolkit"]
    Wait Until Element Is Enabled     xpath://input[@name="OpenVINO™ Toolkit"]   timeout=10
    Spawn Notebook With Arguments  image=openvino-notebook
    Run Cell And Check Output      !pwd           /opt/app-root/src
    Fix Spawner Status