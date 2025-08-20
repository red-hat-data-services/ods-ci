*** Settings ***
Documentation    Collections of tasks to work with OLM operators (excluding RHOAI)
Resource          ../../tests/Resources/RHOSi.resource
Resource          ../Resources/RHODS_OLM/install/oc_install.robot
Suite Setup       RHOSi Setup
Suite Teardown    RHOSi Teardown


*** Variables ***
${STORAGE_SIZE}=    100G


*** Tasks ***
Install NFS Operator
    [Documentation]    Installs and configures the NFS Operator
    [Tags]    nfs-operator-deploy
    Install NFS Operator Via Cli
    Deploy NFS Provisioner    ${STORAGE_SIZE}
    