*** Settings ***
Resource  ../Resources/ODS.robot


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

Can Launch Python3
   [Tags]  Sanity
   Launch Python3 JupyterHub


