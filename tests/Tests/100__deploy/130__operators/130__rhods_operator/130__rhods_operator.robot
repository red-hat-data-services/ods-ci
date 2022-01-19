*** Settings ***
Library         SeleniumLibrary
Library         RequestsLibrary
Library         Collections
Resource        ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../../Resources/Common.robot
Suite Setup     Set Library Search Order  SeleniumLibrary
Suite Teardown  Close Browser

*** Variables ***
#Commercial variable to verify if the URL pregent for RHODS is commercial or not
${commercial_url}              https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-data-science

*** Test Cases ***
Verify RHODS operator information
  [Documentation]  This TC verfiy if the text present in RHODS opeartor Details section
  [Tags]  ODS-498   ODS-624   Sanity
  Open Installed Operators Page
  #Select All Projects
  Click On Searched Operator      Red Hat OpenShift Data Science
  ${link_elements}=  Get WebElements    xpath=//*[@class="co-clusterserviceversion-details__field"]//a
  #Temporary List to hold the url for the verification
  ${temp_list}        Create List
  FOR  ${idx}  ${external_link}  IN ENUMERATE  @{link_elements}  start=1
        ${href}=    Get Element Attribute    ${external_link}    href
        Append to List      ${temp_list}       ${href}
        Run Keyword IF      $href == "mailto:undefined"   Continue For Loop
        ...    ELSE IF     '${href}' == '${commercial_url}'   Get HTTP Status Code   ${href}
        ...       ELSE      Fail      URL '${href}' should not be Present in RHODS Cluster Service Detail Section
  END

  Run Keyword IF     "mailto:undefined" not in $temp_list     FAIL    There shouldn't be reference to maintainers email

*** Keywords ***

Get HTTP Status Code
    [Arguments]  ${link_to_check}
    ${response}=    RequestsLibrary.GET  ${link_to_check}   expected_status=any
    Run Keyword And Continue On Failure  Status Should Be  200
    Log To Console    HTTP status For The '${link_to_check}' is '${response.status_code}'