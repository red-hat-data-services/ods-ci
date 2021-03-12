*** Settings ***
Resource  ../Resources/ODS.robot
Library         DebugLibrary

*** Variables ***
${MYBROWSER} =  chrome


*** Test Cases ***
Logged into OpenShift
   [Tags]  Sanity
   Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
   Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}

Can Launch Jupyterhub
   [Tags]  Sanity
   Launch Jupyterhub

Can Login to Jupyterhub
   [Tags]  Sanity
   Login To Jupyterhub  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
   ${authorization_required} =  Is Service Account Authorization Required
   Run Keyword If  ${authorization_required}  Authorize jupyterhub service account

Can Spawn Notebook
   [Tags]  Sanity
   # We need to skip this testcase if the user has an existing pod
   ${spawner_visible} =  JupyterHub Spawner Is Visible
   # Official SKIP status will be available in Robot Framework 4.0
   # See: https://github.com/robotframework/robotframework/issues/3622
   Run Keyword If  ${spawner_visible}!=True  Set Tags  SKIP
   Pass Execution If  ${spawner_visible}!=True  SKIP:The user has an existing notebook pod running
   Select Notebook Image  s2i-minimal-notebook
   Select Notebook Image  s2i-scipy-notebook
   Select Notebook Image  s2i-tensorflow-notebook
   Select Container Size  Small
   Set Number of required GPUs  9
   Set Number of required GPUs  0
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


