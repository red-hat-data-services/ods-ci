*** Settings ***
Library   SeleniumLibrary
Library   JupyterLibrary
Library   OperatingSystem
Library   Process
Library   RequestsLibrary
Library   ../../libs/Helpers.py
Resource  Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource  Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource  RHOSi.resource


*** Variables ***
@{DEFAULT_CHARS_TO_ESCAPE}=    :    /    .


*** Keywords ***
Begin Web Test
    [Documentation]  This keyword should be used as a Suite Setup; it will log in to the
    ...              ODH dashboard, checking that the spawner is in a ready state before
    ...              handing control over to the test suites.
    [Arguments]    ${username}=${TEST_USER.USERNAME}    ${password}=${TEST_USER.PASSWORD}
    ...            ${auth_type}=${TEST_USER.AUTH_TYPE}
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${username}  ${password}  ${auth_type}
    Wait for RHODS Dashboard to Load
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub  ${username}  ${password}  ${auth_type}
    ${authorization_required} =  Is Service Account Authorization Required
    IF  ${authorization_required}  Authorize jupyterhub service account
    Fix Spawner Status
    Go To  ${ODH_DASHBOARD_URL}

End Web Test
    [Arguments]    ${username}=${TEST_USER.USERNAME}
    ${server}=  Run Keyword and Return Status  Page Should Contain Element  //div[@id='jp-top-panel']//div[contains(@class, 'p-MenuBar-itemLabel')][text() = 'File']
    IF  ${server}==True
        Clean Up Server    username=${username}
        Stop JupyterLab Notebook Server
        Capture Page Screenshot
    END
    Close Browser

Load Json File
    [Arguments]   ${file_path}
    ${j_file}=    Get File    ${file_path}
    ${obj}=    Evaluate    json.loads('''${j_file}''')    json
    RETURN    ${obj}

Load Json String
    [Arguments]     ${json_string}
    ${obj}=     Evaluate  json.loads("""${json_string}""")
    RETURN    ${obj}

Create File From Template
    [Documentation]     Create new file from a template file, by replacing environment variables values
    [Arguments]   ${template_file}    ${output_file}
    ${template_data} = 	Get File 	${template_file}
    ${output_data} = 	Replace Variables 	${template_data}
    Create File  ${output_file}  ${output_data}

Export Variables From File
    [Documentation]     Export variables from file with lines format of: variable=value
    [Arguments]   ${variables_file}
    ${file_data} = 	Get File 	${variables_file}
    @{list} =    Split to lines  ${file_data}
    FOR    ${line}     IN    @{list}
        Log     ${line}
        ${line} =    Remove String    ${line}    export
        ${var_and_value} =    Split String    string=${line}    separator==
        Set Suite Variable    ${${var_and_value}[0]}    ${var_and_value}[1]
    END

Get CSS Property Value
    [Documentation]    Get the CSS property value of a given element
    [Arguments]    ${locator}    ${property_name}
    ${element}=       Get WebElement    ${locator}
    ${css_prop}=    Call Method       ${element}    value_of_css_property    ${property_name}
    RETURN     ${css_prop}

CSS Property Value Should Be
    [Documentation]     Compare the actual CSS property value with the expected one
    [Arguments]   ${locator}    ${property}    ${exp_value}   ${operation}=equal
    ${el_text}=   Get Text   xpath:${locator}
    Log    Text of the target element: ${el_text}
    ${actual_value}=    Get CSS Property Value   xpath:${locator}    ${property}
    IF    $operation == "contains"
        Run Keyword And Continue On Failure   Should Contain    ${actual_value}    ${exp_value}
    ELSE
        Run Keyword And Continue On Failure   Should Be Equal    ${actual_value}    ${exp_value}
    END

