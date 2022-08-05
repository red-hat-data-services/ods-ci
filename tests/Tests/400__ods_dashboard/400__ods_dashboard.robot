*** Settings ***
Library           OpenShiftCLI
Library           OpenShiftLibrary
Resource          ../../Resources/Page/OCPDashboard/OperatorHub/InstallODH.robot
Resource          ../../Resources/RHOSi.resource
Resource          ../../Resources/ODS.robot
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource          ../../Resources/Page/ODH/AiApps/Rhosak.resource
Resource          ../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource          ../../Resources/Page/LoginPage.robot
Resource          ../../Resources/Page/OCPLogin/OCPLogin.robot
Resource          ../../Resources/Common.robot
Resource          ../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource          ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Suite Setup       Dashboard Suite Setup
Suite Teardown    RHOSi Teardown
Test Setup        Dashboard Test Setup
Test Teardown     Dashboard Test Teardown


*** Variables ***
${RHOSAK_REAL_APPNAME}                  rhosak
${RHOSAK_DISPLAYED_APPNAME}             OpenShift Streams for Apache Kafka
@{LIST_OF_IDS_FOR_COMBINATIONS}         documentation--check-box    Red Hat managed--check-box
@{EXPECTED_ITEMS_FOR_ENABLE}            Create List                                                         Creating a Jupyter notebook
...                                     Deploying a sample Python application using Flask and OpenShift
...                                     How to install Python packages on your notebook server              How to update notebook server settings
...                                     How to use data from Amazon S3 buckets                              How to view installed packages on your notebook server
...                                     JupyterHub
@{EXPECTED_ITEMS_FOR_APPLICATION}       Create List                                                         by Anaconda Professional
@{EXPECTED_ITEMS_FOR_RESOURCE_TYPE}     Create List                                                         Tutorial
@{EXPECTED_ITEMS_FOR_PROVIDER_TYPE}     Create List                                                         Connecting to Red Hat OpenShift Streams for Apache Kafka
...                                     Creating a Jupyter notebook                                         Deploying a sample Python application using Flask and OpenShift
...                                     How to install Python packages on your notebook server              How to update notebook server settings
...                                     How to use data from Amazon S3 buckets                              How to view installed packages on your notebook server
...                                     JupyterHub                                                          OpenShift API Management    OpenShift Streams for Apache Kafka    PerceptiLabs
...                                     Securing a deployed model using Red Hat OpenShift API Management
@{EXPECTED_ITEMS_FOR_COMBINATIONS}      Create List                                                         JupyterHub    OpenShift API Management    OpenShift Streams for Apache Kafka
...                                     PerceptiLabs
@{IMAGES}                               PyTorch  TensorFlow  CUDA
@{BUILDS_TO_BE_DELETED}                 pytorch  tensorflow  minimal  cuda-s2i-thoth
@{BUILD_CONFIGS}                        11.4.2-cuda-s2i-base-ubi8    11.4.2-cuda-s2i-core-ubi8
...                                     11.4.2-cuda-s2i-py38-ubi8    11.4.2-cuda-s2i-thoth-ubi8-py38
...                                     s2i-minimal-gpu-cuda-11.4.2-notebook  s2i-pytorch-gpu-cuda-11.4.2-notebook
...                                     s2i-tensorflow-gpu-cuda-11.4.2-notebook
@{BUILDS_TO_BE_CHECKED}                 cuda-s2i-base    cuda-s2i-core    cuda-s2i-py    cuda-s2i-thoth
...                                     minimal    pytorch  tensorflow
${openvino_appname}           ovms
${openvino_container_name}    OpenVINO
${openvino_operator_name}     OpenVINO Toolkit Operator
${CUSTOM_EMPTY_GROUP}                   empty-group
${CUSTOM_INEXISTENT_GROUP}              inexistent-group


*** Test Cases ***
Verify That Login Page Is Shown When Reaching The RHODS Page
    [Tags]      Sanity
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
    ...       ProductBug
    ${EXP_DATA_DICT}=    Load Expected Data Of RHODS Explore Section
    Click Link    Explore
    Wait Until Cards Are Loaded
    Check Number Of Displayed Cards Is Correct    expected_data=${EXP_DATA_DICT}
    Check Cards Details Are Correct    expected_data=${EXP_DATA_DICT}

