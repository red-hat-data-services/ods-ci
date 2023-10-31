*** Settings ***
Documentation    Testing custom image imports (Adding ImageStream to ${APPLICATIONS_NAMESPACE})
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Resource         ../../Resources/RHOSi.resource
Library          JupyterLibrary
Library          OpenShiftLibrary
Suite Setup      Custom Notebook Settings Suite Setup
Suite Teardown   End Web Test
Force Tags       JupyterHub



*** Variables ***
${YAML} =         tests/Resources/Files/custom_image.yaml
${IMG_NAME} =            custom-test-image
${IMG_URL} =             quay.io/opendatahub-contrib/workbench-images:jupyter-datascience-c9s-py311_2023c_latest
${IMG_DESCRIPTION} =     Testing Only This image is only for illustration purposes, and comes with no support. Do not use.
&{IMG_SOFTWARE} =        Software1=x.y.z
&{IMG_PACKAGES} =        elyra=2.2.4    foo-pkg=a.b.c
# Place holder for the imagestream name of BYON notebook created for this test run
${IMAGESTREAM_NAME}=


*** Test Cases ***
Verify Admin User Can Access Custom Notebook Settings
    [Documentation]    Verifies an admin user can reach the custom notebook
    ...    settings page.
    [Tags]    Sanity    Tier1
    ...       ODS-1366
    Pass Execution    Passing tests, as suite setup ensures page can be reached

Verify Custom Image Can Be Added
    [Documentation]    Imports the custom image via UI
    ...                Then loads the spawner and tries using the custom img
    [Tags]    Sanity    Tier1    ExcludeOnDisconnected
    ...       ODS-1208    ODS-1365
    Create Custom Image
    Sleep    5s    #wait a bit from IS to be created
    Get ImageStream Metadata And Check Name
    Verify Custom Image Is Listed  ${IMG_NAME}
    Verify Custom Image Description  ${IMG_NAME}  ${IMG_DESCRIPTION}
    Verify Custom Image Owner  ${IMG_NAME}  ${TEST_USER.USERNAME}
    Launch JupyterHub Spawner From Dashboard

    # These keywords need to be reworked to function here
    #${spawner_description}=  Fetch Image Tooltip Description  ${IMAGESTREAM_NAME}
    #${spawner_packages}=  Fetch Image Tooltip Info  ${IMAGESTREAM_NAME}
    #${spawner_software}=  Fetch Image Description Info  ${IMAGESTREAM_NAME}
    #Should Match  ${spawner_description}  ${IMG_DESCRIPTION}
    #Should Match  ${spawner_software}  ${IMG_SOFTWARE}
    #Should Match  ${spawner_packages}  ${IMG_PACKAGES}

    Spawn Notebook With Arguments  image=${IMAGESTREAM_NAME}  size=Small
    [Teardown]  Custom Image Teardown

Test Duplicate Image
    [Documentation]  Test adding two images with the same name (should fail)
    [Tags]    Sanity    Tier1    ExcludeOnDisconnected
    ...       ODS-1368
    Sleep  1
    Create Custom Image
    Sleep  1
    Import New Custom Image    ${IMG_URL}    ${IMG_NAME}    ${IMG_DESCRIPTION}
    ...    software=${IMG_SOFTWARE}
    ...    packages=${IMG_PACKAGES}
    Run Keyword And Warn On Failure  RHODS Notification Drawer Should Contain
    ...  Unable to add notebook image ${IMG_NAME}
    Sleep  1
    Delete Custom Image  ${IMG_NAME}
    # If both imgs can be created they also have to be deleted twice
    Sleep  2
    Run Keyword And Continue On Failure    Delete Custom Image  ${IMG_NAME}
    Reset Image Name

Test Bad Image URL
    [Documentation]  Test adding an image with a bad repo URL (should fail)
    [Tags]    Sanity    Tier1
    ...       ODS-1367
    ${OG_URL}=  Set Variable  ${IMG_URL}
    ${IMG_URL}=  Set Variable  quay.io/RandomName/RandomImage:v1.2.3
    Set Global Variable  ${IMG_URL}  ${IMG_URL}
    Create Custom Image
    RHODS Notification Drawer Should Contain  Unable to add notebook image ${IMG_NAME}
    ${IMG_URL}=  Set Variable  ${OG_URL}
    Set Global Variable  ${IMG_URL}  ${IMG_URL}
    Reset Image Name