#robocop: disable: line-too-long
Get RHODS Version
    [Documentation]    Return RHODS/ODH operator version number.
    ...    Will fetch version only if $RHODS_VERSION was not already set, or $force_fetch is True.
    [Arguments]    ${force_fetch}=False
    IF  "${RHODS_VERSION}" == "${None}" or "${force_fetch}"=="True"
        IF  "${PRODUCT}" == "${None}" or "${PRODUCT}" == "RHODS"
            ${RHODS_VERSION}=  Run  oc get csv -n ${OPERATOR_NAMESPACE} | grep "rhods-operator" | awk -F ' {2,}' '{print $3}'
        ELSE
            ${RHODS_VERSION}=  Run  oc get csv -n ${OPERATOR_NAMESPACE} | grep "opendatahub" | awk -F ' {2,}' '{print $3}'
        END
    END
    Log  Product:${PRODUCT} Version:${RHODS_VERSION}
    RETURN  ${RHODS_VERSION}

#robocop: disable: line-too-long
Get CodeFlare Version
    [Documentation]    Return RHODS CodeFlare operator version number.
    ...    Will fetch version only if $CODEFLARE_VERSION was not already set, or $force_fetch is True.
    [Arguments]    ${force_fetch}=False
    IF  "${CODEFLARE_VERSION}" == "${None}" or "${force_fetch}" == "True"
        IF  "${PRODUCT}" == "${None}" or "${PRODUCT}" == "RHODS"
            ${CODEFLARE_VERSION}=  Run  oc get csv -n openshift-operators | grep "rhods-codeflare-operator" | awk '{print $1}' | sed 's/rhods-codeflare-operator.//'
        ELSE
            ${CODEFLARE_VERSION}=  Run  oc get csv -n openshift-operators | grep "codeflare-operator" | awk -F ' {2,}' '{print $3}'
        END
    END
    Log  Product:${PRODUCT} CodeFlare Version:${CODEFLARE_VERSION}
    RETURN  ${CODEFLARE_VERSION}

Get Cluster ID
    [Documentation]     Retrieves the ID of the currently connected cluster
    ${cluster_id}=   Run    oc get clusterversion -o json | jq .items[].spec.clusterID
    IF    not $cluster_id
        Fail    Unable to retrieve cluster ID. Are you logged using `oc login` command?
    END
    ${cluster_id}=    Remove String    ${cluster_id}    "
    RETURN    ${cluster_id}

Get Cluster Name By Cluster ID
    [Documentation]     Retrieves the name of the currently connected cluster given its ID
    [Arguments]     ${cluster_id}
    ${cluster_name}=    Get Cluster Name     cluster_identifier=${cluster_id}
    IF    not $cluster_name
        Fail    Unable to retrieve cluster name for cluster ID ${cluster_id}
    END
    RETURN    ${cluster_name}

Wait Until HTTP Status Code Is
    [Documentation]     Waits Until Status Code Of URl Matches expected Status Code
    [Arguments]  ${url}   ${expected_status_code}=200  ${retry}=1m   ${retry_interval}=15s
    Wait Until Keyword Succeeds    ${retry}   ${retry_interval}
    ...    Check HTTP Status Code    ${url}    ${expected_status_code}

Check HTTP Status Code
    [Documentation]     Verifies Status Code of URL Matches Expected Status Code
    [Arguments]  ${link_to_check}    ${expected}=200    ${timeout}=20   ${verify_ssl}=${True}
    ${headers}=    Create Dictionary    User-Agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36
    ${response}=    RequestsLibrary.GET  ${link_to_check}   expected_status=any    headers=${headers}   timeout=${timeout}  verify=${verify_ssl}
    Run Keyword And Continue On Failure  Status Should Be  ${expected}
    RETURN  ${response.status_code}

URLs HTTP Status Code Should Be Equal To
    [Documentation]    Given a list of link web elements, extracts the URLs and
    ...                checks if the http status code expected one is equal to the
    [Arguments]    ${link_elements}    ${expected_status}=200    ${timeout}=20
    FOR    ${idx}    ${ext_link}    IN ENUMERATE    @{link_elements}    start=1
        ${href}=    Get Element Attribute    ${ext_link}    href
        ${text}=    Get Text    ${ext_link}
        ${status}=    Run Keyword And Continue On Failure    Check HTTP Status Code    link_to_check=${href}
        ...                                                                            expected=${expected_status}
        Log To Console    ${idx}. ${href} gets status code ${status}
    END

