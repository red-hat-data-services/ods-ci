*** Settings ***
Documentation    Collections of tasks to work with OLM operators (excluding RHOAI)
Resource          ../../tests/Resources/RHOSi.resource
Resource          ../Resources/RHODS_OLM/install/oc_install.robot
Suite Setup       RHOSi Setup


*** Variables ***
${STORAGE_SIZE}=    100G
${NFS_PROVISIONER_NAME}=    nfs-provisioner
${NFS_STORAGE_CLASS_NAME}=    nfs


*** Tasks ***
Install NFS Operator
    [Documentation]    Installs and configures the NFS Operator
    ...                https://github.com/Jooho/nfs-provisioner-operator/tree/main
    ...                Skips installation when the NFS StorageClass already exists:
    ...                shared clusters may pre-provision NFS with a different CR name
    ...                and deploying a second provisioner would conflict with it.
    [Tags]    nfs-operator-deploy
    ${nfs_storage_class_exists} =    Check If StorageClass Exists    storageclass_name=${NFS_STORAGE_CLASS_NAME}
    IF    not ${nfs_storage_class_exists}
          Install NFS Operator Via Cli
          Deploy NFS Provisioner    ${STORAGE_SIZE}    ${NFS_PROVISIONER_NAME}
    ELSE
          Log To Console    message=NFS StorageClass ${NFS_STORAGE_CLASS_NAME} already exists, skipping NFS operator installation
    END
    Verify NFS Storage Class    storageclass_name=${NFS_STORAGE_CLASS_NAME}
