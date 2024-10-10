*** Settings ***
Library           OpenShiftLibrary
Resource          ../../Resources/Page/Components/Components.resource
Resource          ../../Resources/Page/OCPDashboard/OperatorHub/InstallODH.robot
Resource          ../../Resources/RHOSi.resource
Resource          ../../Resources/ODS.robot
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource          ../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource          ../../Resources/Page/LoginPage.robot
Resource          ../../Resources/Page/OCPLogin/OCPLogin.robot
Resource          ../../Resources/Common.robot
Resource          ../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource          ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource          ../../Resources/Page/HybridCloudConsole/OCM.robot
Suite Setup       Dashboard Suite Setup
Suite Teardown    RHOSi Teardown
Test Setup        Dashboard Test Setup
Test Teardown     Dashboard Test Teardown
Test Tags         Dashboard

*** Variables ***
@{IMAGES}                               PyTorch  TensorFlow  CUDA
@{BUILDS_TO_BE_DELETED}                 pytorch  tensorflow  minimal  cuda-s2i-thoth
@{BUILD_CONFIGS}                        11.4.2-cuda-s2i-base-ubi8    11.4.2-cuda-s2i-core-ubi8
...                                     11.4.2-cuda-s2i-py38-ubi8    11.4.2-cuda-s2i-thoth-ubi8-py38
...                                     s2i-minimal-gpu-cuda-11.4.2-notebook  s2i-pytorch-gpu-cuda-11.4.2-notebook
...                                     tensorflow-gpu-cuda-11.4.2-notebook
@{BUILDS_TO_BE_CHECKED}                 cuda-s2i-base    cuda-s2i-core    cuda-s2i-py    cuda-s2i-thoth
...                                     minimal    pytorch  tensorflow
${openvino_appname}           ovms
${openvino_container_name}    OpenVINO
${openvino_operator_name}     OpenVINO Toolkit Operator
${openvino_dashboard_app_id}     openvino
${CUSTOM_EMPTY_GROUP}                   empty-group
${CUSTOM_INEXISTENT_GROUP}              inexistent-group
@{DOC_LINKS_EXP}        https://access.redhat.com/documentation/en-us/red_hat_openshift_data_science
...                     https://access.redhat.com/support/cases/#/case/new/open-case?caseCreate=true
...                     https://access.redhat.com/documentation/en-us/red_hat_openshift_data_science


*** Test Cases ***
Verify That Login Page Is Shown When Reaching The RHODS Page
    [Tags]      Tier1
    ...         ODS-694
    ...         ODS-355
    [Setup]     Test Setup For Login Page
    RHODS Dahsboard Pod Should Contain OauthProxy Container
    Check OpenShift Login Visible

Verify Content In RHODS Explore Section
    [Documentation]    It verifies if the content present in Explore section of RHODS corresponds to expected one.
    ...    It compares the actual data with the one registered in a JSON file. The checks are about:
    ...    - Card's details (text, badges, images)
    ...    - Sidebar (titles, links text, links status)
    [Tags]    Sanity
    ...       ODS-488    ODS-993    ODS-749    ODS-352    ODS-282
    ...       AutomationBugOnODH
    # TODO: In ODH there are only 2 Apps, we excpect 7 Apps according to:
    # tests/Resources/Files/AppsInfoDictionary_latest.json
    ${EXP_DATA_DICT}=    Load Expected Data Of RHODS Explore Section
    Menu.Navigate To Page    Applications    Explore
    Wait For RHODS Dashboard To Load    expected_page=Explore
    Check Number Of Displayed Cards Is Correct    expected_data=${EXP_DATA_DICT}
    Check Cards Details Are Correct    expected_data=${EXP_DATA_DICT}

Verify RHODS Explore Section Contains Only Expected ISVs
    [Documentation]    It verifies if the ISV reported in Explore section of RHODS corresponds to expected ones
    [Tags]    Smoke
    ...       ODS-1890
    ...       AutomationBugOnODH
    # TODO: In ODH there are only 2 Apps, we excpect 7 Apps according to:
    # tests/Resources/Files/AppsInfoDictionary_latest.json
    ${EXP_DATA_DICT}=    Load Expected Data Of RHODS Explore Section
    Menu.Navigate To Page    Applications    Explore
    Wait For RHODS Dashboard To Load    expected_page=Explore
    Check Number Of Displayed Cards Is Correct    expected_data=${EXP_DATA_DICT}
    Check Dashboard Diplayes Expected ISVs    expected_data=${EXP_DATA_DICT}

