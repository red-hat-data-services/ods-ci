*** Settings ***
Documentation    Collections of keywords to register clusters to RHM
Resource    ../Resources/RedHatMarketplace.resource
Resource          ../../tests/Resources/RHOSi.resource
Suite Setup       RHOSi Setup
Suite Teardown    RHOSi Teardown


*** Tasks ***
Register Cluster To RedHat Marketplace
    [Documentation]    Registers a cluster to RHM if not already done
    [Tags]    rhm-register
    Check Cluster Is Not Already Registered
    Create RedHat Marketplace Project
    Install RedHat Marketplace Operator
    Create RedHat Marketplace Secret    token=${RHM_TOKEN}
    Is Cluster Registered
