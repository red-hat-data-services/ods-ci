*** Settings ***
Documentation    Tasks related to the operator rearchitecture
Library          String
Library          OperatingSystem


*** Tasks ***
Switch To Core Installation Profile
    [Documentation]
    Switch Installation Profile    profile=core

Switch To Serving Installation Profile
    [Documentation]
    Switch Installation Profile    profile=serving

Switch To Training Installation Profile
    [Documentation]
    Switch Installation Profile    profile=training

Switch To Workbench Installation Profile
    [Documentation]
    Switch Installation Profile    profile=workbench

Switch To None Installation Profile
    [Documentation]
    Switch Installation Profile    profile=none


Verify Core Installation Profile
    [Documentation]
    Verify Installation Profile    profile=core

Verify Serving Installation Profile
    [Documentation]
    Verify Installation Profile    profile=serving

Verify Training Installation Profile
    [Documentation]
    Verify Installation Profile    profile=training

Verify Workbench Installation Profile
    [Documentation]
    Verify Installation Profile    profile=workbench

Verify None Installation Profile
    [Documentation]
    Verify Installation Profile    profile=none


*** Keywords ***
Switch Installation Profile
    [Documentation]
    [Arguments]    ${profile}=core    ${dsc_name}=datasciencecluster-sample    ${namespace}=opendatahub
    ${current_profile} =    Get Current Installation Profile
    IF    ${current_profile} == "${profile}"
        Skip    msg=Installed profile is already profile ${profile}
    END
    ${out} =    Run    oc patch datasciencecluster ${dsc_name} --type='merge' -p '{"spec":{"profile":"${profile}"}}'
    Should Be Equal As Strings    ${out}    datasciencecluster.datasciencecluster.${namespace}.io/${dsc_name} patched

Verify Installation Profile
    [Documentation]    Currently always fails, need a better way to check
    [Arguments]    ${profile}=core
    ${current_profile} =    Get Current Installation Profile
    IF    ${current_profile} != "${profile}"
        Switch Installation Profile    profile=${profile}
        Sleep    10s    #Need to define how to check when the switch is complete, '.status.phase' is always "Ready"
    END
    ${expected} =    Get File    ods_ci/tasks/Resources/Files/${profile}.txt
    ${actual} =    Run    oc get $(oc api-resources --namespaced=true --verbs=list -o name | awk '{printf "%s%s",sep,$0;sep=","}') --ignore-not-found -n opendatahub -o=custom-columns=KIND:.kind,NAME:.metadata.name --sort-by='kind' | grep -v "PackageManifest\|Event"  # robocop: disable
    Should Be Equal As Strings    ${expected}    ${actual}

Get Current Installation Profile
    [Documentation]
    [Arguments]    ${dsc_name}=datasciencecluster-sample
    ${profile} =    Run    oc get datasciencecluster ${dsc_name} -o json | jq '.spec.profile'
    RETURN    ${profile}