*** Settings ***
Resource    ../Resources/RedHatMarketplace.resource
Resource          ../../tests/Resources/RHOSi.resource
Suite Setup       RHOSi Setup
Suite Teardown    RHOSi Teardown

*** Tasks ***
Register Cluster To RedHat Marketplace
    [Tags]    rhm-register
    Check Cluster Is Not Already Registered
    Install RedHat Marketplace Operator
    Create RedHat Marketplace Secret    token=${RHM_TOKEN}
    Is Cluster Registered