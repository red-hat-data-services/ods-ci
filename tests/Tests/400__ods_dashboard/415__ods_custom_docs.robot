*** Settings ***
Library         OpenShiftLibrary
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../Resources/Page/LoginPage.robot
Resource        ../../Resources/Page/OCPLogin/OCPLogin.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ResourcesPage.resource
Suite Teardown   Resources Page Suite Teardown


*** Variables ***
${QS_YAML}=    tests/Resources/Files/custom_quickstart.yaml
@{EXPECTED_ITEMS_TITLES}=    TEST -  Custom Quick Start


*** Test Cases ***
Install Custom QuickStart
    [Documentation]     Tests if it is possible to create custom quick start resources
    [Tags]  Sanity    Tier1
    ...     ODS-697
    [Setup]     Resources Page Test Setup
    Create Custom QuickStart
    Resource Page Should Contain      filter=QuickStart    search_term=${EXPECTED_ITEMS_TITLES}[0]
    ...                               expected_items=${EXPECTED_ITEMS_TITLES}
    [Teardown]     Delete Custom Quick Start


*** Keywords ***
Resources Page Test Setup
    [Documentation]     Open RHODS Dashboard page and move to Resources page
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard   ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...                ocp_user_auth_type=${TEST_USER.AUTH_TYPE}   dashboard_url=${ODH_DASHBOARD_URL}
    ...                browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    Click Link      Resources

Resources Page Suite Teardown
    Close All Browsers

Create Custom QuickStart
    [Documentation]     Creates a CRD instance of RhodsQuickStarts using a custom yaml
    Oc Apply    kind=RhodsQuickStart    src=${QS_YAML}     namespace=redhat-ods-applications
    Oc Get      kind=RhodsQuickStart    label_selector=app=ods-ci  namespace=redhat-ods-applications

Delete Custom Quick Start
    [Documentation]     Deletes the previously created CRD instance
    Oc Delete   kind=RhodsQuickStart    label_selector=app=ods-ci  namespace=redhat-ods-applications


