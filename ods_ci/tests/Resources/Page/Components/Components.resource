*** Settings ***
Documentation    This is a resource file for the DSC components.
Resource  Menu.robot
Resource  ../../OCP.resource
Resource  ../../ODS.robot


*** Keywords ***
Set DSC Component Removed State And Wait For Completion
    [Documentation]    Set component management state to 'Removed', and wait for deployment and pod to be removed.
    [Arguments]    ${component}    ${deployment_name}    ${label_selector}

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    ${component}    ${OPERATOR_NS}
    IF    "${management_state}" != "Removed"
            Set Component State    ${component}    Removed
    END

    Wait For Resources To Be Removed    ${deployment_name}    ${label_selector}

Set DSC Component Managed State And Wait For Completion
    [Documentation]    Set component management state to 'Managed', and wait for deployment and pod to be available.
    [Arguments]    ${component}    ${deployment_name}    ${label_selector}

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    ${component}    ${OPERATOR_NS}
    IF    "${management_state}" != "Managed"
            Set Component State    ${component}    Managed
    END

    Wait For Resources To Be Available    ${deployment_name}    ${label_selector}

Wait For Resources To Be Available
    [Documentation]    Wait until Deployment and Pod(s) are Available
    [Arguments]    ${deployment_name}    ${label_selector}
    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Deployment    ${deployment_name}    ${APPLICATIONS_NS}    ${IS_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Check If Pod Exists    ${APPLICATIONS_NS}    ${label_selector}    ${FALSE}

    Wait Until Keyword Succeeds    8 min    0 sec
    ...    Is Pod Ready    ${label_selector}

Wait For Resources To Be Removed
    [Documentation]    Wait until Deployment and Pod(s) to Removed
    [Arguments]    ${deployment_name}    ${label_selector}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Deployment    ${deployment_name}    ${APPLICATIONS_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Check If Pod Does Not Exist    ${label_selector}    ${APPLICATIONS_NS}

Restore DSC Component State
    [Documentation]    Set component management state to original state, wait for component resources to be available.
    [Arguments]    ${component}    ${deployment_name}    ${LABEL_SELECTOR}    ${saved_state}

    ${current_state}=    Get DSC Component State    ${DSC_NAME}    ${component}    ${OPERATOR_NS}
    IF    "${current_state}" != "${saved_state}"
        IF    "${saved_state}" == "Managed"
            Set DSC Component Managed State And Wait For Completion    ${component}    ${deployment_name}    ${LABEL_SELECTOR}
        ELSE IF    "${saved_state}" == "Removed"
            Set DSC Component Removed State And Wait For Completion    ${component}    ${deployment_name}    ${LABEL_SELECTOR}
        ELSE
            FAIL    Component ${component} state "${saved_state}" not supported at this time
        END
    END

Is Pod Ready
    [Documentation]    Check If Pod Is In Ready State.
    ...    Note: Will check that all pods with given label-selector are in Ready state.
    [Arguments]    ${label_selector}
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    oc get pod -A -l ${label_selector} -o jsonpath='{..status.conditions[?(@.type=="Ready")].status}'
    # Log To Console    "Pod Ready Status: ${output}"
    Should Be Equal As Integers    ${rc}    0
    Should Not Contain    ${output}    False

Get DataScienceCluster Spec
    [Documentation]    Return the DSC Spec
    [Arguments]    ${DSC_NAME}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster/${DSC_NAME} -n ${OPERATOR_NS} -o "jsonpath={".spec"}"
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${output}

Check That Image Pull Path Is Correct
    [Documentation]     Check that the deployment Image Pull path is the correct one
    [Arguments]     ${deployment_name}      ${image_pull_path}
    ${rc}=   Set Variable   1
    WHILE   '${rc}' != '0'    limit=5m
        ${rc}   ${image}=    Run And Return Rc And Output
        ...    oc get deployment/${deployment_name} -n ${APPLICATIONS_NAMESPACE} -o jsonpath="{..image}"
    END

    ${rc}   ${images}=    Run And Return Rc And Output
    ...    oc get deployment/${deployment_name} -n ${APPLICATIONS_NAMESPACE} -o jsonpath="{..image}"
    Should Be Equal As Integers    ${rc}    0    msg=${images}
    ${images}=    Split String    ${images}    ${SPACE}


    ${rc}   ${relatedImages}=    Run And Return Rc And Output
    ...    oc get csv ${CSV_NAME} -n ${OPERATOR_NAMESPACE} -o jsonpath="{.spec.relatedImages[*].image}"
    Should Be Equal As Integers    ${rc}    0    msg=${relatedImages}
    ${relatedImages}=    Split String    ${relatedImages}    ${SPACE}

    FOR  ${image}    IN    @{images}
        Log To Console    Check deployment ${deployment_name} pull path for image ${image}
        Run Keyword And Continue On Failure
        ...    Should Start With    ${image}   ${image_pull_path}    msg=Deployment image pull path ${image} does not start with ${image_pull_path}
        # Only check for sha256 digest if the product is RHOAI
        IF    "${PRODUCT}" == "RHODS"
            Run Keyword And Continue On Failure
            ...    Should Match Regexp    ${image}    @sha256:[a-f0-9]{64}$    msg=Deployment image pull path ${image} does not contain sha256 digest
        END
        
        Run Keyword And Continue On Failure
        ...    Should Contain    ${relatedImages}    ${image}    msg=Deployment image pull path ${image} is not in CSV's relatedImages
    END

Check Model Registry Namespace
    [Documentation]    Check that DSC modelregistry.registriesNamespace is correct for ODH/RHOAI
    ...    Validate that namespace exists.

    ${rc}   ${namespace}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster/${DSC_NAME} -n ${OPERATOR_NS} -o "jsonpath={".spec.components.modelregistry.registriesNamespace"}"
    Should Be Equal As Integers    ${rc}    0    msg=${namespace}

    Should Be Equal    ${namespace}    ${MODEL_REGISTRY_NAMESPACE}    msg=Model Registry Namespace: Actual "${namespace}" Expected: "${MODEL_REGISTRY_NAMESPACE}"

    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get namespace -A ${MODEL_REGISTRY_NAMESPACE}
    Should Be Equal As Integers    ${rc}    0    msg=${output}
