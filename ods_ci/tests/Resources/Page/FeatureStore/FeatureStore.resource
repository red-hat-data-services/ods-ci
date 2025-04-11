*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process
Resource         ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Keywords ***
Prepare Feature Store Test Suite
    [Documentation]   Prepare Feature store setup by enabling component
    RHOSi Setup
    Enable Component    feastoperator
    Wait Component Ready    feastoperator

Cleanup Feature Store Setup
    [Documentation]   cleanup Feature store setup by Disabling component
    Disable Component    feastoperator
    RHOSi Teardown