Get List Of Atrributes
    [Documentation]    Returns the list of attributes
    [Arguments]    ${xpath}    ${attribute}
    ${xpath} =    Remove String    ${xpath}    ]
    ${link_elements}=
    ...    Get WebElements    ${xpath} and not(starts-with(@${attribute}, '#'))]
    ${list_of_atrributes}=    Create List
    FOR    ${ext_link}    IN    @{link_elements}
        ${ids}=    Get Element Attribute    ${ext_link}    ${attribute}
        Append To List    ${list_of_atrributes}    ${ids}
    END
    RETURN    ${list_of_atrributes}

Verify NPM Version
    [Documentation]  Verifies the installed version of an NPM library
    ...    against an expected version in a given pod/container
    [Arguments]  ${library}  ${expected_version}  ${pod}  ${namespace}  ${container}=""  ${prefix}=""  ${depth}=0
    ${installed_version} =  Run  oc exec -n ${namespace} ${pod} -c ${container} -- npm list --prefix ${prefix} --depth=${depth} | awk -F@ '/${library}/ { print $2}'
    Should Be Equal  ${installed_version}  ${expected_version}

Get Cluster Name From Console URL
    [Documentation]    Get the cluster name from the Openshift console URL
    ${name}=    Split String    ${OCP_CONSOLE_URL}        .
    RETURN    ${name}[2]

Clean Resource YAML Before Creating It
    [Documentation]    Removes from a yaml of an Openshift resource the metadata which prevent
    ...                the yaml to be applied after being copied
    [Arguments]    ${yaml_data}
    ${clean_yaml_data}=     Copy Dictionary    dictionary=${yaml_data}  deepcopy=True
    Remove From Dictionary    ${clean_yaml_data}[metadata]  managedFields  resourceVersion  uid  creationTimestamp  annotations
    RETURN   ${clean_yaml_data}

Skip If RHODS Version Greater Or Equal Than
    [Documentation]    Skips test if RHODS version is greater or equal than ${version}
    [Arguments]    ${version}    ${msg}=${EMPTY}

    ${version-check}=  Is RHODS Version Greater Or Equal Than  ${version}

    IF    "${msg}" != "${EMPTY}"
       Skip If    condition=${version-check}==True    msg=${msg}
    ELSE
       Skip If    condition=${version-check}==True    msg=This test is skipped for RHODS ${version} or greater
    END

Skip If RHODS Is Self-Managed
    [Documentation]    Skips test if RHODS is installed as Self-managed or PRODUCT=ODH
    [Arguments]    ${msg}=${EMPTY}
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    "${msg}" != "${EMPTY}"
       Skip If    condition=${is_self_managed}==True    msg=${msg}
    ELSE
       Skip If    condition=${is_self_managed}==True    msg=This test is skipped for Self-managed RHODS
    END

Skip If RHODS Is Managed
    [Documentation]    Skips test if RHODS is installed as Self-managed
    [Arguments]    ${msg}=${EMPTY}
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    "${msg}" != "${EMPTY}"
       Skip If    condition=${is_self_managed}==False    msg=${msg}
    ELSE
       Skip If    condition=${is_self_managed}==False    msg=This test is skipped for Managed RHODS
    END

Run Keyword If RHODS Is Managed
    [Documentation]    Runs keyword ${name} using  @{arguments} if RHODS is Managed (Cloud Version)
    [Arguments]    ${name}    @{arguments}
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed} == False    Run Keyword    ${name}    @{arguments}

Run Keyword If RHODS Is Self-Managed
    [Documentation]    Runs keyword ${name} using  @{arguments}
    ...    if RHODS is Self-Managed or PRODUCT=ODH
    [Arguments]    ${name}    @{arguments}
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed} == True    Run Keyword    ${name}    @{arguments}

Get Domain From Current URL
    [Documentation]    Gets the lowest level domain from the current URL (i.e. everything before the first dot in the URL)
    ...    e.g. https://console-openshift-console.apps.<cluster>.rhods.ccitredhat.com -> https://console-openshift-console
    ...    e.g. https://rhods-dashboard-redhat-ods-applications.apps.<cluster>.rhods.ccitredhat.com/ -> https://rhods-dashboard-redhat-ods-applications
    ${current_url} =    Get Location
    ${domain} =    Fetch From Left    string=${current_url}    marker=.
    RETURN    ${domain}