Test Bad Image Import
    [Documentation]  Import a broken image and confirm it is disabled
    ...    in the JH spawner page
    [Tags]    Sanity    Tier1
    ...       ODS-1364
    ${OG_URL}=  Set Variable  ${IMG_URL}
    ${IMG_URL}=  Set Variable  randomstring
    Set Global Variable  ${IMG_URL}  ${IMG_URL}
    Create Custom Image
    RHODS Notification Drawer Should Contain
    ...  Unable to add notebook image ${IMG_NAME}

Test Image From Local registry
    [Documentation]  Try creating a custom image using a local registry URL (i.e. OOTB image)
    [Tags]    Sanity    Tier1
    ...       ODS-2470
    Open Notebook Images Page
    ${local_url} =    Get Standard Data Science Local Registry URL
    ${IMG_URL}=    Set Variable    ${local_url}
    Set Suite Variable    ${IMG_URL}    ${IMG_URL}
    Create Custom Image
    Get ImageStream Metadata And Check Name
    Verify Custom Image Is Listed    ${IMG_NAME}
    Verify Custom Image Owner  ${IMG_NAME}  ${TEST_USER.USERNAME}
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${IMAGESTREAM_NAME}  size=Small
    [Teardown]  Custom Image Teardown


*** Keywords ***

Custom Notebook Settings Suite Setup
    [Documentation]    Navigates to the Custom Notebook Settings page
    ...    in the RHODS dashboard.
    RHOSi Setup
    Set Library Search Order  SeleniumLibrary
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Sleep  2
    Open Notebook Images Page

Custom Image Teardown
    [Documentation]    Closes the JL server and deletes the ImageStream
    [Arguments]    ${cleanup}=True
    IF  ${cleanup}==True
        Server Cleanup
    END
    Go To  ${ODH_DASHBOARD_URL}
    Open Notebook Images Page
    Sleep  1
    Delete Custom Image  ${IMG_NAME}
    Reset Image Name

Server Cleanup
    [Documentation]  helper keyword to clean up JL server
    Clean Up Server
    Stop JupyterLab Notebook Server

Create Custom Image
    [Documentation]    Imports a custom ImageStream via UI
    ${curr_date} =  Get Time  year month day hour min sec
    ${curr_date} =  Catenate  SEPARATOR=  @{curr_date}

    # Create a unique notebook name for this test run
    ${IMG_NAME} =  Catenate  ${IMG_NAME}  ${curr_date}
    Set Global Variable  ${IMG_NAME}  ${IMG_NAME}
    Import New Custom Image    ${IMG_URL}     ${IMG_NAME}    ${IMG_DESCRIPTION}
    ...    software=${IMG_SOFTWARE}    packages=${IMG_PACKAGES}

Get ImageStream Metadata And Check Name
    [Documentation]    Gets the metadata of an ImageStream and checks name of the image
    ${get_metadata} =    OpenShiftLibrary.Oc Get    kind=ImageStream    label_selector=app.kubernetes.io/created-by=byon
    ...    namespace=${APPLICATIONS_NAMESPACE}
    FOR     ${imagestream}    IN    @{get_metadata}
      ${image_name} =    Evaluate    $imagestream['metadata']['annotations']['opendatahub.io/notebook-image-name']
      Exit For Loop If    '${image_name}' == '${IMG_NAME}'
    END
    Should Be Equal    ${image_name}    ${IMG_NAME}
    ${IMAGESTREAM_NAME} =   Set Variable    ${imagestream}[metadata][name]
    ${IMAGESTREAM_NAME} =   Set Global Variable    ${IMAGESTREAM_NAME}

Reset Image Name
    [Documentation]    Helper to reset the global variable img name to default value
    ${IMG_NAME} =  Set Variable  custom-test-image
    Set Global Variable  ${IMG_NAME}  ${IMG_NAME}

Get Standard Data Science Local Registry URL
    [Documentation]    Fetches the local URL for the SDS image
    ${registry} =    Run    oc get imagestream s2i-generic-data-science-notebook -n redhat-ods-applications -o json | jq '.status.dockerImageRepository' | sed 's/"//g'  # robocop: disable
    ${tag} =    Run    oc get imagestream s2i-generic-data-science-notebook -n redhat-ods-applications -o json | jq '.status.tags[-1].tag' | sed 's/"//g'  # robocop: disable
    RETURN    ${registry}:${tag}