*** Settings ***
Documentation    Keywords for task RHODS groups configuration


*** Variables ***
${DEFAULT_ADMIN_GROUPS} =       dedicated-admins
${DEFAULT_ALLOWED_GROUPS} =     system:authenticated
${RHODS_GROUPS_CONFIG} =        tasks/Resources/Configurations/groups/rhods_groups_config.yaml


*** Keywords ***
Modify RHODS Groups
    [Documentation]    (string, string) -> list(dict)
    [Arguments]    ${admin_groups}    ${allowed_groups}
    ${modified_label} =    Set Rhods Groups Modified Label    ${admin_groups}    ${allowed_groups}
    &{template_data} =    Create Dictionary
    ...    admin_groups=${admin_groups}
    ...    allowed_groups=${allowed_groups}
    ...    modified_label=${modified_label}
    ${groups_config} =    Oc Apply    kind=ConfigMap    src=${RHODS_GROUPS_CONFIG}
    ...    api_version=v1    template_data=${template_data}
    Restart JupyterHub Pods
    [Return]    ${groups_config[0]['data']}

Set Rhods Groups Modified Label
    [Documentation]    (str, str) -> str
    [Arguments]    ${admin_groups}    ${allowed_groups}

    IF    "${admin_groups}" == "${DEFAULT_ADMIN_GROUPS}" and "${allowed_groups}" == "${DEFAULT_ALLOWED_GROUPS}"
        Set Local Variable    ${modified_label}    "false"
    ELSE
        Set Local Variable    ${modified_label}    "true"
    END
    [Return]    ${modified_label}

Restart JupyterHub Pods
    [Documentation]    () -> None
    Oc Delete    kind=Pod    namespace=redhat-ods-applications
    ...    api_version=v1    label_selector=app=jupyterhub
