*** Settings ***
Documentation    Tests to verify that ODH in Openshift can be
...              installed from Dashboard
Metadata         Version    0.0.1
Resource         ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Library         SeleniumLibrary
Suite Setup     Set Library Search Order  SeleniumLibrary
Suite Teardown  Close Browser


*** Test Cases ***
Can Install ODH Operator
  [Tags]  TBC
  Open OperatorHub
  Install ODH Operator
  ODH Operator Should Be Installed


