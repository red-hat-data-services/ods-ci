*** Settings ***
Library  SeleniumLibrary

*** Keywords ***
Launch Python3 JupyterHub
   Wait Until Page Contains  New
   Wait Until Page Contains  Files
   #TODO: This window title may change so we should be selecting something with more certainty
   Switch Window  Home Page - Select or create a notebook
   Click Button  new-dropdown-button
   Click Link  Python 3
