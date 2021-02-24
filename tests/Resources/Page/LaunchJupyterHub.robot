*** Settings *** 
Library  SeleniumLibrary

*** Keywords ***
Launch Jupyterhub
   Wait Until Page Contains  Networking
   Click Element  xpath=/html/body/div[2]/div/div/div/div/div[1]/div/div/nav/ul/li[4]/button
   Wait Until Page Contains  Routes  timeout=15
   Click Element  xpath=//*[@id="page-sidebar"]/div/nav/ul/li[4]/section/ul/li[2]/a
   Maximize Browser Window
   Wait Until Page Contains  odh-dashboard
   Sleep  4s
   Wait Until Page Contains  jupyterhub  timeout=15
   Click Element  partial link:https://jupyterhub
