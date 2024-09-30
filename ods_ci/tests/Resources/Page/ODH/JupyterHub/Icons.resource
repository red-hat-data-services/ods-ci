*** Comments ***
# This whole file is a copy of the "clients/jupyterlab/Icons.resource" file from the JupyterLibrary.

# Motivation for the copy is that there is an explicit usage of the JupyterLibrary on one line of
# the PageInfo.resource file in that library. So this file and the PageInfo.resource file were moved
# to our repository with the one line fix.


*** Settings ***
Documentation       Icon keywords for JupyterLab

# Resource            JupyterLibrary/clients/jupyterlab/PageInfo.resource
Resource            ./PageInfo.resource    # Edited - our change


*** Variables ***
&{JLAB1 CSS ICONS}
...                     add=span[data-icon="add"]
...                     run=span[data-icon="run"]
...                     filled circle=.jp-CircleFilledIcon
...                     empty circle=.jp-CircleEmptyIcon
&{JLAB2 CSS ICONS}
...                     add=svg[@data-icon='ui-components:add']
...                     run=svg[@data-icon='ui-components:run']
...                     filled circle=svg[@data-icon='ui-components:circle-filled']
...                     empty circle=svg[@data-icon='ui-components:circle-empty']
&{JLAB1 XP ICONS}
...                     add=span[@data-icon = 'add']
...                     run=span[@data-icon = 'run']
...                     filled circle=div[contains(@class, 'jp-CircleFilledIcon')]
...                     empty circle=div[contains(@class, 'jp-CircleEmptyIcon')]
&{JLAB2 XP ICONS}
...                     add=*[@data-icon='ui-components:add']
...                     run=*[@data-icon='ui-components:run']
...                     filled circle=*[@data-icon='ui-components:circle-filled']
...                     empty circle=*[@data-icon='ui-components:circle-empty']


*** Keywords ***
Get JupyterLab Icon CSS Custom    # Edited
    [Documentation]    Get a Lab version-specific, but general CSS selector for an ``icon``.
    [Arguments]    ${icon}
    ${version} =    Get JupyterLab Application Version Info Custom
    ${sel} =    Set Variable If    ${version[0].__eq__('1')}
    ...    ${JLAB1 CSS ICONS['${icon}']}
    ...    ${JLAB2 CSS ICONS['${icon}']}
    [Return]    ${sel}

Get JupyterLab Icon XPath Custom    # Edited
    [Documentation]    Get a Lab version-specific, but general XPath selector for an ``icon``.
    [Arguments]    ${icon}
    ${version} =    Get JupyterLab Application Version Info Custom
    ${sel} =    Set Variable If    ${version[0].__eq__('1')}
    ...    ${JLAB1 XP ICONS['${icon}']}
    ...    ${JLAB2 XP ICONS['${icon}']}
    [Return]    ${sel}
