*** Settings ***
Documentation    Tests to verify that ODH in Openshift can be
...              installed from Dashboard

Metadata         Version    0.0.1

Resource  ../Resources/Page/OCPDashboard/OCPDashboard.resource

Suite Teardown  Close Browser


*** Test Cases ***
Can Install ODH Operator
  Open OperatorHub
  Install ODH Operator
  ODH Operator Should Be Installed
  

