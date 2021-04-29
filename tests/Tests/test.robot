*** Settings ***
Resource  ../Resources/ODS.robot
Library         DebugLibrary

*** Variables ***


*** Test Cases ***
Logged into OpenShift
   [Tags]  Sanity  Smoke
   Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
   Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}

Can Launch Jupyterhub
   [Tags]  Sanity
   Launch Jupyterhub

Can Login to Jupyterhub
   [Tags]  Sanity  Smoke
   Login To Jupyterhub  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
   ${authorization_required} =  Is Service Account Authorization Required
   Run Keyword If  ${authorization_required}  Authorize jupyterhub service account

Can Spawn Notebook
   [Tags]  Sanity
   # We need to skip this testcase if the user has an existing pod
   ${spawner_visible} =  JupyterHub Spawner Is Visible
   Skip If  ${spawner_visible}!=True  The user has an existing notebook pod running
   Select Notebook Image  s2i-generic-data-science-notebook
   Select Notebook Image  s2i-minimal-notebook
   Select Container Size  Small
   # Cannot set number of required GPUs on clusters without GPUs anymore
   #Set Number of required GPUs  9
   #Set Number of required GPUs  0
   Add Spawner Environment Variable  env_one  one
   Remove Spawner Environment Variable  env_one
   Add Spawner Environment Variable  env_two  two
   Remove Spawner Environment Variable  env_two
   Add Spawner Environment Variable  env_three  three
   Remove Spawner Environment Variable  env_three

   Add Spawner Environment Variable  env_four  four
   Add Spawner Environment Variable  env_five  five
   Add Spawner Environment Variable  env_six  six
   Remove Spawner Environment Variable  env_four
   Remove Spawner Environment Variable  env_five
   Remove Spawner Environment Variable  env_six
   Spawn Notebook

Can Launch Python3
   [Tags]  Sanity
   Launch Python3 JupyterHub