Is Current Domain Equal To
    [Documentation]    Compare the lowest level domain to a given string
    ...   and returns True/False
    [Arguments]    ${url}
    ${domain} =    Get Domain From Current URL
    ${comparison} =    Run Keyword And Return Status    Should Be Equal As Strings
    ...    ${domain}    ${url}
    RETURN    ${comparison}

Get OAuth Cookie
    [Documentation]     Fetches the "_oauth_proxy" cookie from Dashboard page.
    ...                 You can use the value from this cookie to perform login in API calls.
    ...                 It assumes Dashboard UI has been launched and login performed using UI.
    ${cookie}=     Get Cookie  _oauth_proxy
    RETURN    ${cookie.value}

Is Generic Modal Displayed
    [Documentation]    Checks if a modal window is displayed on the page.
    ...                It assumes the html "id" contains "pf-modal-", but it can be
    ...                piloted with ${id} and ${partial_match} arguments
    [Arguments]     ${id}=pf-modal-  ${partial_match}=${TRUE}  ${timeout}=10s
    IF    ${partial_match} == ${TRUE}
        ${is_displayed}=    Run Keyword And Return Status
        ...                 Page Should Contain Element    xpath=//*[contains(@id,"${id}")]
    ELSE
        ${is_displayed}=    Run Keyword And Return Status
        ...                 Page Should Contain Element    xpath=//*[@id="${id}")]
    END
    RETURN    ${is_displayed}

Wait Until Generic Modal Disappears
    [Documentation]    Waits until a modal window disappears from the page.
    ...                It assumes the html "id" contains "pf-modal-", but it can be
    ...                piloted with ${id} and ${partial_match} arguments
    [Arguments]     ${id}=pf-modal-  ${partial_match}=${TRUE}  ${timeout}=10s
    ${is_modal}=    Is Generic Modal Displayed
    IF    ${is_modal} == ${TRUE}
        IF    ${partial_match} == ${TRUE}
            Wait Until Page Does Not Contain Element    xpath=//*[contains(@id,"${id}")]    timeout=${timeout}
        ELSE
            Wait Until Page Does Not Contain Element    xpath=//*[@id="${id}")]    timeout=${timeout}
        END
    ELSE
        Log     No Modals on the screen right now..     level=WARN
    END

Wait Until Generic Modal Appears
    [Documentation]    Waits until a modal window appears on the page.
    ...                It assumes the html "id" contains "pf-modal-", but it can be
    ...                piloted with ${id} and ${partial_match} arguments
    [Arguments]     ${id}=pf-modal-  ${partial_match}=${TRUE}  ${timeout}=10s
    ${is_modal}=    Is Generic Modal Displayed
    IF    ${is_modal} == ${FALSE}
        IF    ${partial_match} == ${TRUE}
            Wait Until Page Contains Element    xpath=//*[contains(@id,"${id}")]    timeout=${timeout}
        ELSE
            Wait Until Page Contains Element    xpath=//*[@id="${id}")]    timeout=${timeout}
        END
    ELSE
        Log     No Modals on the screen right now..     level=WARN
    END

Close Generic Modal If Present
    [Documentation]    Close a modal window from the page and waits for it to disappear
    ${is_modal}=    Is Generic Modal Displayed
    IF    ${is_modal} == ${TRUE}
        Click Element    xpath=//button[@aria-label="Close"]
        Wait Until Generic Modal Disappears
    END