Verify Disabled Cards Can Be Removed
    [Documentation]     Verifies it is possible to remove a disabled card from Enabled page.
    ...                 It uses RHOSAK as example to test the feature
    [Tags]    Sanity
    ...       ODS-1081    ODS-1092
    ...       ProductBug
    Enable RHOSAK
    Remove RHOSAK From Dashboard
    Success Message Should Contain    ${RHOSAK_DISPLAYED_APPNAME}
    Verify Service Is Not Enabled    app_name=${RHOSAK_DISPLAYED_APPNAME}
    Capture Page Screenshot    after_removal.png

Verify License Of Disabled Cards Can Be Re-validated
    [Documentation]   Verifies it is possible to re-validate the license of a disabled card
    ...               from Enabled page. it uses Anaconda CE as example to test the feature.
    [Tags]    Sanity
    ...       ODS-1097   ODS-357
    ...       FlakyTest
    Enable Anaconda    license_key=${ANACONDA_CE.ACTIVATION_KEY}
    Menu.Navigate To Page    Applications    Enabled
    Wait Until RHODS Dashboard JupyterHub Is Visible
    Verify Anaconda Service Is Enabled Based On Version
    Close All Browsers
    Delete ConfigMap Using Name    redhat-ods-applications    anaconda-ce-validation-result
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
    [Tags]    Smoke
    ...       ODS-1165
    Click Link    Explore
    Wait Until Cards Are Loaded
    Open Get Started Sidebar And Return Status    card_locator=${JH_CARDS_XP}
    Capture Page Screenshot    get_started_sidebar.png
    Verify JupyterHub Card CSS Style

Verify Documentation Link HTTP Status Code
    [Documentation]    It verifies the documentation link present in question mark and
    ...    also checks the RHODS dcoumentation link present in resource page.
    [Tags]    Sanity
    ...       ODS-327    ODS-492
    ${links}=  Get RHODS Documentation Links From Dashboard
    Check External Links Status     links=${links}

Verify Logged In Users Are Displayed In The Dashboard
    [Documentation]    It verifies that logged in users username is displayed on RHODS Dashboard.
    [Tags]    Sanity
    ...       ODS-354
    ...       Tier1
    Verify Username Displayed On RHODS Dashboard   ${TEST_USER.USERNAME}

Search and Verify GPU Items Appears In Resources Page
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1226
    Search Items In Resources Section    GPU
    Check GPU Resources

Verify Filters Are Working On Resources Page
    [Documentation]    check if it is possible to filter items by enabling various filters like status,provider
    [Tags]    Sanity
    ...       ODS-489
    ...       Tier1
    Click Link    Resources
    Wait Until Resource Page Is Loaded
    Filter Resources By Status "Enabled" And Check Output
    Filter By Resource Type And Check Output
    Filter By Provider Type And Check Output
    Filter By Application (Aka Povider) And Check Output
    Filter By Using More Than One Filter And Check Output

Verify "Notebook Images Are Building" Is Not Shown When No Images Are Building
    [Documentation]     Verifies that RHODS Notification Drawer doesn't contain "Notebook Images are building", if no build is running
    [Tags]    Sanity
    ...       ODS-307
    ...       Tier1
    Wait Until All Builds Are Complete  namespace=redhat-ods-applications
    RHODS Notification Drawer Should Not Contain  message=Notebooks images are building

Verify Notifications Appears When Notebook Builds Finish And Atleast One Failed
    [Documentation]    Verifies that Notifications are shown when Notebook Builds are finished and atleast one fails
    [Tags]    Tier2
    ...       ODS-470  ODS-718
    ...       Execution-Time-Over-30m
    ...       FlakyTest
    Clear Dashboard Notifications
    ${build_name}=  Search Last Build  namespace=redhat-ods-applications    build_name_includes=pytorch
    Delete Build    namespace=redhat-ods-applications    build_name=${build_name}
    ${new_buildname}=  Start New Build    namespace=redhat-ods-applications    buildconfig=s2i-pytorch-gpu-cuda-11.4.2-notebook
    Wait Until Build Status Is    namespace=redhat-ods-applications    build_name=${new_buildname}   expected_status=Running
    ${failed_build_name}=  Provoke Image Build Failure    namespace=redhat-ods-applications
    ...    build_name_includes=tensorflow    build_config_name=s2i-tensorflow-gpu-cuda-11.4.2-notebook
    ...    container_to_kill=sti-build
    Wait Until Build Status Is    namespace=redhat-ods-applications    build_name=${newbuild_name}     expected_status=Complete
    Verify Notifications After Build Is Complete
    Verify RHODS Notification After Logging Out
    [Teardown]     Restart Failed Build And Close Browser  failed_build_name=${failed_build_name}  build_config=s2i-tensorflow-gpu-cuda-11.4.2-notebook

