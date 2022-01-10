*** Settings ***
Library         SeleniumLibrary
Library         Collections
Resource        ../../../Resources/Page/MarketplaceConsole/MarketplaceConsole.robot
Suite Teardown  Redhat Suite Teardown

*** Variables ***
${username}      #tarun24tk@gmail.com
${password}      #Mphasistaiwan#25
#${url}           https://marketplace.redhat.com

*** Test Cases ***
Verify market place login
  [Tags]  tf
 # Wait Until Element is Diabled
#Launch Marketplace
   Open Browser  ${MARKETPLACE_TEST.URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login to marketplace      ${MARKETPLACE_TEST.USERNAME}  ${MARKETPLACE_TEST.PASSWORD}
  #Click Element   //img[contains(@tilte,"Red Hat Marketplace")]

  #Launch Cluster from Marketplace
  #Click Element   //img[contains(@title,"Red Hat Marketplace")]
  ${url}   Get the OC commands For Cluster registration
  log   ${url}
  Log To Console    ${url}
  #Launch title from Dropdown       Workspace      Software
  #sleep  5
  #Wait until Element is Visible          //span[contains(text(),'Generate Secret')]        timeout=20
  #Click Button    Generate Secret
  #Wait until Element is Visible         //div[contains(@aria-label,'code-snippet') and not (contains(@role,'textbox'))]     timeout=20
  #${new}   Get Text    //div[contains(@aria-label,'code-snippet') and (contains(@role,'textbox'))]
  #Wait Until Element is diabled
  #${name}    Get the OC command
  #Launch title from Dropdown        Workspace      Software
  #sleep   10



