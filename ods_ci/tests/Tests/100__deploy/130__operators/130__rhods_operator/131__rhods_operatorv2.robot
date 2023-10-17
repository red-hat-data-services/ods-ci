*** Settings ***
Documentation    Tasks related to the operator rearchitecture
Library          String
Library          OperatingSystem
Library          ../../../../../libs/Helpers.py
Library          Collections
Resource         ../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Suite Setup      Get Original Configuration
Suite Teardown   Patch DataScienceCluster CustomResource To Original Configuration


*** Variables ***
@{COMPONENTS} =    dashboard    datasciencepipelines    kserve    modelmeshserving    workbenches    codeflare    ray
${DSC_NAME} =    default
${PATCH_PREFIX} =    oc patch datasciencecluster ${DSC_NAME} --type='merge' -p '{"spec": {"components": {
@{ORIGINAL_CONFIGURATION}

*** Test Cases ***
Verify Dashboard Component
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=dashboard
    Component Should Be Enabled    dashboard
    Component Should Not Be Enabled    datasciencepipelines
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    workbenches

Verify DataSciencePipelines Component
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=datasciencepipelines
    Component Should Be Enabled    datasciencepipelines
    Component Should Not Be Enabled    dashboard
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    workbenches

Verify ModelMeshServing Component
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=modelmeshserving
    Component Should Be Enabled    modelmeshserving
    Component Should Not Be Enabled    dashboard
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    workbenches

Verify Workbenches Component
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=workbenches
    Component Should Be Enabled    workbenches
    Component Should Not Be Enabled    dashboard
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    datasciencepipelines

Verify Kserve Component
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=kserve
    Component Should Be Enabled    kserve
    Component Should Not Be Enabled    dashboard
    Component Should Not Be Enabled    workbenches
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    datasciencepipelines

Verify No Components Enabled
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=none
    Component Should Not Be Enabled    datasciencepipelines
    Component Should Not Be Enabled    dashboard
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    workbenches


*** Keywords ***
Verify Component Resources
    [Documentation]    Currently always fails, need a better way to check
    [Arguments]    ${component}
    Enable Single Component    ${component}
    ${filepath} =    Set Variable    ods_ci/tests/Resources/Files/operatorV2/
    ${expected} =    Get File    ${filepath}${component}.txt
    Run    oc get $(oc api-resources --namespaced=true --verbs=list -o name | awk '{printf "%s%s",sep,$0;sep=","}') --ignore-not-found -n ${APPLICATIONS_NAMESPACE} -o=custom-columns=KIND:.kind,NAME:.metadata.name | sort -k1,1 -k2,2 | grep -v "PackageManifest\\|Event\\|ClusterServiceVersion" > ${filepath}${component}_runtime.txt  # robocop: disable
    Process Resource List    filename_in=${filepath}${component}_runtime.txt
    ...    filename_out=${filepath}${component}_processed.txt
    ${actual} =    Get File    ${filepath}${component}_processed.txt
    Remove File    ${filepath}${component}_processed.txt
    Remove File    ${filepath}${component}_runtime.txt
    Should Be Equal As Strings    ${expected}    ${actual}

Enable Single Component
    [Documentation]    Enables a single component AND disables all other components. If "none" is used
    ...    disables all components
    [Arguments]    ${component}    ${dsc_name}=default
    IF    "${component}" not in @{COMPONENTS} and "${component}" != "none"
        Log    unknown component: ${component}    level=WARN
        RETURN
    END
    ${len} =    Get Length    ${COMPONENTS}
    ${patch} =    Set Variable    ${PATCH_PREFIX}
    FOR    ${index}    ${cmp}    IN ENUMERATE    @{COMPONENTS}
        IF     "${cmp}"=="${component}"
            ${sub} =    Change Component Status    component=${cmp}    enable=Managed    run=${FALSE}
        ELSE
            ${sub} =    Change Component Status    component=${cmp}    enable=Removed    run=${FALSE}
        END
        IF    ${index} ==0
            ${patch} =    Catenate    SEPARATOR=    ${patch}    ${sub}
        ELSE
            ${patch} =    Catenate    SEPARATOR=,${SPACE}    ${patch}    ${sub}
        END
    END
    ${patch} =    Catenate    SEPARATOR=    ${patch}    }}}'
    Log    ${patch}
    ${return_code}    ${output} =    Run And Return Rc And Output    ${patch}
    Log    ${output}
    Should Be Equal As Integers	${return_code}	 0  msg=Error detected while applying DSC CR
    Sleep    30s

Change Component Status
    [Documentation]    Enables or disables a single component. Can either run the patch command directly (if `run` is
    ...    set to true) or return the patch string to be combined later for a bigger patch command.
    [Arguments]    ${component}    ${run}=${TRUE}    ${enable}=Managed
    IF    "${component}" not in @{COMPONENTS}
        Log    unknown component: ${component}    level=WARN
        RETURN
    END
    IF    ${run}==${TRUE}
        ${command} =    Catenate    SEPARATOR=    ${PATCH_PREFIX}   "${component}":{"managementState": ${enable}}    }}}'
        ${return_code}    ${output} =    Run And Return Rc And Output    ${command}
        Log    ${output}
        Should Be Equal As Integers	${return_code}	 0  msg=Error detected while applying DSC CR
        Sleep    30s
    ELSE
        RETURN    "${component}":{"managementState": ${enable}}
    END

Get Original Configuration
    [Documentation]
    @{config} =    Create List
    FOR    ${cmp}    IN    @{COMPONENTS}
        ${status} =    Is Component Enabled    ${cmp}
        Append To List    ${config}    ${status}
    END
    ${ORIGINAL_CONFIGURATION} =    Set Variable    ${config}

Patch DataScienceCluster CustomResource To Original Configuration
    [Documentation]  Enables a mix of components based on the values set before this test suite was started
    [Arguments]    ${dsc_name}=default
    ${len} =    Get Length    ${COMPONENTS}
    ${patch} =    Set Variable    ${PATCH_PREFIX}
    FOR    ${index}    ${cmp}    IN ENUMERATE    @{COMPONENTS}
        IF    "${ORIGINAL_CONFIGURATION}[${index}]" == "Managed"
            ${sub} =    Change Component Status    component=${cmp}    run=${FALSE}    enable=Managed
        ELSE IF    "${ORIGINAL_CONFIGURATION}[${index}]" == "Removed"
            ${sub} =    Change Component Status    component=${cmp}    run=${FALSE}    enable=Removed
        END
        IF    ${index} ==0
            ${patch} =    Catenate    SEPARATOR=    ${patch}    ${sub}
        ELSE
            ${patch} =    Catenate    SEPARATOR=,${SPACE}    ${patch}    ${sub}
        END
    END
    ${patch} =    Catenate    SEPARATOR=    ${patch}    }}}'
    Log    ${patch}
    ${return_code}    ${output} =    Run And Return Rc And Output    ${patch}
    Log    ${output}
    Should Be Equal As Integers	${return_code}	 0  msg=Error detected while applying DSC CR
    Sleep    30s
