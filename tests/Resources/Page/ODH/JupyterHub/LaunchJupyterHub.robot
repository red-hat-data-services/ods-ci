*** Settings *** 
Library  JupyterLibrary

*** Keywords ***
Launch Jupyterhub via Routes
   [Documentation]  This keyword only works with kubeadmin or accounts that are
   ...              cluster admins. Use Launch via App for other accounts.
   Wait Until Page Contains  Networking  timeout=60
   Click Button  Networking
   Wait Until Page Contains  Routes  timeout=15
   Click Link  Routes
   Maximize Browser Window
   Wait Until Page Contains Element  xpath://input[@data-test-id="item-filter"]
   Input Text  xpath://input[@data-test-id="item-filter"]  rhods-dashboard
   Wait Until Page Contains  rhods-dashboard
   Sleep  4s
   Input Text  xpath://input[@data-test-id="item-filter"]  jupyterhub
   Wait Until Page Contains  jupyterhub  timeout=15
   Click Element  partial link:https://jupyterhub
   Sleep  10s
   Switch Window  JupyterHub

Launch Jupyterhub via App
   Click Element  xpath://header[@id='page-main-header']/div[2]/div[1]/div[1]/nav/button
   Sleep  1
   Click Element  xpath://a[contains(@href, 'https://rhods-dashboard')]
   Switch Window  NEW