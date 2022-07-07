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
  [Return]  ${build_status}

Delete BuildConfig using Name
    [Arguments]    ${namespace}                    ${name}
    ${status}      Check If BuildConfig Exists    ${namespace}      ${name}
    Run Keyword If          '${status}'=='PASS'   OpenShiftCLI.Delete  kind=BuildConfig   name=${name}   namespace=${namespace}
    ...        ELSE          FAIL        No BuildConfig present with name '${name}' in '${namespace}' namespace, Check the BuildConfig name and namespace provide is correct and try again
    Dependent Build should not Present     ${name}
    ${status}      Check If BuildConfig Exists    ${namespace}      ${name}
    Run Keyword IF          '${status}'!='FAIL'     FAIL       BuildConfig with name '${name}' is not deleted in '${namespace}'

Check If BuildConfig Exists
    [Arguments]    ${namespace}      ${name}
    ${status}   ${val}  Run keyword and Ignore Error   OpenShiftCLI.Get  kind=BuildConfig  namespace=${namespace}     field_selector=metadata.name==${name}
    [Return]   ${status}

Dependent Build should not Present
     [Arguments]     ${selector}
     ${isExist}      Run Keyword and Return Status          OpenShiftCLI.Get     kind=Build    label_selector=buildconfig=${selector}
     Run Keyword IF     not ${isExist}        Log    Build attached to Build config has been deleted
     ...        ELSE    FAIL       Attached Build to Build config is not deleted

Check Image Build Status
  [Arguments]  ${target_status}     ${build_name}   ${namespace}=redhat-ods-applications
  ${build_status}=  Get Build Status    namespace=${namespace}  build_search_term=${build_name}
  Run Keyword If    "${build_status}" == "${target_status}"
  ...    Log   The '${build_name}' image match the expected target status
  ...  ELSE
  ...    Fail  The '${build_name}' image build status doesn't match the target status '${target_status}'

Search Last Build
    [Documentation]    Returns latest(sorted by creation time) build which match the ${build_name_includes}
    [Arguments]    ${namespace}    ${build_name_includes}
    ${build} =    Run    oc get builds --sort-by=.metadata.creationTimestamp -n ${namespace} | grep ${build_name_includes} | awk '{print $1;}'
    @{builds} =  Split String  ${build}  \n
    [Return]    ${builds}[-1]

Delete Build
    [Documentation]    Deletes the build ${build_name} in ${namespace}
    [Arguments]    ${namespace}    ${build_name}
    OpenShiftCLI.Delete    kind=Build    namespace=${namespace}    field_selector=metadata.name==${build_name}

Start New Build
    [Documentation]    Starts new build using ${buildconfig}
    [Arguments]    ${namespace}    ${buildconfig}
    ${name} =    Run    oc start-build ${buildconfig} -n ${namespace}
    @{list_for} =    Split String    ${name}    ${SPACE}
    @{name_list} =    Split String    ${list_for}[0]    /
    [Return]    ${name_list}[1]

Get Build Status From Oc
    [Documentation]    Get Status of build using name
    [Arguments]    ${namespace}    ${build_name}
    ${status} =    Run    oc get builds -n ${namespace} -o json | jq '.items[] | select(.metadata.name == "${build_name}") | .status.phase'
    ${status}    Replace String    ${status}    "    ${EMPTY}
    [Return]    ${status}

Build Status Should Be
    [Documentation]    Get status and check with ${expected_status}
    [Arguments]    ${namespace}    ${build_name}    ${expected_status}=Complete
    ${status} =    Get Build Status From Oc    namespace=${namespace}    build_name=${build_name}
    Should Be Equal    ${status}    ${expected_status}

Wait Until Build Status Is
    [Documentation]    Check status build with ${expected_status} for every min until is succeed or timeout
    [Arguments]    ${namespace}    ${build_name}    ${expected_status}=Complete    ${timeout}=20 min
    Wait Until Keyword Succeeds    ${timeout}    1 min
    ...    Build Status Should Be    ${namespace}    ${build_name}    ${expected_status}

Wait Until All Builds Are Complete
    [Documentation]     Waits until all the builds are in Complete State
    [Arguments]    ${namespace}
    ${builds_data} =  Oc Get  kind=Build  namespace=${namespace}
    FOR    ${build_data}    IN    @{builds_data}
        Wait Until Build Status Is    namespace=${namespace}    build_name=${build_data['metadata']['name']}  expected_status=Complete
    END

Provoke Image Build Failure
    [Documentation]    Starts New Build after some time it fail the build and return name of failed build
    [Arguments]    ${namespace}    ${build_name_includes}    ${build_config_name}    ${container_to_kill}
    ${build} =    Search Last Build    namespace=${namespace}    build_name_includes=${build_name_includes}
    Delete Build    namespace=${namespace}    build_name=${build}
    ${failed_build_name} =    Start New Build    namespace=${namespace}
    ...    buildconfig=${build_config_name}
    ${pod_name} =    Find First Pod By Name    namespace=${namespace}    pod_start_with=${failed_build_name}
    Wait Until Build Status Is    namespace=${namespace}    build_name=${failed_build_name}
    ...    expected_status=Running
    Wait Until Container Exist  namespace=${namespace}  pod_name=${pod_name}  container_to_check=${container_to_kill}
    Sleep    60s    reason=Waiting extra time to make sure the container has started
    Run Command In Container    namespace=${namespace}    pod_name=${pod_name}    command=/bin/kill 1    container_name=${container_to_kill}
    Wait Until Build Status Is    namespace=${namespace}    build_name=${failed_build_name}
    ...    expected_status=Failed    timeout=5 min
    [Return]    ${failed_build_name}

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