*** Settings ***
Library    OpenShiftLibrary
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot

*** Keywords ***

Delete ImageStream using Name
    [Arguments]    ${namespace}    ${name}
    ${image_exists}=   Check If ImageStream Exists       ${namespace}      ${name}
    IF    '${image_exists}'=='PASS'
        ${deleted_images}=    Oc Delete
        ...    kind=ImageStream  namespace=${namespace}     label_selector=opendatahub.io/modified=false     field_selector=metadata.name==${name}
        IF    len(${deleted_images}) == 0
            FAIL    Error deleting ImageStreams: ${deleted_images}
        ELSE
            ${image_exists}=    Check If ImageStream Exists       ${namespace}      ${name}
            IF    '${image_exists}'=='PASS'    FAIL    ImageStreams '${name}' in namespace '${namespace}' still exist
        END
    ELSE
        Log    level=WARN
        ...    message=No ImageStream present with Name '${name}' in '${namespace}' namespace
    END

Check If ImageStream Exists
    [Arguments]    ${namespace}      ${name}
    ${status}   ${val}  Run keyword and Ignore Error   Oc Get  kind=ImageStream  namespace=${namespace}         field_selector=metadata.name==${name}
    RETURN   ${status}




