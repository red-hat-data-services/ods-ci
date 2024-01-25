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
    ...            ${privileged_value}    ${unprivileged_value}   ${violation_threshold}
    Input Text  id=metric-name  ${metric_name}
    Click Element           xpath://button[@id="metric-type"]
    Click Element           xpath://span[contains(text(), '${metric_type}')]/ancestor::button
    Input Text  id=protected-attribute  ${protected_attribute}
    Input Text  id=privileged-value    ${unprivileged_value}
    Input Text  id=unprivileged-value    ${unprivileged_value}
    Input Text  id=output    ${output}
    Input Text  id=output-value    ${output_value}
    Input Text  id=violation-threshold    ${violation_threshold}
    Click Element   //button[@data-testid="modal-submit-button"]

View Metrics
    [Documentation]    View configured Bias Metrics from Model serving Page
    Click Element   xpath://button[text()="View metrics"]

Modify Time Range For Metrics
    [Documentation]    Modify Time range for a metrics
    [Arguments]    ${time_range}
    Click Element   xpath://div[text()="Time range"]/following-sibling::div//button
    Click Element   xpath://button[text()="${time_range}"]/..


Modify Refresh Interval For Metrics
    [Documentation]    Modify Refresh Interval for a metrics
    [Arguments]    ${refresh_interval}
    Click Element   xpath://div[text()="Refresh interval"]/following-sibling::div//button
    Click Element   xpath://button[text()="${refresh_interval}"]/..