Verify License Of Disabled Cards Can Be Re-validated
    [Documentation]   Verifies it is possible to re-validate the license of a disabled card
    ...               from Enabled page. it uses Anaconda CE as example to test the feature.
    ...               It also verifies if it is possible to remove a disabled card.
    [Tags]    Tier1
    ...       ODS-1097   ODS-357
    Enable Anaconda    license_key=${ANACONDA_CE.ACTIVATION_KEY}
    Menu.Navigate To Page    Applications    Enabled
    Wait Until RHODS Dashboard Jupyter Is Visible
    Verify Anaconda Service Is Enabled Based On Version
    Close All Browsers
    Delete ConfigMap Using Name    ${APPLICATIONS_NAMESPACE}    anaconda-ce-validation-result
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Re-Validate License For Disabled Application From Enabled Page    app_id=${ANACONDA_APPNAME}
    Insert Anaconda License Key    license_key=${ANACONDA_CE.ACTIVATION_KEY}
    Validate Anaconda License Key
    Verify Anaconda Success Message Based On Version
    Verify Anaconda Service Is Enabled Based On Version
    Capture Page Screenshot    after_revalidation.png
    [Teardown]    Remove Anaconda Component

Verify CSS Style Of Getting Started Descriptions
    [Documentation]    Verifies the CSS style is not changed. It uses JupyterHub card as sample
    [Tags]    Tier1
    ...       ODS-1165
    Menu.Navigate To Page    Applications    Explore
    Wait For RHODS Dashboard To Load    expected_page=Explore
    ${status}=    Open Get Started Sidebar And Return Status    card_locator=${JUPYTER_CARD_XP}
    Should Be Equal    ${status}    ${TRUE}
    Capture Page Screenshot    get_started_sidebar.png
    Verify Jupyter Card CSS Style

Verify Documentation Links HTTP Status Code
    [Documentation]    It verifies the documentation links present in question mark and
    ...    also checks the RHODS dcoumentation link present in resource page.
    ...    ProductBug: RHOAIENG-11451 (on ODH only)
    [Tags]    Smoke
    ...       ODS-327    ODS-492
    ${links}=  Get RHODS Documentation Links From Dashboard
    # Compare Doc Links only by number, since ODH and RHOAI have diffrent URLs (but same count)
    Lists Size Should Be Equal    ${links}    ${DOC_LINKS_EXP}
    Check External Links Status     links=${links}

Verify Logged In Users Are Displayed In The Dashboard
    [Documentation]    It verifies that logged in users username is displayed on RHODS Dashboard.
    [Tags]    Sanity
    ...       ODS-354
    Verify Username Displayed On RHODS Dashboard   ${TEST_USER.USERNAME}

Search and Verify GPU Items Appears In Resources Page
    [Documentation]    Verifies if all the expected learning items for GPU are listed
    ...                in RHODS Dashboard > Resources page
    [Tags]    Sanity
    ...       ODS-1226
    ...       ExcludeOnODH
    Search Items In Resources Section    GPU
    Check GPU Resources

Verify Favorite Resource Cards
    [Tags]    ODS-389    ODS-384
    ...       Tier1
    [Documentation]    Verifies the item in Resource page can be marked se favorite.
    ...                It checks if favorite items are always listed as first regardless
    ...                the view type or sorting
    Click Link    Resources
    Wait Until Resource Page Is Loaded
    Sort Resources By    name
    ${list_of_tile_ids} =    Get List Of Ids Of Tiles
    Verify Star Icons Are Clickable    ${list_of_tile_ids}
    ${favorite_ids} =    Get Slice From List    ${list_of_tile_ids}    ${2}    ${7}
    Add The Items In Favorites    @{favorite_ids}
    ${list_of_tile_ids} =    Get List Of Ids Of Tiles
    Favorite Items Should Be Listed First    ${favorite_ids}    ${list_of_tile_ids}    ${5}
    Click Button    //*[@id="list-view"]
    Sleep    0.5s
    ${list_view_tiles} =    Get The List Of Ids of Tiles In List View
    Favorite Items Should Be Listed First    ${favorite_ids}    ${list_view_tiles}    ${5}
    Click Button    //*[@id="card-view"]
    Sleep    0.5s
    Favorite Items Should Be Listed First When Sorted By    ${favorite_ids}    type
    Favorite Items Should Be Listed First When Sorted By    ${favorite_ids}    application
    Favorite Items Should Be Listed First When Sorted By    ${favorite_ids}    duration
    [Teardown]    Remove Items From favorites    @{favorite_ids}