Verify Favorite Resource Cards
    [Tags]    ODS-389    ODS-384
    ...       Tier1
    [Documentation]    Verifies the item in Resource page can be marked se favorite.
    ...                It checks if favorite items are always listed as first regardless
    ...                the view type or sorting
    Click Link    Resources
    Wait Until Element Is Visible    //div[@class="pf-l-gallery pf-m-gutter odh-learning-paths__gallery"]
    Sort Resources By    name
    ${list_of_tile_ids} =    Get List Of Ids Of Tiles
    Verify Star Icons Are Clickable    ${list_of_tile_ids}

    ${favorite_ids} =    Get Slice From List    ${list_of_tile_ids}    ${27}    ${48}
    Add The Items In Favorites    @{favorite_ids}

    ${list_of_tile_ids} =    Get List Of Ids Of Tiles
    Favorite Items Should Be Listed First    ${favorite_ids}    ${list_of_tile_ids}    ${21}

    Click Button    //*[@id="list-view"]
    Sleep    0.5s
    ${list_view_tiles} =    Get The List Of Ids of Tiles In List View
    Favorite Items Should Be Listed First    ${favorite_ids}    ${list_view_tiles}    ${21}

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
    Delete Multiple Builds  @{BUILDS_TO_BE_DELETED}  namespace=redhat-ods-applications
    ${last_cuda_build}=  Start New Build    namespace=redhat-ods-applications    buildconfig=11.4.2-cuda-s2i-thoth-ubi8-py38
    Verify Notification Saying Notebook Builds Not Started
    Clear Dashboard Notifications
    Wait Until Build Status Is    namespace=redhat-ods-applications    build_name=${last_cuda_build}  expected_status=Complete
    Remove Values From List    ${IMAGES}  CUDA
    Verify Notification Saying Notebook Builds Not Started
    RHODS Notification Drawer Should Contain    message=Notebook images are building
    RHODS Notification Drawer Should Not Contain    message=CUDA
    [Teardown]   Wait Until Remaining Builds Are Complete And Close Browser

Verify "Enabled" Keeps Being Available After One Of The ISV Operators If Uninstalled
   [Documentation]     Verify "Enabled" keeps being available after one of the ISV operators if uninstalled
   [Tags]      Sanity
   ...         ODS-1491
   ...         Tier1
   ...         ProductBug
   Check And Install Operator in Openshift    ${openvino_operator_name}   ${openvino_appname}
   Close All Browsers
   Verify Operator Is Added On ODS Dashboard  operator_name=${openvino_container_name}
   Uninstall Operator And Check Enabled Page Is Rendering  operator_name=${openvino_operator_name}  operator_appname=${openvino_appname}
   [Teardown]    Check And Uninstall Operator In Openshift    ${openvino_operator_name}   ${openvino_appname}

Verify Error Message In Logs When A RHODS Group Is Empty
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1408
    [Documentation]     Verifies the messages printed out in the logs of
    ...                 dashboard pods are the ones expected when an empty group
    ...                 is set as admin in "rhods-group-config" ConfigMap
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
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1494
    [Documentation]     Verifies the messages printed out in the logs of
    ...                 dashboard pods are the ones expected when an inexistent group
    ...                 is set as admin in "rhods-group-config" ConfigMap
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
    ...                 is set as admin in "rhods-group-config" ConfigMap
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1500
    [Setup]     Set Variables For Group Testing
    ${lengths_dict_before}=     Get Lengths Of Dashboard Pods Logs
    Set RHODS Admins Group To system:authenticated
    ${lengths_dict_after}=    New Lines In Logs Of Dashboard Pods Should Contain
    ...     exp_msg=${EXP_ERROR_SYS_AUTH}
    ...     prev_logs_lengths=${lengths_dict_before}
    [Teardown]      Set Default Groups And Check Logs Do Not Change

