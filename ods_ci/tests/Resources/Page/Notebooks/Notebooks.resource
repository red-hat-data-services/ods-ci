*** Settings ***
# robocop: disable=LEN08,LEN28
Documentation       Notebooks resource file containing keywords for notebook creation and management
Library             OperatingSystem
Library             String
Library             OpenShiftLibrary


*** Keywords ***
Create Notebook Programmatically And Wait For Ready
    [Documentation]    Creates a notebook CR programmatically using oc commands and waits for network policies
    ${notebook_cr_name} =    Prepare Notebook Creation
    ${temp_yaml_file} =    Create Notebook YAML File    ${notebook_cr_name}
    Apply Notebook CR    ${temp_yaml_file}
    Wait For Network Policies    ${notebook_cr_name}
    Cleanup Temporary File    ${temp_yaml_file}

Prepare Notebook Creation
    [Documentation]    Prepares notebook creation by generating safe username and notebook name
    ${safe_username} =    Get Safe Username    ${TEST_USER.USERNAME}
    ${notebook_cr_name} =    Set Variable    jupyter-nb-${safe_username}
    Log    Creating notebook with name: ${notebook_cr_name}
    Log    Using namespace: ${NOTEBOOKS_NAMESPACE}
    Log    Safe username: ${safe_username}
    RETURN    ${notebook_cr_name}

Create Notebook YAML File
    [Documentation]    Creates a temporary YAML file with notebook CR definition
    [Arguments]    ${notebook_cr_name}
    ${safe_username} =    Get Safe Username    ${TEST_USER.USERNAME}
    ${notebook_yaml} =    Load And Substitute Notebook Template    ${notebook_cr_name}    ${safe_username}
    ${temp_yaml_file} =    Set Variable    /tmp/notebook-${notebook_cr_name}.yaml
    Create File    ${temp_yaml_file}    ${notebook_yaml}
    Log    Created temporary YAML file: ${temp_yaml_file}
    RETURN    ${temp_yaml_file}

Load And Substitute Notebook Template
    [Documentation]    Loads notebook template and substitutes variables
    [Arguments]    ${notebook_cr_name}    ${safe_username}
    ${notebook_yaml} =    Get File    tests/Resources/Files/notebook-template.yaml
    ${notebook_yaml} =    Replace String    ${notebook_yaml}    \${NOTEBOOK_CR_NAME}    ${notebook_cr_name}
    ${notebook_yaml} =    Replace String    ${notebook_yaml}    \${NOTEBOOKS_NAMESPACE}    ${NOTEBOOKS_NAMESPACE}
    ${notebook_yaml} =    Replace String    ${notebook_yaml}    \${SAFE_USERNAME}    ${safe_username}
    ${notebook_yaml} =    Replace String    ${notebook_yaml}    \${TEST_USER.USERNAME}    ${TEST_USER.USERNAME}
    RETURN    ${notebook_yaml}

Apply Notebook CR
    [Documentation]    Applies the notebook CR using oc command
    [Arguments]    ${temp_yaml_file}
    ${rc}    ${output} =    Run And Return Rc And Output    oc apply -f ${temp_yaml_file} -n ${NOTEBOOKS_NAMESPACE}
    Log    oc apply return code: ${rc}
    Log    oc apply output: ${output}
    IF    ${rc}    Fail    Failed to apply notebook CR: ${output}

Wait For Network Policies
    [Documentation]    Waits for network policies to be created
    [Arguments]    ${notebook_cr_name}
    Wait Until Keyword Succeeds    2 min    10s    Verify Network Policies Created    ${notebook_cr_name}

Cleanup Temporary File
    [Documentation]    Removes the temporary YAML file
    [Arguments]    ${temp_yaml_file}
    Run And Verify Command    rm -f ${temp_yaml_file}

Verify Network Policies Created
    [Documentation]    Verifies that both network policies exist for the given notebook
    [Arguments]    ${notebook_cr_name}
    ${ctrl_policy_exists} =    Run Keyword And Return Status    Run
    ...    oc get networkpolicy ${notebook_cr_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE}
    ${oauth_policy_exists} =    Run Keyword And Return Status    Run
    ...    oc get networkpolicy ${notebook_cr_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE}
    IF    not ${ctrl_policy_exists}    Fail    Control network policy ${notebook_cr_name}-ctrl-np not found
    IF    not ${oauth_policy_exists}    Fail    OAuth network policy ${notebook_cr_name}-kube-rbac-proxy-np not found
    Log    Network policies created successfully for notebook: ${notebook_cr_name}

Cleanup Notebook CR
    [Documentation]    Deletes the notebook CR without requiring it to be running
    [Arguments]    ${user}
    ${safe_username} =   Get Safe Username    ${user}
    ${CR_name} =    Set Variable    jupyter-nb-${safe_username}

    # Check if notebook CR exists before trying to delete it
    ${notebook_exists} =    Run Keyword And Return Status    Run
    ...    oc get notebook ${CR_name} -n ${NOTEBOOKS_NAMESPACE}

    IF    ${notebook_exists}
        Log    Deleting notebook CR: ${CR_name}
        OpenShiftLibrary.Oc Delete    kind=Notebook    name=${CR_name}    namespace=${NOTEBOOKS_NAMESPACE}
        Log    Notebook CR ${CR_name} deleted successfully
    ELSE
        Log    Notebook CR ${CR_name} not found, nothing to delete
    END
