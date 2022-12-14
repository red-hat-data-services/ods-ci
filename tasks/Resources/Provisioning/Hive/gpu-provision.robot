*** Settings ***
Library           OperatingSystem

*** Keywords ***
Create GPU Node In Self Managed AWS Cluster
    Set Log Level    Info
    ${gpu_node} =    Run Process    sh    tasks/Resources/Provisioning/Hive/AWS/provision-gpu.sh

Delete GPU Node In Self Managed AWS Cluster
    ${gpu_nodes} =    Oc Get    kind=Machine    label_selector=machine.openshift.io/instance-type=g4dn.xlarge
    Log    ${gpu_nodes[0]['metadata']['name']}    console=True
    Run And Return Rc    oc annotate machine/${gpu_nodes[0]['metadata']['name']} -n openshift-machine-api machine.openshift.io/cluster-api-delete-machine="true"
    Run And Return Rc    oc adm cordon ${gpu_nodes[0]['metadata']['name']}
    Run And Return Rc    oc adm drain ${gpu_nodes[0]['metadata']['name']} --ignore-daemonsets --delete-local-data
    ${gpu_machineset} =    Oc Get    kind=MachineSet    label_selector=gpu-machineset=true
    Run And Return Rc    oc scale --replicas=0 machineset/${gpu_machineset[0]['metadata']['name']} -n openshift-machine-api

Install GPU Operator on Self Managed Cluster
   [Documentation]  Install GPU operator on Self Managed cluster
   ${gpu_install} =    Run Process    sh    tasks/Resources/Provisioning/GPU/gpu_deploy.sh   shell=yes
   Should Not Contain    ${gpu_install.stdout}    FAIL
   Wait For Pods Status   namespace=nvidia-gpu-operator   timeout=600