Verify Notifications Are Shown When Notebook Builds Have Not Started
    [Documentation]     Verifies that Notifications are shown in RHODS Dashboard when Notebook builds haven't started
    [Tags]    Tier3
    ...       ODS-1347  ODS-444
    ...       Execution-Time-Over-30m
    ...       AutomationBug
    ...       FlakyTest
    Delete Multiple Builds  @{BUILDS_TO_BE_DELETED}  namespace=${APPLICATIONS_NAMESPACE}
    ${last_cuda_build}=  Start New Build    namespace=${APPLICATIONS_NAMESPACE}    buildconfig=11.4.2-cuda-s2i-thoth-ubi8-py38
    Verify Notification Saying Notebook Builds Not Started
    Clear Dashboard Notifications
    Wait Until Build Status Is    namespace=${APPLICATIONS_NAMESPACE}    build_name=${last_cuda_build}  expected_status=Complete
    Remove Values From List    ${IMAGES}  CUDA
    Verify Notification Saying Notebook Builds Not Started
    RHODS Notification Drawer Should Contain    message=Notebook images are building
    RHODS Notification Drawer Should Not Contain    message=CUDA
    [Teardown]   Wait Until Remaining Builds Are Complete And Close Browser

Verify "Enabled" Keeps Being Available After One Of The ISV Operators If Uninstalled
   [Documentation]     Verify "Enabled" keeps being available after one of the ISV operators if uninstalled
   [Tags]      Tier3
   ...         ODS-1491
   Check And Install Operator in Openshift    ${openvino_operator_name}   ${openvino_appname}
   Close All Browsers
   Verify Operator Is Added On ODS Dashboard  operator_name=${openvino_container_name}
   Uninstall Operator And Check Enabled Page Is Rendering
   ...    operator_name=${openvino_operator_name}  operator_appname=${openvino_appname}
   [Teardown]    Run Keyword And Ignore Error
   ...    Check And Uninstall Operator In Openshift    
   ...    ${openvino_operator_name}   ${openvino_appname}    ${openvino_dashboard_app_id}

Verify Error Message In Logs When A RHODS Group Is Empty
    [Documentation]     Verifies the messages printed out in the logs of
    ...                 dashboard pods are the ones expected when an empty group
    ...                 is set as admin in OdhDashboardConfig CRD
    [Tags]  Tier2
    ...     ODS-1408
    ...     AutomationBug
    [Setup]     Set Variables For Group Testing
    Create Group    group_name=${CUSTOM_EMPTY_GROUP}
    ${lengths_dict_before}=     Get Lengths Of Dashboard Pods Logs
    Set RHODS Admins Group Empty Group
    Logs Of Dashboard Pods Should Not Contain New Lines     lengths_dict=${lengths_dict_before}
    Set Default Groups And Check Logs Do Not Change   delete_group=${FALSE}
    Set RHODS Users Group Empty Group
    Logs Of Dashboard Pods Should Not Contain New Lines    lengths_dict=${lengths_dict_before}
    [Teardown]      Set Default Groups And Check Logs Do Not Change     delete_group=${TRUE}

