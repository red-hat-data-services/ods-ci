*** Settings ***
Library  Dialogs

*** Keywords ***
Open OSD Cluster Manager
    Open Browser    ${OSD_CLUSTERMGMT_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}

Login To OSD
  [Arguments]  ${osd_user_name}  ${osd_user_password}
  # Give the login prompt time to render after browser opens
  Wait Until Page Contains  Red Hat login or email
  Input Text  id=username-verification  ${osd_user_name}
  Click Element  id=login-show-step2
  Wait Until Page Contains  Password
  Sleep  1  # Wait out silly animation
  Input Text  id=password  ${osd_user_password}
  Click Element  id=rh-password-verification-submit-button
  # FIXME: replace this sleep for something more efficient, considering that this method is used for
  # authentication in OpenShift Console, but also RHODS dashboard and other places
  Sleep  5
