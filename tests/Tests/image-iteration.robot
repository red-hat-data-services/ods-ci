*** Settings ***
Resource         ../Resources/ODS.robot
Resource         ../Resources/Common.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***
@{IMAGES}  s2i-minimal-notebook  s2i-generic-data-science-notebook


*** Test Cases ***
Open ODH Dashboard
  [Tags]  Sanity
  Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for ODH Dashboard to Load

Iterative Testing
  [Tags]  Sanity
  FOR  ${image}  IN  @{IMAGES}
    Iterative Image Test  ${image}
  END