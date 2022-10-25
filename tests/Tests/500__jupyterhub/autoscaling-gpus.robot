*** Settings ***
Documentation    Tests for a scenario in which a gpu machine pool with autoscaling
...              Is present on the cluster. Tests that the spawner shows the correct
...              No. of GPUs available and that autoscaling can be triggered
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Resource         ../../Resources/Page/OCPDashboard/Pods/Pods.robot
Library          JupyterLibrary
Suite Setup      Spawner Suite Setup


*** Variables ***
${NOTEBOOK_IMAGE} =         minimal-gpu


*** Test Cases ***
Verify Number Of Available GPUs Is Correct With Machine Autoscalers
    [Documentation]  Verifies that the number of available GPUs in the
    ...    spawner dropdown is correct; i.e., it should show the maximum
    ...    number of GPUs available in a single node, also taking into account
    ...    nodes that can be autoscaled.
    [Tags]    Tier2    Resources-GPU-Autoscaling
    ...       ODS-XXXX
    ${maxNo} =    Find Max Number Of GPUs In One MachineSet
    ${maxSpawner} =    Fetch Max Number Of GPUs In Spawner Page
    Should Be Equal    ${maxSpawner}    ${maxNo}

Verify Autoscale Can Be Triggered
    [Documentation]    Tries spawning a server requesting 1 GPU, which should
    ...    trigger a node autoscale.
    [Tags]    Tier2    Resources-GPU-Autoscaling
    ...       ODS-XXXX
    Spawn Notebook And Trigger Autoscale
    ${serial} =    Get GPU Serial Number
    ${pod_node} =    Get User Server Node
    Log    ${serial}
    Log    ${pod_node}
    Set Suite Variable    $NODE    ${pod_node}
    End Web Test

Verify Node Is Scaled Down
    [Documentation]    After closing down all servers using gpus the node
    ...    should be scaled down in a reasonable amount of time
    [Tags]    Tier2    Resources-GPU-Autoscaling
    ...       ODS-XXXX
    ${machine_name} =  Run  oc get Node ${NODE} -o json | jq '.metadata.annotations["machine.openshift.io/machine"]' | awk '{split($0, a, "/"); print a[2]}' | sed 's/"//'
    ${machineset_name} =  Run  oc get machine ${machine_name} -n openshift-machine-api -o json | jq '.metadata.ownerReferences[0].name' | sed 's/"//g'
    Wait Until Keyword Succeeds  20 min  30 sec  Verify MachineSet Has Zero Replicas  ${machineset_name}


*** Keywords ***
Spawner Suite Setup
    [Documentation]    Suite Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard

Spawn Notebook And Trigger Autoscale
    [Documentation]    Wrapper keyword to spawn a notebook and trigger the autoscaling
    ...    of the GPU node.
    Select Notebook Image    ${NOTEBOOK_IMAGE}
    Select Container Size    Small
    Set Number Of Required GPUs    1
    Spawn Notebook    spawner_timeout=20 minutes  autoscale=${True}
    Run Keyword And Warn On Failure   Login To Openshift  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
    Maybe Close Popup
    Open New Notebook In Jupyterlab Menu
    Spawned Image Check    ${NOTEBOOK_IMAGE}

Verify MachineSet Has Zero Replicas
    [Documentation]    Verify that a machineset has 0 replicas
    ...    (running nodes).
    [Arguments]    ${machineset_name}
    ${current_replicas} =  Run  oc get MachineSet ${machineset_name} -n openshift-machine-api -o json | jq '.spec.replicas'
    Should Be Equal As Integers  ${current_replicas}  0

# Autoscaler useful oc commands
# ALWAYS USE -n openshift-machine-api

# get all machinesets names
# oc get machinesets -n openshift-machine-api | awk '{split($0,a); print a[1]}'
# First row is "NAME", can throw away

# Number of GPUs available in each node of machine set
# oc get MachineSet mroman-gpu-2hzdv-gpu-worker-us-east-1a -n openshift-machine-api -o json | jq '.metadata.annotations["machine.openshift.io/GPU"]'

# Current number of replicas of the machine set (i.e. running nodes)
# oc get MachineSet mroman-gpu-2hzdv-gpu-worker-us-east-1a -n openshift-machine-api -o json | jq '.spec.replicas'

# Max no. of autoscale replicas
# oc get MachineSet mroman-gpu-2hzdv-gpu-worker-us-east-1a -n openshift-machine-api -o json | jq '.metadata.annotations["machine.openshift.io/cluster-api-autoscaler-node-group-max-size"]'

# Min no. of autoscale replicas
# oc get MachineSet mroman-gpu-2hzdv-gpu-worker-us-east-1a -n openshift-machine-api -o json | jq '.metadata.annotations["machine.openshift.io/cluster-api-autoscaler-node-group-min-size"]'

# Does machineset have autoscaling enabled
# oc get MachineSet mroman-gpu-2hzdv-gpu-worker-us-east-1a -n openshift-machine-api -o json | jq '.metadata.annotations["autoscaling.openshift.io/machineautoscaler"]'
# Any string: yes; empty: no