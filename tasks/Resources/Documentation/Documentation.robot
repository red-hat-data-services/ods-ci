*** Keywords ***
Generate Documentation
    [Arguments]    ${src}    ${dest}
    Execute Script    ${CURDIR}/generate_documentation.sh    ${src}    ${dest}