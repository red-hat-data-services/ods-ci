*** Settings ***
Library         OpenShiftCLI
Resource        ../../Resources/Page/OCPDashboard/OperatorHub/InstallODH.robot
Resource        ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../Resources/Page/ODH/AiApps/Rhosak.resource
Resource        ../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource        ../../Resources/Page/LoginPage.robot
Resource        ../../Resources/Page/OCPLogin/OCPLogin.robot
Test Setup      Dashboard Test Setup
Test Teardown   Dashboard Test Teardown


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


*** Test Cases ***
Verify That Login Page Is Shown When Reaching The RHODS Page
    [Tags]    Sanity    ODS-694
    [Setup]    Test Setup For Login Page
    Check OpenShift Login Visible

Verify Resource Link HTTP Status Code
    [Tags]    Sanity
    ...       ODS-531    ODS-507
    Click Link    Resources
    Sleep    5
    ${link_elements}=    Get WebElements    //a[@class="odh-card__footer__link" and not(starts-with(@href, '#'))]
    ${len}=    Get Length    ${link_elements}
    Log To Console    ${len} Links found\n
    FOR    ${idx}    ${ext_link}    IN ENUMERATE    @{link_elements}    start=1
        ${href}=    Get Element Attribute    ${ext_link}    href
        ${status}=    Check HTTP Status Code    link_to_check=${href}
        Log To Console    ${idx}. ${href} gets status code ${status}
    END

Verify Content In RHODS Explore Section
    [Documentation]    It verifies if the content present in Explore section of RHODS corresponds to expected one.
    ...    It compares the actual data with the one registered in a JSON file. The checks are about:
    ...    - Card's details (text, badges, images)
    ...    - Sidebar (titles, links text, links status)
    [Tags]    Sanity
    ...       ODS-488    ODS-993    ODS-749    ODS-352    ODS-282
    ...       KnownIssues
    ${EXP_DATA_DICT}=    Load Expected Data Of RHODS Explore Section
    Click Link    Explore
    Wait Until Cards Are Loaded
    Check Number Of Displayed Cards Is Correct    expected_data=${EXP_DATA_DICT}
    Check Cards Details Are Correct    expected_data=${EXP_DATA_DICT}

Verify Disabled Cards Can Be Removed
    [Documentation]    Verifies it is possible to remove a disabled card from Enabled page.
    ...    It uses RHOSAK as example to test the feature
    [Tags]    Sanity
    ...       ODS-1081    ODS-1092
    ...       KnownIssues
    Enable RHOSAK
    Remove RHOSAK From Dashboard
    Success Message Should Contain    ${RHOSAK_DISPLAYED_APPNAME}
    Verify Service Is Not Enabled    app_name=${RHOSAK_DISPLAYED_APPNAME}
    Capture Page Screenshot    after_removal.png

Verify License Of Disabled Cards Can Be Re-validated
    [Documentation]    Verifies it is possible to re-validate the license of a disabled card
    ...    from Enabled page. it uses Anaconda CE as example to test the feature.
    [Tags]    Sanity
    ...       ODS-1097    ODS-357
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
<<<<<<< HEAD
    [Teardown]    Remove Anaconda Professional Component
=======
    [Teardown]    Remove Anaconda Component
>>>>>>> 33de412 (Merge branch 'name_change' of github.com:risusing/ods-ci into name_change)

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
    ${links}=    Get RHODS Documentation Links From Dashboard
    Check External Links Status    links=${links}

Verify Logged In Users Are Displayed In The Dashboard
    [Documentation]    It verifies that logged in users username is displayed on RHODS Dashboard.
    [Tags]    Sanity
    ...       ODS-354
    ...       Tier1
    Verify Username Displayed On RHODS Dashboard    ${TEST_USER.USERNAME}

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


*** Keywords ***
Verify JupyterHub Card CSS Style
    [Documentation]    Compare the some CSS properties of the Explore page
    ...    with the expected ones. The expected values change based
    ...    on the RHODS version
    ${version-check}=    Is RHODS Version Greater Or Equal Than    1.7.0
    IF    ${version-check}==True
        CSS Property Value Should Be    locator=//pre
        ...    property=background-color    exp_value=rgba(240, 240, 240, 1)
        CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}//p
        ...    property=margin-bottom    exp_value=8px
    ELSE
        CSS Property Value Should Be    locator=//pre
        ...    property=background-color    exp_value=rgba(245, 245, 245, 1)
        CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}//p
        ...    property=margin-bottom    exp_value=10px
    END
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
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}

Dashboard Test Teardown
    Close All Browsers

Check GPU Resources
    ${version-check}=    Is RHODS Version Greater Or Equal Than    1.9.0
    IF    ${version-check}==True
        ${elements}=    Get WebElements    //article
        ${len}=    Get Length    ${elements}
        Should Be Equal As Integers    ${len}    1
        Page Should Contain Element    //article[@id="python-gpu-numba-tutorial"]
        Page Should Contain Element    //a[@href="https://github.com/ContinuumIO/gtc2018-numba"]
    ELSE
        ${elements}=    Get WebElements    //article
        ${len}=    Get Length    ${elements}
        Should Be Equal As Integers    ${len}    0
        Page Should Not Contain Element    //article[@id="python-gpu-numba-tutorial"]
        Page Should Not Contain Element    //a[@href="https://github.com/ContinuumIO/gtc2018-numba"]
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

Wait Until Resource Page Is Loaded
    Wait Until Page Contains Element    xpath://div[contains(@class,'odh-learning-paths__gallery')]

Filter Resources By Status "Enabled" And Check Output
    [Documentation]    Filters the resources By Status Enabled
    Select Checkbox Using Id    enabled-filter-checkbox--check-box
    Verify The Resources Are Filtered    selector=pf-c-card__title odh-card__doc-title
    ...    list_of_items=${EXPECTED_ITEMS_FOR_ENABLE}
    Deselect Checkbox Using Id    enabled-filter-checkbox--check-box

Filter By Application (Aka Povider) And Check Output
    [Documentation]    Filter by application (aka provider)
    Select Checkbox Using Id    Anaconda Professional--check-box
    Verify The Resources Are Filtered    selector=pf-c-card__title odh-card__doc-title
    ...    list_of_items=${EXPECTED_ITEMS_FOR_APPLICATION}    index_of_text=1
    Deselect Checkbox Using Id    id=Anaconda Professional--check-box

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
    [Documentaion]  Checks Anaconda success message based on version
    ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
    IF  ${version-check}==False
        Success Message Should Contain    ${ANACONDA_DISPLAYED_NAME}
    ELSE
        Success Message Should Contain    ${ANACONDA_DISPLAYED_NAME_LATEST}
    END
