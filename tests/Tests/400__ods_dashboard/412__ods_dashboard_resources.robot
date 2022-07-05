*** Settings ***
Library         OpenShiftCLI
Resource        ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource        ../../Resources/Page/LoginPage.robot
Test Setup      Resources Test Setup
Test Teardown   Resources Test Teardown


*** Test Cases ***
Verify Quick Starts Work As Expected
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1166    ODS-1306
    ...     ODS-1307    ODS-1308
    ...     ODS-1402    ODS-1403
    Verify Quick Starts Work As Expected When All Steps Are Marked As Yes   create-jupyter-notebook-anaconda
    Verify Quick Starts Work As Expected When Restarting The Previous One   create-jupyter-notebook-anaconda
    Verify Quick Starts Work As Expected When All Steps Are Skipped         create-jupyter-notebook
    Verify Quick Starts Work As Expected When At Least One Step Is Skipped      deploy-python-model
    Verify Quick Starts Work As Expected When One Step Is Marked As No  openvino-inference-notebook

Verify Resource Link HTTP Status Code
    [Documentation]    Verifies the how-to, documentation and tutorial cards in Resource page
    ...                redirects users to working URLs (i.e., http status must be 200)
    [Tags]    Sanity
    ...       ODS-531    ODS-507
    Click Link    Resources
    Sleep    5
    ${link_elements}=     Get Link Web Elements From Resource Page
    URLs HTTP Status Code Should Be Equal     link_elements=${link_elements}    expected_status=200


*** Keywords ***
Resources Test Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Click Link      Resources
    Sleep   5

Resources Test Teardown
    Close All Browsers

Verify Quick Starts Work As Expected When All Steps Are Marked As Yes
    [Arguments]    ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Star QuickStart Tour
    FOR     ${index}    IN RANGE    ${count}
        Run Keyword And Continue On Failure     Mark Step Check As Yes
        IF  ${index} != ${count-1}
            Go To Next QuickStart Step
        END
    END
    Run Keyword And Continue On Failure     Go Back And Check Previouse Step Is Selected     n_steps=${count}   exp_step=${count-1}
    Run Keyword And Continue On Failure         Mark Step Check As Yes
    Go To Next QuickStart Step
    Go To Next QuickStart Step
    Close QuickStart From Button
    Run Keyword And Continue On Failure     Page Should Not Contain QuickStart Sidebar
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}  Complete

Verify Quick Starts Work As Expected When Restarting The Previous One
    [Arguments]    ${element}
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Restart
    Run Keyword And Continue On Failure     QuickStart Status Should Not Be Set     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Close
    Continue QuickStart
    Run Keyword And Continue On Failure     Current Step In QuickStart Should Be    n_steps=${count}  exp_step=1
    Close QuickStart From Top     decision=cancel
    Run Keyword And Continue On Failure     Current Step In QuickStart Should Be    n_steps=${count}  exp_step=1
    Close QuickStart From Top     decision=leave
    Run Keyword And Continue On Failure     Page Should Not Contain QuickStart Sidebar
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}  In Progress
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Continue

Verify Quick Starts Work As Expected When One Step Is Marked As No
    [Arguments]     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Star QuickStart Tour
    FOR     ${index}    IN RANGE    ${count}
        IF  ${index} != ${count-1}
            Run Keyword And Continue On Failure     Mark Step Check As Yes
        ELSE
            Run Keyword And Continue On Failure     Mark Step Check As No
        END
        Go To Next QuickStart Step
    END
    Close QuickStart From Button
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}      Failed

Verify Quick Starts Work As Expected When All Steps Are Skipped
    [Arguments]     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Star QuickStart Tour
    FOR     ${index}    IN RANGE    ${count}
        Go To Next QuickStart Step
    END
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}      In Progress
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Continue

Verify Quick Starts Work As Expected When At Least One Step Is Skipped
    [Arguments]     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Star QuickStart Tour
    FOR     ${index}    IN RANGE    ${count}
        IF  ${index} == ${0}
            Run Keyword And Continue On Failure     Mark Step Check As No
        END
        Go To Next QuickStart Step
    END
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}      In Progress
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Continue
