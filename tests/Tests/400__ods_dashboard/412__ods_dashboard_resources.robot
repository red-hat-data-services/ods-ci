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
    Go Back And Check Previouse Step Is Selected     n_steps=${count}   exp_step=${count-1}
    Run Keyword And Continue On Failure         Mark Step Check As Yes
    Go To Next QuickStart Step
    Go To Next QuickStart Step
    Close QuickStart From Button
    Page Should Not Contain QuickStart Sidebar
    QuickStart Status Should Be    ${element}  Complete

Verify Quick Starts Work As Expected When Restarting The Previous One
    [Arguments]    ${element}
    Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Restart
    QuickStart Status Should Not Be Set     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Close
    Continue QuickStart
    Current Step In QuickStart Should Be    n_steps=${count}  exp_step=1
    Close QuickStart From Top     decision=cancel
    Current Step In QuickStart Should Be    n_steps=${count}  exp_step=1
    Close QuickStart From Top     decision=leave
    Page Should Not Contain QuickStart Sidebar
    QuickStart Status Should Be    ${element}  In Progress
    Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Continue

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
    QuickStart Status Should Be    ${element}      Failed

Verify Quick Starts Work As Expected When All Steps Are Skipped
    [Arguments]     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Star QuickStart Tour
    FOR     ${index}    IN RANGE    ${count}
        Go To Next QuickStart Step
    END
    QuickStart Status Should Be    ${element}      In Progress
    Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Continue

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
    QuickStart Status Should Be    ${element}      In Progress
    Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Continue