Verify Error Message In Logs When A RHODS Group Does Not Exist
    [Documentation]     Verifies the messages printed out in the logs of
    ...                 dashboard pods are the ones expected when an inexistent group
    ...                 is set as admin in OdhDashboardConfig CRD
    [Tags]  Tier2
    ...     ODS-1494
    ...     AutomationBug
    [Setup]     Set Variables For Group Testing
    ${lengths_dict_before}=     Get Lengths Of Dashboard Pods Logs
    Set RHODS Admins Group To Inexistent Group
    ${lengths_dict_after}=  New Lines In Logs Of Dashboard Pods Should Contain
    ...     exp_msg=${EXP_ERROR_INEXISTENT_GRP}
    ...     prev_logs_lengths=${lengths_dict_before}
    Set Default Groups And Check Logs Do Not Change
    Set RHODS Users Group To Inexistent Group
    Logs Of Dashboard Pods Should Not Contain New Lines    lengths_dict=${lengths_dict_after}
    [Teardown]      Set Default Groups And Check Logs Do Not Change

Verify Error Message In Logs When All Authenticated Users Are Set As RHODS Admins
    [Documentation]     Verifies the messages printed out in the logs of
    ...                 dashboard pods are the ones expected when 'system:authenticated'
    ...                 is set as admin in OdhDashboardConfig CRD
    [Tags]    Tier2
    ...       ODS-1500
    ...       AutomationBug
    [Setup]     Set Variables For Group Testing
    ${lengths_dict_before}=     Get Lengths Of Dashboard Pods Logs
    Set RHODS Admins Group To system:authenticated
    ${lengths_dict_after}=    New Lines In Logs Of Dashboard Pods Should Contain
    ...     exp_msg=${EXP_ERROR_SYS_AUTH}
    ...     prev_logs_lengths=${lengths_dict_before}
    [Teardown]      Set Default Groups And Check Logs Do Not Change

Verify Dashboard Pod Is Not Getting Restarted
    [Documentation]    Verify Dashboard Pod container doesn't restarted
    [Tags]    Sanity
    ...       ODS-374
    ${pod_names}    Get POD Names    ${APPLICATIONS_NAMESPACE}    app=${DASHBOARD_APP_NAME}
    Verify Containers Have Zero Restarts    ${pod_names}    ${APPLICATIONS_NAMESPACE}

Verify Switcher to Masterhead
    [Tags]    ODS-771
    ...       Smoke
    [Documentation]    Checks the link in switcher and also check the link of OCM in staging
    Open Application Switcher Menu
    Check Application Switcher Links To Openshift Console
    Run Keyword If RHODS Is Managed    Check Application Switcher Links To Openshift Cluster Manager


*** Keywords ***
Set Variables For Group Testing
    [Documentation]     Sets the suite variables used by the test cases for checking
    ...                 Dashboard logs about rhods groups
    Set Standard RHODS Groups Variables
    Set Suite Variable      ${EXP_ERROR_INEXISTENT_GRP}      Error: Failed to retrieve Group ${CUSTOM_INEXISTENT_GROUP}, might not exist.
    Set Suite Variable      ${EXP_ERROR_SYS_AUTH}      Error: It is not allowed to set system:authenticated or an empty string as admin group.
    Set Suite Variable      ${EXP_ERROR_MISSING_RGC}      Error: Failed to retrieve ConfigMap ${RHODS_GROUPS_CONFIG_CM}, might be malformed or doesn't exist.
    ${dash_pods_name}=   Get Dashboard Pods Names
    Set Suite Variable    ${DASHBOARD_PODS_NAMES}  ${dash_pods_name}

Restore Group ConfigMap And Check Logs Do Not Change
    [Documentation]    Creates the given configmap and checks the logs of Dashboard
    ...                pods do not show new lines
    [Arguments]   ${cm_yaml}
    ${clean_yaml}=    Clean Resource YAML Before Creating It    ${cm_yaml}
    Log    ${clean_yaml}
    OpenShiftLibrary.Oc Create    kind=ConfigMap    src=${clean_yaml}   namespace=${APPLICATIONS_NAMESPACE}
    ${lengths_dict}=    Get Lengths Of Dashboard Pods Logs
    Logs Of Dashboard Pods Should Not Contain New Lines  lengths_dict=${lengths_dict}

