*** Settings ***
Documentation    Tasks related to the operator rearchitecture
Library          String
Library          OperatingSystem
Library          ../../libs/Helpers.py


*** Variables ***
@{COMPONENTS} =    dashboard    datasciencepipelines    distributedWorkloads    kserve    modelmeshserving    workbenches  # robocop: disable
${DSC_NAME} =    default
${PATCH_PREFIX} =    oc patch datasciencecluster ${DSC_NAME} --type='merge' -p '{"spec": {"components": {



*** Tasks ***
# Switch To Core Installation Profile
#     [Documentation]
#     Switch Installation Profile    profile=core

# Switch To Serving Installation Profile
#     [Documentation]
#     Switch Installation Profile    profile=serving

# Switch To Training Installation Profile
#     [Documentation]
#     Switch Installation Profile    profile=training

# Switch To Workbench Installation Profile
#     [Documentation]
#     Switch Installation Profile    profile=workbench

# Switch To None Installation Profile
#     [Documentation]
#     Switch Installation Profile    profile=none


Verify Core Installation Profile
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=dashboard
    Component Should Be Enabled    dashboard
    Component Should Not Be Enabled    datasciencepipelines
    Component Should Not Be Enabled    distributedWorkloads
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    workbenches

Verify Serving Installation Profile
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=datasciencepipelines
    Component Should Be Enabled    datasciencepipelines
    Component Should Not Be Enabled    dashboard
    Component Should Not Be Enabled    distributedWorkloads
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    workbenches

Verify Training Installation Profile
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=modelmeshserving
    Component Should Be Enabled    modelmeshserving
    Component Should Not Be Enabled    dashboard
    Component Should Not Be Enabled    distributedWorkloads
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    workbenches

Verify Workbench Installation Profile
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=workbenches
    Component Should Be Enabled    workbenches
    Component Should Not Be Enabled    dashboard
    Component Should Not Be Enabled    distributedWorkloads
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    datasciencepipelines

Verify None Installation Profile
    [Documentation]
    Run Keyword And Continue On Failure    Verify Component Resources    component=none
    Component Should Not Be Enabled    datasciencepipelines
    Component Should Not Be Enabled    dashboard
    Component Should Not Be Enabled    distributedWorkloads
    Component Should Not Be Enabled    kserve
    Component Should Not Be Enabled    modelmeshserving
    Component Should Not Be Enabled    workbenches


*** Keywords ***
# Switch Installation Profile
#     [Documentation]
#     [Arguments]    ${profile}=core    ${dsc_name}=example    ${namespace}=opendatahub
#     ${current_profile} =    Get Current Installation Profile
#     IF    ${current_profile} == "${profile}"
#         Skip    msg=Installed profile is already profile ${profile}
#     END
#     ${out} =    Run    oc patch datasciencecluster ${dsc_name} --type='merge' -p '{"spec":{"profile":"${profile}"}}'
#     Should Be Equal As Strings    ${out}    datasciencecluster.datasciencecluster.${namespace}.io/${dsc_name} patched

Component Should Be Enabled
    [Arguments]    ${component}    ${dsc_name}=default
    ${status} =    Verify If Component Is Enabled    ${component}    ${dsc_name}
    IF    '${status}' != 'true'    Fail

Component Should Not Be Enabled
    [Arguments]    ${component}    ${dsc_name}=default
    ${status} =    Verify If Component Is Enabled    ${component}    ${dsc_name}
    IF    '${status}' != 'false'    Fail


Verify Component Resources
    [Documentation]    Currently always fails, need a better way to check
    [Arguments]    ${component}
    Enable Single Component    ${component}
    ${filepath} =    Set Variable    ods_ci/tasks/Resources/Files/
    ${expected} =    Get File    ${filepath}${component}.txt
    Run    oc get $(oc api-resources --namespaced=true --verbs=list -o name | awk '{printf "%s%s",sep,$0;sep=","}') --ignore-not-found -n opendatahub -o=custom-columns=KIND:.kind,NAME:.metadata.name | sort -k1,1 -k2,2 | grep -v "PackageManifest\\|Event\\|ClusterServiceVersion" > ${filepath}${component}_runtime.txt  # robocop: disable
    Process Resource List    filename_in=${filepath}${component}_runtime.txt
    ...    filename_out=${filepath}${component}_processed.txt
    ${actual} =    Get File    ${filepath}${component}_processed.txt
    Remove File    ${filepath}${component}_processed.txt
    Remove File    ${filepath}${component}_runtime.txt
    Should Be Equal As Strings    ${expected}    ${actual}

Verify If Component Is Enabled
    [Documentation]    Returns the enabled status of a single component (true/false)
    [Arguments]    ${component}    ${dsc_name}=default
    ${status} =    Run    oc get datasciencecluster ${dsc_name} -o json | jq '.spec.components.${component}\[]'
    RETURN    ${status}

Enable Single Component
    [Documentation]    Enables a single component AND disables all other components. If "none" is used
    ...    disables all components
    [Arguments]    ${component}    ${dsc_name}=default
    IF    "${component}" not in @{COMPONENTS} and "${component}" != "none"
        Log    unknown component: ${component}
        RETURN
    END
    ${len} =    Get Length    ${COMPONENTS}
    ${patch} =    Set Variable    ${PATCH_PREFIX}
    FOR    ${index}    ${cmp}    IN ENUMERATE    @{COMPONENTS}
        IF     "${cmp}"=="${component}"
            ${sub} =    Change Component Status    component=${cmp}    run=${FALSE}
        ELSE
            ${sub} =    Change Component Status    component=${cmp}    enable=false    run=${FALSE}
        END
        IF    ${index} ==0
            ${patch} =    Catenate    SEPARATOR=    ${patch}    ${sub}
        ELSE
            ${patch} =    Catenate    SEPARATOR=,${SPACE}    ${patch}    ${sub}
        END
    END
    ${patch} =    Catenate    SEPARATOR=    ${patch}    }}}'
    Log    ${patch}
    ${status} =    Run    ${patch}
    Log    ${status}
    Sleep    30s

Change Component Status
    [Documentation]    Enables or disables a single component. Can either run the patch command directly (if `run` is
    ...    set to true) or return the patch string to be combined later for a bigger patch command.
    [Arguments]    ${component}    ${run}=${TRUE}    ${enable}=true
    IF    "${component}" not in @{COMPONENTS}
        Log    unknown component: ${component}
        RETURN
    END
    IF    ${run}==${TRUE}
        ${command} =    Catenate    SEPARATOR=    ${PATCH_PREFIX}   "${component}":{"enabled": ${enable}}    }}}'
        ${status} =    Run    ${command}
        Log    ${status}
        Sleep    30s
    ELSE
        RETURN    "${component}":{"enabled": ${enable}}
    END
