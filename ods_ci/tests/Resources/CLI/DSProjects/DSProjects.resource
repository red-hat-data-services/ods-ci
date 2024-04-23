*** Settings ***
Documentation    Collection of keywords to interact with the administration of DS Projects via CLI


*** Keywords ***

Delete All DS Projects With Name Like
    [Documentation]    Delete all accelerator profiles with a name that partially or totally matches with the given
    ...                {dsp_name}
    ...                Uses OC
    [Arguments]   ${dsp_name}
    ${dsp_str}=    Run
    ...    oc get projects -o json | jq .items[].metadata.name | grep ${dsp_name} | tr -d '"'
    @{dsp_list}=    Split String    ${dsp_str}    separator=\n
    Log     List of DS Projects to be deleted: @{dsp_list}    console=yes
    FOR    ${dsp_name}    IN    @{dsp_list}
        ${return_code}=    Run And Return Rc
        ...    oc delete project ${dsp_name}
        Should Be Equal As Integers  ${return_code}   0   msg=Error deleting DS Project ${dsp_name}
    END