Verify Error Message In Logs When rhods-groups-config ConfigMap Does Not Exist
    [Documentation]     Verifies the messages printed out in the logs of
    ...                 dashboard pods are the ones expected when "rhods-groups-config"
    ...                 ConfigMap does not exist
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1495
    [Setup]     Set Variables For Group Testing
    ${groups_configmaps_dict}=     Get ConfigMaps For RHODS Groups Configuration
    ${lengths_dict_before}=     Get Lengths Of Dashboard Pods Logs
    Delete RHODS Config Map     name=${RHODS_GROUPS_CONFIG_CM}
    ${lengths_dict_after}=      New Lines In Logs Of Dashboard Pods Should Contain
    ...     exp_msg=${EXP_ERROR_MISSING_RGC}
    ...     prev_logs_lengths=${lengths_dict_before}
    [Teardown]      Restore Group ConfigMaps And Check Logs Do Not Change     cm_yamls=${groups_configmaps_dict}

Verify Dashboard Pod Is Not Getting Restarted
    [Documentation]    Verify Dashboard Pod container doesn't restarted
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-374
    ${pod_names}    Get POD Names    redhat-ods-applications    app=rhods-dashboard
    Verify Containers Have Zero Restarts    ${pod_names}    redhat-ods-applications


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
    OpenShiftLibrary.Oc Create    kind=ConfigMap    src=${clean_yaml}   namespace=redhat-ods-applications
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
    [Return]    ${lengths_dict}

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
    [Return]    ${new_logs_lengths}

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
    [Return]    ${pod_logs_lines}[${prev_length}:]     ${n_lines}

Set RHODS Admins Group Empty Group
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given empty group (i.e., with no users)
    Set Access Groups Settings    admins_group=${CUSTOM_EMPTY_GROUP}
    ...     users_group=${STANDARD_USERS_GROUP}   groups_modified_flag=true

Set RHODS Admins Group To system:authenticated    # robocop:disable
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given empty group (i.e., with no users)
    Set Access Groups Settings    admins_group=system:authenticated
    ...     users_group=${STANDARD_USERS_GROUP}   groups_modified_flag=true

Set RHODS Users Group Empty Group
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given empty group (i.e., with no users)
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...     users_group=${CUSTOM_EMPTY_GROUP}   groups_modified_flag=true

Set RHODS Admins Group To Inexistent Group
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given inexistent group
    Set Access Groups Settings    admins_group=${CUSTOM_INEXISTENT_GROUP}
    ...     users_group=${STANDARD_USERS_GROUP}   groups_modified_flag=true

Set RHODS Users Group To Inexistent Group
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given inexistent group
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...     users_group=${CUSTOM_INEXISTENT_GROUP}   groups_modified_flag=true

Set Default Groups And Check Logs Do Not Change
    [Documentation]     Teardown for ODS-1408 and ODS-1494. It sets the default configuration of "rhods-groups-config"
    ...                 ConfigMap and checks if no new lines are generated in the logs after that.
    [Arguments]     ${delete_group}=${FALSE}
    ${lengths_dict}=    Get Lengths Of Dashboard Pods Logs
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...     users_group=${STANDARD_USERS_GROUP}   groups_modified_flag=true
    Logs Of Dashboard Pods Should Not Contain New Lines  lengths_dict=${lengths_dict}
    IF  "${delete_group}" == "${TRUE}"
        Delete Group    group_name=${CUSTOM_EMPTY_GROUP}
    END

Logs Of Dashboard Pods Should Not Contain New Lines
    [Documentation]     Checks if no new lines are generated in the logs after that.
    [Arguments]     ${lengths_dict}
    FOR    ${index}    ${pod_name}    IN ENUMERATE    @{DASHBOARD_PODS_NAMES}
        ${new_lines_flag}=  Run Keyword And Return Status
        ...                 Wait Until New Log Lines Are Generated In A Dashboard Pod
        ...                 prev_length=${lengths_dict}[${pod_name}]  pod_name=${pod_name}
        Run Keyword And Continue On Failure     Should Be Equal     ${new_lines_flag}   ${FALSE}
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
    ...    xpath=//article[@class="pf-c-card pf-m-selectable odh-card odh-tourable-card"]    attribute=id
    [Return]    ${list_of_ids}

