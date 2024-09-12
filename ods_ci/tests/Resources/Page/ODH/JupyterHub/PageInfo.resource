*** Comments ***
# This whole file is a copy of the "clients/jupyterlab/PageInfo.resource" file from the JupyterLibrary.

# Motivation for the copy is that there is an explicit usage of the JupyterLibrary on one line of
# the PageInfo.resource file in that library. So this file and the Icons.resource file were moved
# to our repository with the one line fix. See the "Edited - our fix" line.


*** Settings ***
Documentation       Page config keywords for JupyterLab

Resource            JupyterLibrary/clients/jupyterlab/Selectors.resource
Library             String
Library             json    WITH NAME    JSON


*** Variables ***
${JLAB XP PAGEINFO}                 script[contains(@id, 'jupyter-config-data')]
# keep this updated below
@{JLAB DEFAULT PAGEINFO TAGS}       appName    appVersion    buildAvailable
...                                 buildCheck    notebookVersion    devMode


*** Keywords ***
Get JupyterLab Page Info Custom    # Edited
    [Documentation]    Get one (or all) of the ``pageInfo`` ``key`` s from JupyterLab's HTML ``<head>``.
    ...    Optionally ``clear`` the cached info first.
    ...
    ...    See also:
    ...    - [#Tag With JupyterLab Metadata|Tag With JupyterLab Metadata]
    [Arguments]    ${key}=${EMPTY}    ${clear}=${False}
    ${pageInfo} =    Get Variable Value    ${JLAB PAGEINFO CACHE}    ${EMPTY}
    # Run Keyword If    ${clear} or not ${pageInfo.__len__()}    Update JupyterLab PageInfo Cache
    Run Keyword If    ${clear} or not ${pageInfo.__len__()}    Update JupyterLab PageInfo Cache Custom    # Edited
    ${pageInfo} =    Set Variable    ${JLAB PAGEINFO CACHE}
    ${result} =    Set Variable If    ${key.__len__()}    ${pageInfo.get("${key}")}    ${pageInfo}
    [Return]    ${result}

Update JupyterLab PageInfo Cache Custom    # Edited
    [Documentation]    Update the cached JupyterLab ``pageInfo``. _Not usually needed._
    ${sel} =    Set Variable    xpath://${JLAB XP PAGEINFO}
    Wait Until Page Contains Element    ${sel}
    # ${txt} =    JupyterLibrary.Get Element Attribute    ${sel}    innerHTML
    ${txt} =    Get Element Attribute    ${sel}    innerHTML    # Edited - our fix
    ${pageInfo} =    JSON.Loads    ${txt}
    Set Suite Variable    ${JLAB PAGEINFO CACHE}    ${pageInfo}    children=${True}

Tag With JupyterLab Metadata Custom    # Edited
    [Documentation]    Tag the current test (or suite) with ``keys`` from the
    ...    JupyterLab ``pageInfo``.
    ...    The default ``keys``: ``appName`` ``appVersion`` ``buildAvailable``
    ...    ``buildCheck`` ``notebookVersion`` ``devMode``
    [Arguments]    ${keys}=${JLAB DEFAULT PAGEINFO TAGS}    ${clear}=${False}
    # ${info} =    Get JupyterLab Page Info    clear=${clear}
    ${info} =    Get JupyterLab Page Info Custom    clear=${clear}    # Edited
    FOR    ${key}    IN    @{keys}
        ${val} =    Set Variable    ${info.get("${key}")}
        Set Tags    jupyterlab:${key}:${val}
    END

Get JupyterLab Application Version Info Custom    # Edited
    [Documentation]    Get the version of the application ``2.3.0.rc1`` as a list of
    ...    strings from ``pageInfo``, e.g. ``["2", "3", "1", "rc1"]``. Optionally ``clear``
    ...    the cached info first.
    [Arguments]    ${clear}=${False}
    # ${version} =    Get JupyterLab Page Info    appVersion    clear=${clear}
    ${version} =    Get JupyterLab Page Info Custom   appVersion    clear=${clear}    # Edited
    ${version_info} =    Set Variable    ${version.split(".")}
    [Return]    ${version_info}