Extract Value From JSON Path
    [Documentation]    Given a Python JSON Object (i.e., a dictionary) and
    ...                a desired path (e.g., spec.resources.limits.cpu), it retrieves
    ...                the value by looping into the dictionary.
    [Arguments]    ${json_dict}    ${path}
    ${path_splits}=    Split String    string=${path}    separator=.
    ${value}=    Set Variable    ${json_dict}
    FOR    ${idx}    ${split}    IN ENUMERATE    @{path_splits}  start=1
        Log    ${idx} - ${split}
        ${present}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    dictionary=${value}    key=${split}
        IF    ${present} == ${TRUE}
            ${value}=    Set Variable    ${value["${split}"]}
        ELSE
            ${value}=    Set Variable    ${EMPTY}
            Log    message=${path} or part of it is not found in the given JSON
            ...    level=ERROR
            BREAK
        END
    END
    RETURN    ${value}

Extract URLs From Text
    [Documentation]    Reads a text and extracts portions which match the pattern
    ...                of a URL
    [Arguments]    ${text}
    ${urls}=     Get Regexp Matches   ${text}   (?:(?:(?:ftp|http)[s]*:\/\/|www\.)[^\.]+\.[^ \n]+)
    RETURN    ${urls}

Run And Watch Command
  [Documentation]    Run any shell command (including args) with optional:
  ...    Timeout: 10 minutes by default.
  ...    Output Should Contain: Verify an excpected text to exists in command output.
  ...    Output Should Not Contain: Verify an excpected text to not exists in command output.
  [Arguments]    ${command}    ${timeout}=10 min   ${output_should_contain}=${NONE}    ${output_should_not_contain}=${NONE}
  ...            ${cwd}=${CURDIR}
  Log    Watching command output: ${command}   console=True
  ${is_test}=    Run keyword And Return Status    Variable Should Exist     ${TEST NAME}
  IF    ${is_test} == ${FALSE}
    ${incremental}=    Generate Random String    5    [NUMBERS]
    ${TEST NAME}=    Set Variable    testlogs-${incremental}    
  END
  ${process_log} =    Set Variable    ${OUTPUT DIR}/${TEST NAME}.log
  ${temp_log} =    Set Variable    ${TEMPDIR}/${TEST NAME}.log
  Create File    ${process_log}
  Create File    ${temp_log}
  ${process_id} =    Start Process    ${command}    shell=True    stdout=${process_log}
  ...    stderr=STDOUT    cwd=${cwd}
  Log    Shell process started in the background   console=True
  Wait Until Keyword Succeeds    ${timeout}    10 s
  ...    Check Process Output and Status    ${process_id}    ${process_log}    ${temp_log}
  ${proc_result} =	    Wait For Process    ${process_id}    timeout=3 secs
  Terminate Process    ${process_id}    kill=true
  Should Be Equal As Integers	    ${proc_result.rc}    0    msg=Error occured while running: ${command}
  IF  "${output_should_contain}" != "${NONE}"
    ${result} =    Run Process 	grep '${output_should_contain}' '${process_log}'    shell=yes
    Should Be True    ${result.rc} == 0    msg='${process_log}' should contain '${output_should_contain}'
  END
  IF  "${output_should_not_contain}" != "${NONE}"
    ${result} =    Run Process 	grep -L '${output_should_not_contain}' '${process_log}' | grep .    shell=yes
    Should Be True    ${result.rc} == 0    msg='${process_log}' should not contain '${output_should_not_contain}'
  END
  RETURN    ${proc_result.rc}

Check Process Output and Status
  [Documentation]    Helper keyward for 'Run And Watch Command', to tail proccess and check its status
  [Arguments]    ${process_id}    ${process_log}    ${temp_log}
  Log To Console    .    no_newline=true
  ${log_data} = 	Get File 	${process_log}
  ${temp_log_data} = 	Get File 	${temp_log}
  ${last_line_index} =    Get Line Count    ${temp_log_data}
  @{new_lines} =    Split To Lines    ${log_data}    ${last_line_index}
  FOR    ${line}    IN    @{new_lines}
      Log To Console    ${line}
  END
  Create File    ${temp_log}    ${log_data}
  Process Should Be Stopped	    ${process_id}

Escape String Chars
    [Arguments]    ${str}    ${chars}=@{DEFAULT_CHARS_TO_ESCAPE}
    FOR    ${char}    IN    @{chars}
        ${str}=    Replace String   ${str}    ${char}    \\${char}
    END
    RETURN    ${str}