Set Item As Favorite
    [Documentation]    Add the tiles in favorite
    [Arguments]    ${id}
    ${not_clicked} =    Get Element Attribute    //*[@id="${id}"]/div[1]/span    class
    Should Be Equal    ${not_clicked}    odh-dashboard__favorite
    Click Element    //*[@id="${id}"]/div[1]/span

Remove An Item From Favorite
    [Documentation]    Removes the tiles from favorite
    [Arguments]    ${id}
    ${clicked} =    Get Element Attribute    //*[@id="${id}"]/div[1]/span    class
    Should Be Equal    ${clicked}    odh-dashboard__favorite m-is-favorite
    Click Element    //*[@id="${id}"]/div[1]/span

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
    Favorite Items Should Be Listed First    ${list_of_ids_of_favorite}    ${new_list_of_tile}    ${21}

Get The List Of Ids of Tiles In List View
    [Documentation]    Returns the list of ids of tiles in list view
    ${list_of_new_tile_ids} =    Get List Of Atrributes    //div[@class="odh-list-item__doc-title"]    id
    ${len} =    Get Length    ${list_of_new_tile_ids}
    ${list_of_ids_in_list_view} =    Create List
    FOR    ${index}    IN RANGE    0    ${len}    2
        Append To List    ${list_of_ids_in_list_view}    ${list_of_new_tile_ids}[${index}]
    END
    [Return]    ${list_of_ids_in_list_view}

Remove Items From Favorites
    [Documentation]    Removes the items from favorites
    [Arguments]    @{list_of_ids}
    FOR    ${id}    IN     @{list_of_ids}
        Remove An Item From Favorite    ${id}
    END
    Close Browser

RHODS Dahsboard Pod Should Contain OauthProxy Container
    ${list_of_pods} =    Search Pod    namespace=redhat-ods-applications    pod_start_with=rhods-dashboard
    FOR    ${pod_name}    IN   @{list_of_pods}
        ${container_name} =    Get Containers    pod_name=${pod_name}    namespace=redhat-ods-applications
        List Should Contain Value    ${container_name}    oauth-proxy
    END

Verify JupyterHub Card CSS Style
    [Documentation]    Compare the some CSS properties of the Explore page
    ...    with the expected ones. The expected values change based
    ...    on the RHODS version
    CSS Property Value Should Be    locator=//pre
    ...    property=background-color    exp_value=rgba(240, 240, 240, 1)
    CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}//p
    ...    property=margin-bottom    exp_value=8px
    CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}/h1
    ...    property=font-size    exp_value=24px
    CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}/h1
    ...    property=font-family    exp_value=RedHatDisplay
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

