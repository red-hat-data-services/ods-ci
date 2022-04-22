*** Settings ***
Documentation    Testing the backend for custom images (Adding ImageStream to redhat-ods-applications)
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Library          JupyterLibrary
Library          OpenShiftCLI
Library          OpenShiftLibrary
Suite Teardown   Custom Image Teardown
Force Tags       JupyterHub



*** Variables ***
${YAML} =         tests/Resources/Files/custom_image.yaml
${IMG_NAME} =     custom-test-image


*** Test Cases ***
Verify Admin User Can Access Custom Notebook Settings
    Set Library Search Order  SeleniumLibrary
    Launch Dashboard    ocp_user_name=${OCP_ADMIN_USER.USERNAME}    ocp_user_pw=${OCP_ADMIN_USER.PASSWORD}
    ...    ocp_user_auth_type=${OCP_ADMIN_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Open Notebook Images Page

Verify Custom Image Can Be Added
    [Documentation]    Applies the YAML and Gets the ImageStream
    ...                Then loads the spawner and tries using the custom img
    [Tags]    Tier2
    ...       ODS-1208
    Apply Custom ImageStream And Check Status
    Get ImageStream Metadata And Check Name
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${IMG_NAME}  size=Default


*** Keywords ***
Custom Image Teardown
    [Documentation]    Closes the JL server and deletes the ImageStream
    End Web Test
    OpenShiftCLI.Delete    kind=ImageStream    field_selector=metadata.name==${IMG_NAME}
    ...    namespace=redhat-ods-applications

Apply Custom ImageStream And Check Status
    [Documentation]    Applies a custom ImageStream as a YAML and checks the status

    ${software} =   Create Dictionary    Python=x.y.z    CUDA=1.2.3
    ${packages} =   Create Dictionary    my-pkg=a.b.c    foo-bar=4.5.6
    ${apply_result} =    Run Keyword And Return Status    Import New Image  
    ...    quay.io/thoth-station/s2i-lab-elyra:v0.1.1
    ...    Custom Image
    ...    Testing Only This image is only for illustration purposes, and comes with no support. Do not use.
    ...    software=${software}
    ...    packages=${packages}

    #${apply_result} =    Run Keyword And Return Status    Run    oc apply -f ${YAML}
    #Should Be Equal    "${apply_result}"    "True"
    # OpenShiftCLI.Apply    kind=ImageStream    src="tests/Resources/Files/custom_image.yaml"
    # ...    namespace=redhat-ods-applications

Get ImageStream Metadata And Check Name
    [Documentation]    Gets the metadata of an ImageStream and checks name of the image
    ${get_metadata} =    OpenShiftCLI.Get    kind=ImageStream    field_selector=metadata.name==${IMG_NAME}
    ...    namespace=redhat-ods-applications
    &{data} =    Set Variable    ${get_metadata}[0]
    Should Be Equal    ${data.metadata.name}    ${IMG_NAME}
