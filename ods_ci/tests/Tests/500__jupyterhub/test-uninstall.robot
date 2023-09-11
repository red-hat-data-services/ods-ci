*** Settings ***
Documentation  Tests Operator Uninstall GUI
...            Verify the operator can be uninstalled via GUI

Metadata  Version    0.1.0
...       RHODS-74

Resource  ../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource  ../../Resources/Page/OCPLogin/OCPLogin.resource

Suite Setup  Set Library Search Order
...          SeleniumLibrary
...          JupyterLibrary

Suite Teardown  Close Browser

*** Test Cases ***
Can Uninstall ODH Operator
  [Tags]  TBC
  Open Installed Operators Page
  Uninstall ODH Operator
  ODH Operator Should Be Uninstalled