Restore Group ConfigMaps And Check Logs Do Not Change
    [Documentation]    Creates the given configmaps and checks the logs of Dashboard
    ...                pods do not show new lines after restoring each of the given CMs
    [Arguments]    ${cm_yamls}
    ${cm_dicts}=      Run Keyword And Continue On Failure    Get ConfigMaps For RHODS Groups Configuration
    FOR    ${key}    IN   @{cm_dicts.keys()}
        ${cm}=    Get From Dictionary    dictionary=${cm_dicts}    key=${key}
        ${null}=    Run Keyword And Return Status   Should Be Equal     ${cm}   ${EMPTY}
        IF   ${null} == ${TRUE}
            Restore Group ConfigMap And Check Logs Do Not Change    cm_yaml=${cm_yamls}[${key}]
        END
    END

Get Lengths Of Dashboard Pods Logs
    [Documentation]     Computes the number of lines present in the logs of both the dashboard pods
    ...                 and returns them as dictionary
    ${lengths_dict}=    Create Dictionary
    FOR    ${index}    ${pod_name}    IN ENUMERATE    @{DASHBOARD_PODS_NAMES}
        Log    ${pod_name}
        ${pod_logs_lines}   ${n_lines}=     Get Dashboard Pod Logs     pod_name=${pod_name}
        Set To Dictionary   ${lengths_dict}     ${pod_name}  ${n_lines}
    END
    RETURN    ${lengths_dict}

New Lines In Logs Of Dashboard Pods Should Contain
    [Documentation]     Verifies that newly generated lines in the logs contain the given message
    [Arguments]     ${exp_msg}      ${prev_logs_lengths}
    &{new_logs_lengths}=   Create Dictionary
    FOR    ${index}    ${pod_name}    IN ENUMERATE    @{DASHBOARD_PODS_NAMES}
        Log    ${pod_name}
        ${pod_log_lines_new}    ${n_lines_new}=   Wait Until New Log Lines Are Generated In A Dashboard Pod
        ...     prev_length=${prev_logs_lengths}[${pod_name}]  pod_name=${pod_name}
        Set To Dictionary   ${new_logs_lengths}     ${pod_name}    ${n_lines_new}
        Log     ${pod_log_lines_new}
        FOR    ${line_idx}    ${line}    IN ENUMERATE    @{pod_log_lines_new}
            Run Keyword And Continue On Failure     Should Contain   container=${line}
            ...     item=${exp_msg}
        END
    END
    RETURN    ${new_logs_lengths}

Wait Until New Log Lines Are Generated In A Dashboard Pod
    [Documentation]     Waits until new messages in the logs are generated
    [Arguments]     ${prev_length}  ${pod_name}  ${retries}=10    ${retries_interval}=3s
    FOR  ${retry_idx}  IN RANGE  0  1+${retries}
        ${pod_logs_lines}   ${n_lines}=     Get Dashboard Pod Logs     pod_name=${pod_name}
        Log     ${n_lines} vs ${prev_length}
        ${equal_flag}=     Run Keyword And Return Status    Should Be True     "${n_lines}" > "${prev_length}"
        Exit For Loop If    $equal_flag == True
        Sleep    ${retries_interval}
    END
    IF    $equal_flag == False
        Fail    Something got wrong. Check the logs
    END
    RETURN    ${pod_logs_lines}[${prev_length}:]     ${n_lines}

Logs Of Dashboard Pods Should Not Contain New Lines
    [Documentation]     Checks if no new lines are generated in the logs after that.
    [Arguments]     ${lengths_dict}
    FOR    ${index}    ${pod_name}    IN ENUMERATE    @{DASHBOARD_PODS_NAMES}
        ${new_lines_flag}=  Run Keyword And Return Status
        ...                 Wait Until New Log Lines Are Generated In A Dashboard Pod
        ...                 prev_length=${lengths_dict}[${pod_name}]  pod_name=${pod_name}
        Run Keyword And Continue On Failure     Should Be Equal     ${new_lines_flag}   ${FALSE}
    END

Set Default Groups And Check Logs Do Not Change
    [Documentation]    Teardown for ODS-1408 and ODS-1494. It sets the default configuration of "odh-dashboard-config"
    ...    ConfigMap and checks if no new lines are generated in the logs after that.
    [Arguments]    ${delete_group}=${FALSE}
    ${lengths_dict}=    Get Lengths Of Dashboard Pods Logs
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...    users_group=${STANDARD_SYSTEM_GROUP}
    Logs Of Dashboard Pods Should Not Contain New Lines  lengths_dict=${lengths_dict}
    IF  "${delete_group}" == "${TRUE}"
        Delete Group    group_name=${CUSTOM_EMPTY_GROUP}
    END

