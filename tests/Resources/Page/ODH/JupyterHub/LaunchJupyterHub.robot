*** Settings *** 
Library  JupyterLibrary

*** Keywords ***
Launch Jupyterhub
   Wait Until Page Contains  Networking  timeout=60
   Click Button  Networking
   Wait Until Page Contains  Routes  timeout=15
   Click Link  Routes
   Maximize Browser Window
   Wait Until Page Contains Element  xpath://input[@data-test-id="item-filter"]
   Input Text  xpath://input[@data-test-id="item-filter"]  odh-dashboard
   Wait Until Page Contains  odh-dashboard
   Sleep  4s
   Input Text  xpath://input[@data-test-id="item-filter"]  jupyterhub
   Wait Until Page Contains  jupyterhub  timeout=15
   Click Element  partial link:https://jupyterhub
   Sleep  10s
   Switch Window  JupyterHub
