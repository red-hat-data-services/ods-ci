*** Settings ***
Library    OpenShiftLibrary
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot


*** Keywords ***
Get Build Status
  [Arguments]  ${namespace}  ${build_search_term}
  Navigate To Page    Builds    Builds
  Search Last Item Instance By Title in OpenShift Table  search_term=${build_search_term}  namespace=${namespace}
  ${build_status}=  Get Text    xpath://tr[@data-key='0-0']/td/span/span[@data-test='status-text']
  RETURN  ${build_status}

Delete BuildConfig using Name
    [Arguments]    ${namespace}                    ${name}
    ${status}      Check If BuildConfig Exists    ${namespace}      ${name}
    IF          '${status}'=='PASS'   Oc Delete  kind=BuildConfig   name=${name}   namespace=${namespace}
    ...        ELSE          FAIL        No BuildConfig present with name '${name}' in '${namespace}' namespace, Check the BuildConfig name and namespace provide is correct and try again
    Wait Until Keyword Succeeds     10s  2s
    ...         Dependent Build should not Present     ${name}
    ${status}      Check If BuildConfig Exists    ${namespace}      ${name}
    IF          '${status}'!='FAIL'     FAIL       BuildConfig with name '${name}' is not deleted in '${namespace}'

Check If BuildConfig Exists
    [Arguments]    ${namespace}      ${name}
    ${status}   ${val}  Run keyword and Ignore Error   Oc Get  kind=BuildConfig  namespace=${namespace}     field_selector=metadata.name==${name}
    RETURN   ${status}

Dependent Build should not Present
     [Arguments]     ${selector}
     ${isExist}      Run Keyword and Return Status          OC Get     kind=Build    label_selector=buildconfig=${selector}
     IF     not ${isExist}        Log    Build attached to Build config has been deleted
     ...        ELSE    FAIL       Attached Build to Build config is not deleted

Check Image Build Status
  [Arguments]  ${target_status}     ${build_name}   ${namespace}=${APPLICATIONS_NAMESPACE}
  ${build_status}=  Get Build Status    namespace=${namespace}  build_search_term=${build_name}
  IF    "${build_status}" == "${target_status}"
  ...    Log   The '${build_name}' image match the expected target status
  ...  ELSE
  ...    Fail  The '${build_name}' image build status doesn't match the target status '${target_status}'

Search Last Build
    [Documentation]    Returns latest(sorted by creation time) build which match the ${build_name_includes}
    [Arguments]    ${namespace}    ${build_name_includes}
    ${build} =    Run    oc get builds --sort-by=.metadata.creationTimestamp -n ${namespace} | grep ${build_name_includes} | tail -n 1 | awk '{print $1;}'
    IF    "${build}" == "${EMPTY}"
        Fail    msg=Could not find any build including ${build_name_includes} in ${namespace} namespace
    END
    @{builds} =  Split String  ${build}  \n
    RETURN    ${builds}[-1]

Delete Build
    [Documentation]    Deletes the build ${build_name} in ${namespace}
    [Arguments]    ${namespace}    ${build_name}
    Oc Delete    kind=Build    namespace=${namespace}    field_selector=metadata.name==${build_name}

Start New Build
    [Documentation]    Starts new build using ${buildconfig}
    [Arguments]    ${namespace}    ${buildconfig}
    ${name} =    Run    oc start-build ${buildconfig} -n ${namespace}
    @{list_for} =    Split String    ${name}    ${SPACE}
    @{name_list} =    Split String    ${list_for}[0]    /
    RETURN    ${name_list}[1]

Get Build Status From Oc
    [Documentation]    Get Status of build using name
    [Arguments]    ${namespace}    ${build_name}
    ${status} =    Run    oc get builds -n ${namespace} -o json | jq '.items[] | select(.metadata.name == "${build_name}") | .status.phase'
    ${status}    Replace String    ${status}    "    ${EMPTY}
    RETURN    ${status}

Build Status Should Be
    [Documentation]    Gets build status and fails if not equal to  ${expected_status}
    [Arguments]    ${namespace}    ${build_name}    ${expected_status}=Complete
    ${status} =    Get Build Status From Oc    namespace=${namespace}    build_name=${build_name}
    IF    "${status}" != "${expected_status}"
       Fail    msg=Unexpected Build status for ${build_name} (expected_status: ${expected_status}, status: ${status})
    END

Build Status Should Not Be
    [Documentation]    Gets build status and fails if equal to ${unexpected_status}
    [Arguments]    ${namespace}    ${build_name}    ${unexpected_status}=Error
    ${status} =    Get Build Status From Oc    namespace=${namespace}    build_name=${build_name}
    IF    "${status}" == "${unexpected_status}"
       Fail    msg=Build ${build_name} shoud not have build status ${unexpected_status}
    END

Wait Until Build Exists
    [Documentation]    Waits until a build exist with name including ${build_name_includes} or timeout exceeded
    ...    Returns build name
    [Arguments]    ${namespace}    ${build_name_includes}    ${timeout}=20 min
    ${build_name} =    Wait Until Keyword Succeeds    ${timeout}    1 min
    ...    Search Last Build    namespace=${namespace}   build_name_includes=${build_name_includes}
    RETURN    ${build_name}

