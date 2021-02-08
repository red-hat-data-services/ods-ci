*** Settings *** 
Library  Selenium2Library

*** Keywords ***
Launch Python3 JupyterHub
   Wait Until Page Contains  New
   Wait Until Page Contains  Files
   Select Window  NEW
   Click Element  xpath=//*[@id="new-dropdown-button"]/span[2]
   Click Element  xpath=//*[@id="kernel-python3"]/a

