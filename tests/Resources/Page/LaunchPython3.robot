*** Settings ***
#Library  JupyterLibrary
Library  JupyterLibrary

*** Keywords ***
Launch Python3 JupyterHub
   Wait Until Page Contains  New
   Wait Until Page Contains  Files
   #TODO: This window title may change so we should be selecting something with more certainty
   Switch Window  Home Page - Select or create a notebook
   Click Button  new-dropdown-button
   Click Link  Python 3

Launch Python3 JupyterLab
   Open With JupyterLab Menu  Git  Clone a Repository
   Input Text  xpath://input[@class="jp-mod-styled"]  https://github.com/TreeinRandomForest/pricingnbs.git
   Debug
   Maybe Accept a JupyterLab Prompt