Check GPU Resources
    [Documentation]   Check resource tiles for GPU is present
    ${version_check}=    Is RHODS Version Greater Or Equal Than    1.13.0
    ${elements}=    Get WebElements    //article
    @{gpu_re_id}=    Create List  'gpu-enabled-notebook-quickstart'   'python-gpu-numba-tutorial'
    ...    'gpu-quickstart'     'nvidia-doc'
    @{gpu_re_link}=   Create List   '#'  'https://github.com/ContinuumIO/gtc2018-numba'   '#'
    ...   'https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/openshift/contents.html'
    ${len}=    Get Length    ${elements}
    IF    ${version_check}==True
        Should Be Equal As Integers    ${len}    4
        FOR    ${counter}    IN RANGE    ${len}
           Page Should Contain Element    //article[@id=${gpu_re_id}[${counter}]]
           IF    ${gpu_re_link}[${counter}] == '#'
                 ${counter}=    Get WebElements   //a[@href=${gpu_re_link}[${counter}]]
                 ${no_of_open_link}=    Get Length    ${counter}
                 Run Keyword IF   ${no_of_open_link} == ${2}   Log   There are two tile with `Open' link
                 ...        ELSE    Fail     Mismatch on the number of GPU tile present with 'Open' link.Please check the RHODS dashboard.  #robocop disable
           ELSE
                 Page Should Contain Element    //a[@href=${gpu_re_link}[${counter}]]
           END
        END
    ELSE
        Should Be Equal As Integers    ${len}    1
        Page Should Contain Element    //article[@id=${gpu_re_id}[1]]
        Page Should Contain Element    //a[@href=${gpu_re_link}[1]]
    END

Select Checkbox Using Id
    [Documentation]    Select check-box
    [Arguments]    ${id}
    Select Checkbox    id=${id}
    sleep    1s

Deselect Checkbox Using Id
    [Documentation]    Deselect check-box
    [Arguments]    ${id}
    Unselect Checkbox    id=${id}
    sleep    1s

Verify The Resources Are Filtered
    [Documentation]    verified the items, ${index_of_text} is index text appear on resource 0 = title,1=provider,2=tag(like documentation,tutorial)
    [Arguments]    ${selector}    ${list_of_items}    ${index_of_text}=0
    @{items}=    Get WebElements    //div[@class="${selector}"]
    FOR    ${item}    IN    @{items}
        @{texts}=    Split String    ${item.text}    \n
        List Should Contain Value    ${list_of_items}    ${texts}[${index_of_text}]
    END

Filter Resources By Status "Enabled" And Check Output
    [Documentation]    Filters the resources By Status Enabled
    Select Checkbox Using Id    enabled-filter-checkbox--check-box
    Verify The Resources Are Filtered    selector=pf-c-card__title odh-card__doc-title
    ...    list_of_items=${EXPECTED_ITEMS_FOR_ENABLE}
    Deselect Checkbox Using Id    enabled-filter-checkbox--check-box

Filter By Application (Aka Povider) And Check Output
    [Documentation]    Filter by application (aka provider)
    ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
    IF  ${version-check}==False
        ${id_name} =  Set Variable    Anaconda Commercial Edition--check-box
    ELSE
        ${id_name} =  Set Variable    Anaconda Professional--check-box
    END
    Select Checkbox Using Id    ${id_name}
    Verify The Resources Are Filtered    selector=pf-c-card__title odh-card__doc-title
    ...    list_of_items=${EXPECTED_ITEMS_FOR_APPLICATION}    index_of_text=1
    Deselect Checkbox Using Id    id=${id_name}

Filter By Resource Type And Check Output
    [Documentation]    Filter by resource type
    Select Checkbox Using Id    id=tutorial--check-box
    Verify The Resources Are Filtered    selector=pf-c-card__title odh-card__doc-title
    ...    list_of_items=${EXPECTED_ITEMS_FOR_RESOURCE_TYPE}    index_of_text=2
    Deselect Checkbox Using Id    id=tutorial--check-box

Filter By Provider Type And Check Output
    [Documentation]    Filter by provider type
    Select Checkbox Using Id    id=Red Hat managed--check-box
    Verify The Resources Are Filtered    selector=pf-c-card__title odh-card__doc-title
    ...    list_of_items=${EXPECTED_ITEMS_FOR_PROVIDER_TYPE}
    Deselect Checkbox Using Id    id=Red Hat managed--check-box

Filter By Using More Than One Filter And Check Output
    [Documentation]    Filter resouces using more than one filter ${list_of_ids} = list of check-box ids
    FOR    ${id}    IN    @{LIST_OF_IDS_FOR_COMBINATIONS}
        Select Checkbox Using Id    id=${id}
    END
    Verify The Resources Are Filtered    selector=pf-c-card__title odh-card__doc-title
    ...    list_of_items=${EXPECTED_ITEMS_FOR_COMBINATIONS}
    FOR    ${id}    IN    @{LIST_OF_IDS_FOR_COMBINATIONS}
        Deselect Checkbox Using Id    id=${id}
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
    Delete Failed Build And Start New One  namespace=redhat-ods-applications  failed_build_name=${failed_build_name}  build_config_name=${build_config}
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
    Rebuild Missing Or Failed Builds  builds=${BUILDS_TO_BE_CHECKED}  build_configs=${BUILD_CONFIGS}  namespace=redhat-ods-applications
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
    [Arguments]       ${operator_name}    ${operator_appname}   ${expected_number_operator}=2
    ${status}       Check If Operator Is Already Installed In Opneshift    ${operator_name}
    IF  ${status}
        Open OperatorHub
        ${actual_no_of_operator}    Get The Number of Operator Available    ${operator_appname}
        IF  ${actual_no_of_operator} == ${expected_number_operator}
            Uninstall Operator    ${operator_name}
        ELSE
            FAIL      Only ${actual_no_of_operator} ${operator_name} is found in Opearatorhub

        END
    END
    Close All Browsers
