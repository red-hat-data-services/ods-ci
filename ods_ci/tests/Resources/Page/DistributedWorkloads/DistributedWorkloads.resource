*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process


*** Variables ***
${VIRTUAL_ENV_NAME}    venv3.9
${CODEFLARE-SDK-API_URL}            %{CODEFLARE-SDK-API_URL=https://api.github.com/repos/project-codeflare/codeflare-sdk/releases/latest}
${CODEFLARE-SDK_DIR}    codeflare-sdk-upgrade
${CODEFLARE-SDK_REPO_URL}    %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}


*** Keywords ***
Clone Git Repository
    [Documentation]   Clone Git repository
    [Arguments]    ${DW_REPO_URL}    ${DW_REPO_BRANCH}    ${DW_DIR}
    ${result} =    Run Process    git clone -b ${DW_REPO_BRANCH} ${DW_REPO_URL} ${DW_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone DW repo ${DW_REPO_URL}:${DW_REPO_BRANCH}:${DW_DIR}
    END

Run Codeflare Upgrade Tests
    [Documentation]   Run codeflare upgrade tests by cloning codeflare-sdk repo
    [Arguments]    ${TEST_NAME}
    ${latest_tag} =    Run Process   curl -s "${CODEFLARE-SDK-API_URL}" | grep '"tag_name":' | cut -d '"' -f 4
    ...    shell=True    stderr=STDOUT
    Log To Console  codeflare-sdk latest tag is : ${latest_tag.stdout}
    IF    ${latest_tag.rc} != 0
        FAIL    Unable to fetch codeflare-sdk latest tag
    END

    Clone Git Repository    ${CODEFLARE-SDK_REPO_URL}    ${latest_tag.stdout}    ${CODEFLARE-SDK_DIR}

    ${result} =    Run Process  virtualenv -p python3.9 ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to setup Python virtual environment
    END

    ${result} =    Run Process  source ${VIRTUAL_ENV_NAME}/bin/activate && cd ${CODEFLARE-SDK_DIR} && poetry env use 3.9 && poetry install --with test,docs && poetry run pytest -v -s ./tests/upgrade/raycluster_sdk_upgrade_test.py::${TEST_NAME} --timeout\=300 && deactivate
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running test ${TEST_NAME} failed
    END

Codeflare Upgrade Tests Teardown
    [Documentation]   Run codeflare upgrade tests by cloning codeflare-sdk repo
    [Arguments]    ${project_name}    ${project_created}
    IF    ${project_created} == True    Run Keywords
    ...    Run   oc delete project ${project_name}    AND
    ...    Run Process    oc delete LocalQueue local-queue-mnist -n ${project_name} &
    ...    oc delete ClusterQueue cluster-queue-mnist &
    ...    oc delete ResourceFlavor default-flavor-mnist    shell=True

Cleanup Codeflare Setup
    [Documentation]   cleanup codeflare repository cloned and python setup
    ${result} =    Run Process  rm -rf ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Unable to cleanup Python virtual environment
    END

    ${result} =    Run Process  rm -rf ${CODEFLARE-SDK_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Unable to cleanup directory ${CODEFLARE-SDK_DIR}
    END

Restart Kueue
    Log To Console    "Rollout restart kueue-controller-manager"
    ${result} =    Run Process    oc rollout restart deployment/kueue-controller-manager -n ${APPLICATIONS_NAMESPACE}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to restart Kueue
    END

    Log To Console    "Wait for kueue-controller-manager rollout to finish"
    ${result} =    Run Process    oc rollout status deployment/kueue-controller-manager -w -n ${APPLICATIONS_NAMESPACE}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to finish Kueue rollout
    END
