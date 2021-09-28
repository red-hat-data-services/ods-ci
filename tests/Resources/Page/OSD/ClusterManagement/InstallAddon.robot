*** Settings ***
Resource   ../../Components/Components.resource
Resource   LoginOSD.robot


*** Keywords ***
Open ClusterManagement
    [Arguments]  ${osd_user_name}  ${osd_user_password}
    Open OSD Cluster Manager
    Login To OSD  ${osd_user_name}  ${osd_user_password}

Open AddOns Tab
  ${addonstab} =  Set Variable  ${OSD_CLUSTERMGMT_URL}#addOns
  Go To  ${addonstab}

Install RHODS Operator From AddOns
  [Arguments]  ${notification-email-list}
  Wait Until Page Contains  Red Hat OpenShift Data Science
  Click Element  //div[contains(text(), "Red Hat OpenShift Data Science")]
  ${addon_already_installed} =  Run Keyword And Return Status  Check if Selected AddOn Installed  Red Hat OpenShift Data Science
  Run Keyword If  not ${addon_already_installed}  Install Selected AddOn  Red Hat OpenShift Data Science  ${notification-email-list}

Install Selected AddOn
  [Arguments]  ${addon}  ${notification-email-list}
  Wait Until Page Contains  Install
  Click Install
  Add Notification Email  ${notification-email-list}
  #This is technically different as its type is *submit*, not *button*
  Complete Operator Install

Check if Selected AddOn Installed
  [Arguments]  ${addon}
  Wait Until Page Contains  ${addon}
  ${installed_status} =   Run Keyword And Return Status  Element Should Be Visible  //span[contains(text(), "Installed")]
  [Return]  ${installed_status}

Complete Operator Install
    # Click the Second "Install" Button (first/only one found under a footer tag)
    Wait Until Element is Visible    //footer//*[text()='Install']
    Click Element    //footer//*[text()='Install']
    Verify No Errors Installing

Add Notification Email
  [Arguments]  ${notification-email-list}
  Wait Until Element is Visible  id=field-addon-notification-email  timeout=15seconds
  Input Text  id=field-addon-notification-email  ${notification-email-list}

Verify No Errors Installing
  Sleep  60
  Page Should Not Contain  Error adding add-ons
