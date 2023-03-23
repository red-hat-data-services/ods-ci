*** Keywords ***
 Disconnect Cluster
    Oc Create    kind=ConfigMap    namespace=openshift-config
    ...    src=tasks/Resources/Provisioning/Disconnect/disconnect.yaml
    ...    template_data=${infrastructure_configurations}
    Oc Patch     kind=Image    name=cluster    api_version=config.openshift.io/v1 
    ...    src={"spec":{"additionalTrustedCA":{"name":"registry-config"}}}
    Oc Delete   kind=Secret   name=pull-secret    namespace=openshift-config
    Oc Create    kind=Secret    namespace=openshift-config
    ...    src=tasks/Resources/Provisioning/Disconnect/registry_pull_secret.yaml
    ...    template_data=${infrastructure_configurations}
    Oc Patch     kind=OperatorHub    name=cluster 
    ...    src="spec": {"disableAllDefaultSources": true}
    Oc Apply     kind=ImageContentSourcePolicy    
    ...    src=tasks/Resources/Provisioning/Disconnect/icsp.yaml
