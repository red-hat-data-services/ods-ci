*** Settings ***
Documentation    Testing the backend for custom images (Adding ImageStream to redhat-ods-applications)
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Library          JupyterLibrary
Library          OpenShiftCLI
Suite Teardown   Custom Image Teardown


*** Variables ***
${YAML} =         configs/resources/custom_image.yaml


*** Test Cases ***
Verify ImageStream Can Be Created
    [Documentation]    Applies the YAML and Gets the ImageStream
    [Tags]    Sanity
    ...       ODS-1208
    ${apply_status} =    Run Keyword And Return Status    Run    oc apply -f ${YAML}
    # OpenShiftCLI.Apply    kind=ImageStream    src="configs/resources/custom_image.yaml"
    # ...    namespace=redhat-ods-applications
    ${get_status} =    OpenShiftCLI.Get    kind=ImageStream    field_selector=metadata.name==custom-test-image
    ...    namespace=redhat-ods-applications
    Log To Console    ${get_status}

Verify Custom Image Spawn
    [Documentation]    Tries spawning the custom image
    [Tags]    Sanity
    ...       ODS-1208
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=custom-test-image  size=Default


*** Keywords ***
Custom Image Teardown
    [Documentation]    Closes the JL server and deletes the ImageStream
    End Web Test
    OpenShiftCLI.Delete    kind=ImageStream    field_selector=metadata.name==custom-test-image
    ...    namespace=redhat-ods-applications
