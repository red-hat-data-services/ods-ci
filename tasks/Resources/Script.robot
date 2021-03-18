*** Settings ***
Library    Process

*** Keywords ***

Execute Script
   [Arguments]    ${script}    ${argument1}    ${argument2}
   Run Process    ${script}    ${argument1}    ${argument2}    shell=yes