Wait Until Build Status Is
    [Documentation]    Check status build with ${expected_status} for every min until is succeed or timeout
    [Arguments]    ${namespace}    ${build_name}    ${expected_status}=Complete    ${timeout}=20 min
    Wait Until Keyword Succeeds    ${timeout}    1 min
    ...    Build Status Should Be    ${namespace}    ${build_name}    ${expected_status}

Wait Until All Builds Are Complete
    [Documentation]     Obtains the list of buildsconfigs in ${namespace} and, for each of
    ...    them,  search the last build with similar name and fails if state is Failed or Error.
    ...    If not, waits until state is Complete or ${build_timeout} is reached
    [Arguments]    ${namespace}    ${build_timeout}=20 min

    ${buildconfigs_data} =  Oc Get  kind=BuildConfig  namespace=${namespace}

    FOR    ${buildconfig_data}    IN    @{buildconfigs_data}
        ${buildconfig_name} =     Set Variable    ${buildconfig_data['metadata']['name']}
        ${build_name} =    Wait Until Build Exists    namespace=${namespace}   build_name_includes=${buildconfig_name}
        Build Status Should Not Be    namespace=${namespace}    build_name=${build_name}
        ...    unexpected_status=Error
        Build Status Should Not Be    namespace=${namespace}    build_name=${build_name}
        ...    unexpected_status=Failed
        Wait Until Build Status Is    namespace=${namespace}    build_name=${build_name}
        ...   expected_status=Complete    timeout=${build_timeout}
    END

Verify All Builds Are Complete
    [Documentation]    Verify all Builds in a namespace have status as Complete
    [Arguments]    ${namespace}
    ${builds_data} =    Oc Get  kind=Build  namespace=${namespace}
    FOR    ${build_data}    IN    @{builds_data}
        ${build_name} =     Set Variable    ${build_data['metadata']['name']}
        ${build_status} =    Set Variable    ${build_data['status']['phase']}
        Should Be Equal As Strings  ${build_status}  Complete
        ...    msg=Build ${build_name} is not in Complete status
    END

Provoke Image Build Failure
    [Documentation]    Starts New Build after some time it fail the build and return name of failed build
    [Arguments]    ${namespace}    ${build_name_includes}    ${build_config_name}    ${container_to_kill}
    ${build} =    Search Last Build    namespace=${namespace}    build_name_includes=${build_name_includes}
    Delete Build    namespace=${namespace}    build_name=${build}
    ${failed_build_name} =    Start New Build    namespace=${namespace}
    ...    buildconfig=${build_config_name}
    ${pod_name} =    Find First Pod By Name    namespace=${namespace}    pod_regex=${failed_build_name}
    Wait Until Build Status Is    namespace=${namespace}    build_name=${failed_build_name}
    ...    expected_status=Running
    Wait Until Container Exist  namespace=${namespace}  pod_name=${pod_name}  container_to_check=${container_to_kill}
    Sleep    60s    reason=Waiting extra time to make sure the container has started
    Run Command In Container    namespace=${namespace}    pod_name=${pod_name}    command=/bin/kill 1    container_name=${container_to_kill}
    Wait Until Build Status Is    namespace=${namespace}    build_name=${failed_build_name}
    ...    expected_status=Failed    timeout=5 min
    RETURN    ${failed_build_name}

Delete Failed Build And Start New One
    [Documentation]    It will delete failed build and start new build
    [Arguments]    ${namespace}    ${failed_build_name}    ${build_config_name}
    Delete Build    namespace=${namespace}    build_name=${failed_build_name}
    ${build_name} =    Start New Build    namespace=${namespace}
    ...    buildconfig=${build_config_name}
    Wait Until Build Status Is    namespace=${namespace}    build_name=${build_name}    expected_status=Complete

Delete Multiple Builds
    [Documentation]     Deletes Multiple Builds in the given namespace
    [Arguments]   @{build_name_list}  ${namespace}
    FOR    ${build}    IN    @{build_name_list}
        ${build_name}=  Search Last Build  namespace=${namespace}    build_name_includes=${build}
        Delete Build    namespace=${namespace}    build_name=${build_name}
    END

Rebuild Missing Or Failed Builds
    [Documentation]    Starts new build if build fails or is not started , Waits until all builds are complete
    [Arguments]    ${builds}  ${build_configs}  ${namespace}
    ${no_of_builds} =    Get Length    ${builds}
    FOR    ${ind}    IN RANGE    ${no_of_builds}
        ${build_name} =    Search Last Build    namespace=${namespace}
        ...    build_name_includes=${builds}[${ind}]
        IF    "${build_name}" == ""
            ${build_name} =    Start New Build    namespace=${namespace}
            ...    buildconfig=${build_configs}[${ind}]
        ELSE
            ${build_status} =    Get Build Status    namespace=${namespace}
            ...    build_search_term=${build_name}
            IF    "${build_status}" == "Failed" or "${build_status}" == "Error"
                Delete Build    namespace=${namespace}    build_name=${build_name}
                ${build_name} =    Start New Build    namespace=${namespace}
                ...    buildconfig=${build_configs}[${ind}]
            END
        END
        Wait Until Build Status Is    namespace=${namespace}    build_name=${build_name}
        ...    expected_status=Complete
    END