Favorite Items Should Be Listed First
    [Documentation]    Compares the ids and checks that favorite Items
    ...                are listed first
    [Arguments]    ${list_of_fav_items_id}    ${list_of_all_items_id}    ${range}
    ${new_list_of_tile} =    Get Slice From List    ${list_of_all_items_id}    0    ${range}
    Lists Should Be Equal    ${new_list_of_tile}    ${list_of_fav_items_id}    ignore_order=${True}

Verify Star Icons Are Clickable
    [Documentation]    Verifies that star icons in the resources page are clickable
    [Arguments]    ${list_of_ids}
    FOR    ${id}    IN    @{list_of_ids}
         Set Item As Favorite    ${id}
         Remove An Item From Favorite    ${id}
    END

Get List Of Ids Of Tiles
    [Documentation]    Returns the list of ids of tiles present in resources page
    ${list_of_ids}=    Get List Of Atrributes
    ...    xpath=//div[contains(@class, "odh-tourable-card")]    attribute=id
    RETURN    ${list_of_ids}

Set Item As Favorite
    [Documentation]    Add the tiles in favorite
    [Arguments]    ${id}
    ${card_star_button}=    Set Variable    //*[@id="${id}" and contains(@class, "odh-tourable-card")]//button
    ${not_clicked} =    Get Element Attribute    ${card_star_button}    aria-label
    Should Be Equal    ${not_clicked}    not starred
    Click Element    ${card_star_button}

Remove An Item From Favorite
    [Documentation]    Removes the tiles from favorite
    [Arguments]    ${id}
    ${card_star_button}=    Set Variable    //*[@id="${id}" and contains(@class, "odh-tourable-card")]//button
    ${clicked} =    Get Element Attribute    ${card_star_button}    aria-label
    Should Be Equal    ${clicked}    starred
    Click Element    ${card_star_button}

Add The Items In Favorites
    [Documentation]    Add the tiles in the favorites
    [Arguments]    @{list_of_ids}
    FOR    ${id}    IN     @{list_of_ids}
        Set Item As favorite    ${id}
    END

Favorite Items Should Be Listed First When Sorted By
    [Documentation]    Changes the sort type of tile and checks that favorites
    ...                favorite items are still listed first
    [Arguments]    ${list_of_ids_of_favorite}    ${sort_type}
    Sort Resources By    ${sort_type}
    ${new_list_of_tile} =    Get List Of Ids Of Tiles
    Favorite Items Should Be Listed First    ${list_of_ids_of_favorite}    ${new_list_of_tile}    ${5}

Get The List Of Ids of Tiles In List View
    [Documentation]    Returns the list of ids of tiles in list view
    ${list_of_new_tile_ids} =    Get List Of Atrributes    //div[@class="odh-list-item__doc-title"]    id
    ${len} =    Get Length    ${list_of_new_tile_ids}
    ${list_of_ids_in_list_view} =    Create List
    FOR    ${index}    IN RANGE    0    ${len}    2
        Append To List    ${list_of_ids_in_list_view}    ${list_of_new_tile_ids}[${index}]
    END
    RETURN    ${list_of_ids_in_list_view}

Remove Items From Favorites
    [Documentation]    Removes the items from favorites
    [Arguments]    @{list_of_ids}
    FOR    ${id}    IN     @{list_of_ids}
        Remove An Item From Favorite    ${id}
    END
    Close Browser

RHODS Dahsboard Pod Should Contain OauthProxy Container
    ${list_of_pods} =    Search Pod    namespace=${APPLICATIONS_NAMESPACE}    pod_regex=${DASHBOARD_APP_NAME}
    FOR    ${pod_name}    IN   @{list_of_pods}
        ${container_name} =    Get Containers    pod_name=${pod_name}    namespace=${APPLICATIONS_NAMESPACE}
        List Should Contain Value    ${container_name}    oauth-proxy
    END

