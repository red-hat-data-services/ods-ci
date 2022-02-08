*** Settings ***
Library         SeleniumLibrary

***Keywords ***
Uninstall AIKIT Operator
    Go To  ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Delete Tabname Instance For Installed Operator      ${intel_aikit_operator_name}      AIKitContainer    redhat-ods-applications
    Uninstall Operator       ${intel_aikit_operator_name}
    OpenShiftCLI.Delete      kind=ImageStream    namespace=redhat-ods-applications  label_selector=opendatahub.io/notebook-image=true  field_selector=metadata.name==oneapi-aikit

Verify JupyterHub Can Spawn AIKIT Notebook
    Launch JupyterHub Spawner From Dashboard
    Wait Until Page Contains Element   xpath://input[@name="oneAPI AI Analytics Toolkit"]
    Wait Until Element Is Enabled     xpath://input[@name="oneAPI AI Analytics Toolkit"]  timeout=10
    Spawn Notebook With Arguments  image=oneapi-aikit
    Fix Spawner Status