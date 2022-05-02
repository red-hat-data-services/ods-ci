*** Settings ***
Documentation    Testing custom image imports (Adding ImageStream to redhat-ods-applications)
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Library          JupyterLibrary
Library          OpenShiftCLI
Library          OpenShiftLibrary
Suite Teardown   End Web Test
Force Tags       JupyterHub



*** Variables ***
${YAML} =         tests/Resources/Files/custom_image.yaml
${IMG_NAME} =            custom-test-image
${IMG_URL} =             quay.io/thoth-station/s2i-lab-elyra:v0.1.1
${IMG_DESCRIPTION} =     Testing Only This image is only for illustration purposes, and comes with no support. Do not use.
&{IMG_SOFTWARE} =        Software1=x.y.z
&{IMG_PACKAGES} =        elyra=2.2.4    foo-pkg=a.b.c
# Place holder for the imagestream name of BYON notebook created for this test run
${IMAGESTREAM_NAME}=


*** Test Cases ***
Verify Admin User Can Access Custom Notebook Settings
    Set Library Search Order  SeleniumLibrary
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Sleep  2
    Open Notebook Images Page

Verify Custom Image Can Be Added
    [Documentation]    Imports the custom image via UI
    ...                Then loads the spawner and tries using the custom img
    [Tags]    Tier2
    ...       ODS-1208
    Apply Custom ImageStream And Check Status
    Get ImageStream Metadata And Check Name
    Verify Image Name  ${IMG_NAME}
    Verify Image Description  ${IMG_NAME}  ${IMG_DESCRIPTION}
    Verify User  ${IMG_NAME}  ${TEST_USER.USERNAME}
    Launch JupyterHub Spawner From Dashboard

    # These keywords need to be reworked to function here
    #${spawner_description}=  Fetch Image Tooltip Description  ${IMAGESTREAM_NAME}
    #${spawner_packages}=  Fetch Image Tooltip Info  ${IMAGESTREAM_NAME}
    #${spawner_software}=  Fetch Image Description Info  ${IMAGESTREAM_NAME}
    #Should Match  ${spawner_description}  ${IMG_DESCRIPTION}
    #Should Match  ${spawner_software}  ${IMG_SOFTWARE}
    #Should Match  ${spawner_packages}  ${IMG_PACKAGES}

    Spawn Notebook With Arguments  image=${IMAGESTREAM_NAME}  size=Default
    [Teardown]  Custom Image Teardown

Test Duplicate Image
    [Documentation]  Test adding two images with the same name (should fail)
    Apply Custom ImageStream And Check Status
    Sleep  1
    Import New Image    ${IMG_URL}    ${IMG_NAME}    ${IMG_DESCRIPTION}
    ...    software=${IMG_SOFTWARE}
    ...    packages=${IMG_PACKAGES}
    RHODS Notification Drawer Should Contain  Unable to add notebook image ${IMG_NAME}
    Sleep  1
    Delete Image  ${IMG_NAME}
    Reset Image Name

Test Bad Image URL
    [Documentation]  Test adding an image with a bad repo URL (should fail)
    ${OG_URL}=  Set Variable  ${IMG_URL}
    ${IMG_URL}=  Set Variable  quay.io/RandomName/RandomImage:v1.2.3
    Set Global Variable  ${IMG_URL}  ${IMG_URL}
    Apply Custom ImageStream And Check Status
    RHODS Notification Drawer Should Contain  Unable to add notebook image ${IMG_NAME}
    ${IMG_URL}=  Set Variable  ${OG_URL}
    Set Global Variable  ${IMG_URL}  ${IMG_URL}
    Reset Image Name
    # No image created, teardown not needed

Test Bad Image Import
    [Documentation]  Import a broken image and confirm it cannot spawn
    ${OG_URL}=  Set Variable  ${IMG_URL}
    ${IMG_URL}=  Set Variable  randomstring
    Set Global Variable  ${IMG_URL}  ${IMG_URL}
    Apply Custom ImageStream And Check Status
    Get ImageStream Metadata And Check Name
    Launch JupyterHub Spawner From Dashboard
    # Imgs imported with a broken/wrong url will be disabled in the spawner
    Element Should Be Disabled  xpath://input[contains(@id, "${IMAGESTREAM_NAME}")]
    ${IMG_URL}=  Set Variable  ${OG_URL}
    Set Global Variable  ${IMG_URL}  ${IMG_URL}
    Reset Image Name


*** Keywords ***
Custom Image Teardown
    [Documentation]    Closes the JL server and deletes the ImageStream
    Clean Up Server
    Stop JupyterLab Notebook Server
    Go To  ${ODH_DASHBOARD_URL}
    Open Notebook Images Page
    Sleep  1
    Delete Image  ${IMG_NAME}
    Reset Image Name

Apply Custom ImageStream And Check Status
    [Documentation]    Imports a custom ImageStream via UI and checks the status
    ${curr_date} =  Get Time  year month day hour min sec
    ${curr_date} =  Catenate  SEPARATOR=  @{curr_date}

    # Create a unique notebook name for this test run
    ${IMG_NAME} =  Catenate  ${IMG_NAME}  ${curr_date}
    Set Global Variable  ${IMG_NAME}  ${IMG_NAME}

    ${apply_result} =    Run Keyword And Return Status    Import New Image
    ...    ${IMG_URL}     ${IMG_NAME}    ${IMG_DESCRIPTION}
    ...    software=${IMG_SOFTWARE}
    ...    packages=${IMG_PACKAGES}

Get ImageStream Metadata And Check Name
    [Documentation]    Gets the metadata of an ImageStream and checks name of the image
    ${get_metadata} =    OpenShiftLibrary.Oc Get    kind=ImageStream    label_selector=app.kubernetes.io/created-by=byon
    ...    namespace=redhat-ods-applications
    FOR     ${imagestream}    IN    @{get_metadata}
      ${image_name} =    Evaluate    $imagestream['metadata']['annotations']['opendatahub.io/notebook-image-name']
      Exit For Loop If    '${image_name}' == '${IMG_NAME}'
    END
    Should Be Equal    ${image_name}    ${IMG_NAME}
    ${IMAGESTREAM_NAME} =   Set Variable    ${imagestream}[metadata][name]
    ${IMAGESTREAM_NAME} =   Set Global Variable    ${IMAGESTREAM_NAME}

Reset Image Name
    ${IMG_NAME} =  Set Variable  custom-test-image
    Set Global Variable  ${IMG_NAME}  ${IMG_NAME}
