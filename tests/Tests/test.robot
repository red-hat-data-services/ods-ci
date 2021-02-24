*** Settings ***
Resource  ../Resources/ODS.robot
Library         DebugLibrary

*** Variables ***
${MYBROWSER} =  chrome


*** Test Cases ***
Logged into OpenShift 
   [Tags]  Sanity
   Login To Openshift

Can Launch Jupyterhub
   [Tags]  Sanity
   Launch Jupyterhub

Can Login to Jupyterhub
   [Tags]  Sanity
   Can LoginTo Jupyterhub

Can Spawn Notebook
   [Tags]  Sanity
   Select Notebook Image  s2i-minimal-notebook:v0.0.4
   Select Notebook Image  s2i-scipy-notebook:v0.0.1
   Select Notebook Image  s2i-tensorflow-notebook:v0.0.1
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


