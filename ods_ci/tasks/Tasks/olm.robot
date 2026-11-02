*** Settings ***
Documentation    Collections of tasks to work with OLM operators (excluding RHOAI)
Resource          ../../tests/Resources/RHOSi.resource
Resource          ../Resources/RHODS_OLM/install/oc_install.robot
Suite Setup       RHOSi Setup


*** Variables ***
${STORAGE_SIZE}=    100G
${NFS_PROVISIONER_NAME}=    nfs-provisioner
${NFS_STORAGE_CLASS_NAME}=    nfs
${ARCH_TYPE}=    amd64


*** Tasks ***
Install NFS Operator
    [Documentation]    Installs and configures the NFS Operator
    ...                https://github.com/Jooho/nfs-provisioner-operator/tree/main
    [Tags]    nfs-operator-deploy
    IF    '${ARCH_TYPE}' not in ['s390x', 'ppc64le']
        Install NFS Operator Via Cli
        Deploy NFS Provisioner    ${STORAGE_SIZE}    ${NFS_PROVISIONER_NAME}
        Verify NFS Storage Class    storageclass_name=${NFS_STORAGE_CLASS_NAME}
    ELSE
        Log    Skipping NFS Operator installation for ${ARCH_TYPE} architecture (operator images are only available for amd64/arm64)
        ...    console=yes
    END