Verify Jupyter Card CSS Style
    [Documentation]    Compare the some CSS properties of the Explore page with the expected ones
    # Verify that the color of the Jupyter code is gray
    CSS Property Value Should Be    locator=${EXPLORE_PANEL_XP}//code
    ...    property=background-color    exp_value=rgba(240, 240, 240, 1)
    CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}//p
    ...    property=margin-bottom    exp_value=8px
    CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}/h1
    ...    property=font-size    exp_value=24px
    CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}/h1
    ...    property=font-family    exp_value=RedHatText
    ...    operation=contains

Test Setup For Login Page
    Set Library Search Order    SeleniumLibrary
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}

Check OpenShift Login Visible
    ${result}=    Is OpenShift Login Visible
    IF    ${result}=='false'
        FAIL    OpenShift Login Is Not Visible
    END

Dashboard Test Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}

Dashboard Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Dashboard Test Teardown
    Close All Browsers

Set GPU Expected Resources
    [Documentation]    Sets the expected items in Resources section for GPUs.
    ...                Those changes based on RHODS installation type (i.e., Self-Managed vs Cloud Service)
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed} == ${TRUE}
        ${gpu_re_id}=    Create List  'python-gpu-numba-tutorial'
        ${gpu_re_link}=   Create List   'https://github.com/ContinuumIO/gtc2018-numba'
    ELSE
        ${gpu_re_id}=    Create List  'gpu-enabled-notebook-quickstart'   'python-gpu-numba-tutorial'
        ...    'gpu-quickstart'     'nvidia-doc'
        ${gpu_re_link}=   Create List   '#'  'https://github.com/ContinuumIO/gtc2018-numba'   '#'
        ...   'https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/openshift/contents.html'
    END
    ${gpu_re_exp}=    Get Length    ${gpu_re_id}
    RETURN    ${gpu_re_id}    ${gpu_re_link}    ${gpu_re_exp}

