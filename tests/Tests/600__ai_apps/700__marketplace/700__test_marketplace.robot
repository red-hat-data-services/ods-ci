*** Settings ***
Library         SeleniumLibrary
Resource        ../../../Resources/Page/MarketplaceConsole/MarketplaceConsole.robot
#Resource        ../../../../Resources/Common.robot
Suite Setup     Set Library Search Order  SeleniumLibrary
Suite Teardown  Close Browser

*** Variables ***
${m_url}            https://marketplace.redhat.com
${username}         tarun24tk@gmail.com
${password}         Mphasistaiwan#25
*** Test Cases ***
Verify market place keyword
     [Tags]  test    tr
      Open Browser  ${m_url}   browser=${BROWSER.NAME}   options=${BROWSER.OPTIONS}
      Login to Marketplace     ${username}    ${password}
      ${oc_command}       Get the OC commands For Cluster registration
      Log        ${oc_command} 
      Log To Console    ${oc_command}