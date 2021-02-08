*** Settings *** 
Library  Selenium2Library

*** Keywords ***
Can LoginTo Jupyterhub
   Select Window  NEW
   Wait Until Page Contains  OpenShift
   Click Element  xpath=//*[@id="login-main"]/div/a