Check GPU Resources
    [Documentation]   Check resource tiles for GPU is present
    ${gpu_re_id}    ${gpu_re_link}    ${gpu_re_exp}=    Set GPU Expected Resources
    ${elements}=    Get WebElements    ${RES_CARDS_XP}
    ${len}=    Get Length    ${elements}
    Should Be Equal As Integers    ${len}    ${gpu_re_exp}
    FOR    ${counter}    IN RANGE    ${len}
        Page Should Contain Element    xpath:${RES_CARDS_XP}\[@id=${gpu_re_id}[${counter}]]
        IF    ${gpu_re_link}[${counter}] == '#'
                ${counter}=    Get WebElements   ${RES_CARDS_XP}//button[text()='Open']
                ${no_of_open_link}=    Get Length    ${counter}
                IF   ${no_of_open_link} == ${2}   Log   There are two tile with `Open' link
                ...        ELSE    Fail     Mismatch on the number of GPU tile present with 'Open' link.Please check the RHODS dashboard.  #robocop disable
        ELSE
                Page Should Contain Element    //a[@href=${gpu_re_link}[${counter}]]
        END
    END

Verify Anaconda Success Message Based On Version
    [Documentation]  Checks Anaconda success message based on version
    ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
    IF  ${version-check}==False
        Success Message Should Contain    ${ANACONDA_DISPLAYED_NAME}
    ELSE
        Success Message Should Contain    ${ANACONDA_DISPLAYED_NAME_LATEST}
    END

Verify RHODS Notification After Logging Out
    [Documentation]     Logs out from RHODS Dashboard and then relogin to check notifications
    Go To    ${ODH_DASHBOARD_URL}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    RHODS Notification Drawer Should Contain  message=Notebook image build TensorFlow failed

Restart Failed Build and Close Browser
    [Documentation]     Deletes failed build and starts new build , Closes All Browsers
    [Arguments]     ${failed_build_name}  ${build_config}
    Delete Failed Build And Start New One  namespace=${APPLICATIONS_NAMESPACE}  failed_build_name=${failed_build_name}  build_config_name=${build_config}
    Dashboard Test Teardown

Verify Notifications After Build Is Complete
    [Documentation]  Verifies Notifications after build status is complete
    RHODS Notification Drawer Should Contain  message=builds completed successfully
    RHODS Notification Drawer Should Contain  message=TensorFlow build image failed
    RHODS Notification Drawer Should Contain  message=Contact your administrator to retry failed images

Verify Notification Saying Notebook Builds Not Started
    [Documentation]     Verifies RHODS Notification Drawer Contains Names of Image Builds which have not started
    Sleep  2min  reason=Wait For Notifications
    Reload Page
    RHODS Notification Drawer Should Contain    message=These notebook image builds have not started:
    FOR    ${image}    IN    @{IMAGES}
        RHODS Notification Drawer Should Contain    message=${image}
    END

Wait Until Remaining Builds Are Complete And Close Browser
    [Documentation]     Waits Until Remaining builds have Status as Complete and Closes Browser
    Go To  url=${OCP_CONSOLE_URL}
    Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
    Rebuild Missing Or Failed Builds  builds=${BUILDS_TO_BE_CHECKED}  build_configs=${BUILD_CONFIGS}  namespace=${APPLICATIONS_NAMESPACE}
    Dashboard Test Teardown

Verify Operator Is Added On ODS Dashboard
    [Documentation]     It checks operator is present on ODS Dashboard in Enabled section
    [Arguments]         ${operator_name}
    Launch Dashboard   ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ...   ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Wait Until Keyword Succeeds    10x    1m    Verify Service Is Enabled  app_name=${operator_name}
    Close Browser

Uninstall Operator And Check Enabled Page Is Rendering
    [Documentation]    Uninstall Operator And Check Enabled Page(ODS) Is Rendering, Not shwoing "Error loading components"
    [Arguments]     ${operator_name}    ${operator_appname}
    Open Installed Operators Page
    Uninstall Operator    ${operator_name}
    Launch Dashboard   ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ...   ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Page Should Not Contain    Error loading components

Check And Uninstall Operator In Openshift
    [Documentation]     it checks operator is uninstalled if not then uninstall it
    [Arguments]       ${operator_name}    ${operator_appname}   ${dashboard_app_id}   ${expected_number_operator}=2
    ${status}       Check If Operator Is Already Installed In Opneshift    ${operator_name}
    IF  ${status}
        Open OperatorHub
        ${actual_no_of_operator}    Get The Number of Operator Available    ${operator_appname}
        IF  ${actual_no_of_operator} == ${expected_number_operator}
            Uninstall Operator    ${operator_name}
        ELSE
            FAIL      Only ${actual_no_of_operator} ${operator_name} is found in Operatorhub
        END
    END
    Close All Browsers
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=${dashboard_app_id}

Check Application Switcher Links To Openshift Cluster Manager
    [Documentation]    Checks for HTTP status of OCM link in application switcher
    Skip If RHODS Is Self-Managed
    ${cluster_id}=    Get Cluster ID
    ${cluster_name}=    Get Cluster Name By Cluster ID    ${cluster_id}
    ${cluster_env}=    Fetch ODS Cluster Environment
    IF    "${cluster_env}" == "stage"
        ${ocm_staging_link}=    Set Variable    https://console.dev.redhat.com/openshift/details/${cluster_id}
        Check HTTP Status Code    link_to_check=${ocm_staging_link}    verify_ssl=${False}
        Go To   ${ocm_staging_link}
    ELSE
        ${list_of_links}=    Get Links From Switcher
        ${ocm_prod_link}=    Set Variable    ${list_of_links}[1]
        Check HTTP Status Code    ${ocm_prod_link}
        Click Link    xpath://a[*[text()="OpenShift Cluster Manager"]]
        Switch Window   NEW
    END
    Sleep  1
    Login To OCM
    Reload Page
    Wait Until OCM Cluster Page Is Loaded    ${cluster_name}

Check Application Switcher Links To Openshift Console
    [Documentation]    Checks the HTTP status of OpenShift Console
    ${list_of_links}=    Get Links From Switcher
    ${status}=    Check HTTP Status Code    link_to_check=${list_of_links}[0]     verify_ssl=${False}
    Should Be Equal    ${list_of_links}[0]    ${OCP_CONSOLE_URL}/
    Should Be Equal    ${status}    ${200}

