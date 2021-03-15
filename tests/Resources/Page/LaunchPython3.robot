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
   Launch a new JupyterLab Document
   Add and Run JupyterLab Code Cell  import os
   Add and Run JupyterLab Code Cell  print("Hello World!")
   Add and Run JupyterLab Code Cell  print(os.environ)
   Capture Page Screenshot
   #Retrieves all of the output cells
   #Get WebElements  xpath://div[contains(@class,"jp-OutputArea-output")]
   #Get the text of the last output cell
   Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]

   Open With JupyterLab Menu  Git  Clone a Repository
   Input Text  xpath://input[@class="jp-mod-styled"]  https://github.com/sophwats/notebook-smoke-test.git
   Maybe Accept a JupyterLab Prompt

Launch Python3 JupyterLab Smoke Test Notebook
   Launch a new JupyterLab Document

   Add and Run JupyterLab Code Cell  !pip freeze
   Capture Page Screenshot
   Add and Run JupyterLab Code Cell  !pip install watermark

   Add and Run JupyterLab Code Cell  import boto3
   Element Should Not Contain  (//div[contains(@class,"jp-OutputArea-output")])[last()]  ModuleNotFoundError
   Add and Run JupyterLab Code Cell  import kafka
   Element Should Not Contain  (//div[contains(@class,"jp-OutputArea-output")])[last()]  ModuleNotFoundError
   Add and Run JupyterLab Code Cell  import pandas
   Element Should Not Contain  (//div[contains(@class,"jp-OutputArea-output")])[last()]  ModuleNotFoundError
   Add and Run JupyterLab Code Cell  import matplotlib
   Element Should Not Contain  (//div[contains(@class,"jp-OutputArea-output")])[last()]  ModuleNotFoundError
   Add and Run JupyterLab Code Cell  import numpy
   Element Should Not Contain  (//div[contains(@class,"jp-OutputArea-output")])[last()]  ModuleNotFoundError
   Add and Run JupyterLab Code Cell  import scipy
   Element Should Not Contain  (//div[contains(@class,"jp-OutputArea-output")])[last()]  ModuleNotFoundError
   Capture Page Screenshot

   Add and Run JupyterLab Code Cell  import watermark

   Add and Run JupyterLab Code Cell  %load_ext watermark
   Add and Run JupyterLab Code Cell  %watermark
   Capture Page Screenshot
   Add and Run JupyterLab Code Cell  %watermark --iversions
   Capture Page Screenshot

