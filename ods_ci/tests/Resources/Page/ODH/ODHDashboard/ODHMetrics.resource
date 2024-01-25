*** Settings ***
Documentation    Collection of keywords to interact with Model Serving


*** Variables ***


*** Keywords ***
Move To Tab
    [Documentation]    Open one of the tabs in a Metrics Page (e.g., Endpoint performance/ Model bias)
    [Arguments]    ${tab_title}
    Click Element    xpath://span[text()="${tab_title}"]

Click Configure Button
    [Documentation]    Click the Configure button for configuring the Bias Metrics
    Click Button    Configure

Configure Bias Metrics
    [Documentation]    Configure a Bias Metrics with given arguments
    [Arguments]    ${metric_name}   ${metric_type}    ${protected_attribute}   ${output}    ${output_value}
    ...            ${privileged_value}    ${unprivileged_value}
    Input Text  id=metric-name  ${metric_name}
    Click Element           xpath://button[@id="metric-type"]
    Click Element           xpath://span[contains(text(), ${metric_type})]
    Input Text  id=protected-attribute  ${protected-attribute}
    Input Text  id=unprivileged_value    ${unprivileged_value}
    Input Text  id=output    ${output}
    Input Text  id=output_value    ${output_value}
    Click Element   //button[@data-testid="modal-submit-button"]



