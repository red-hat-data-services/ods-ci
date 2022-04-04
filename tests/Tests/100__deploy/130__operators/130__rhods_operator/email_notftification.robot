*** Settings ***
Library       ../../../../../libs/Helpers.py


*** Test Cases ***
Verify Notification email is updated
  [Documentation]  This TC verfiy if the email is updated or not
  [Tags]  ODS-email
  update_notification_email_address     qeairhods-ts2   email_address=takumar@redhat.com

