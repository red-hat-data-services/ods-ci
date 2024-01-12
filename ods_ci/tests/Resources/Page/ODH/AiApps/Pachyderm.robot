*** Settings ***
Documentation       Resource file for pachyderm operator
Resource            ../JupyterHub/JupyterLabLauncher.robot
Library             SeleniumLibrary


*** Keywords ***
Delete Pipeline And Stop JupyterLab Server
    [Documentation]     Deletes pipeline using command from jupyterlab and clean and stops the server.
    Run Cell And Check For Errors   !pachctl delete pipeline edges
    Clean Up Server
    Stop JupyterLab Notebook Server
