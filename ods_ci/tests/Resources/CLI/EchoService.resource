*** Settings ***
Documentation       Deploy and manage echo service for service token auth testing
Library             OperatingSystem
Resource            ../Common.robot


*** Variables ***
${ECHO_RESOURCES_DIRPATH}=    tests/Resources/Files/echo-service
${ECHO_DEPLOYMENT_TEMPLATE}=    ${ECHO_RESOURCES_DIRPATH}/echo-deployment.yaml.template
${ECHO_DEPLOYMENT_FILLED}=    ${ECHO_RESOURCES_DIRPATH}/echo-deployment-filled.yaml
${ECHO_HTTPROUTE_FILEPATH}=    ${ECHO_RESOURCES_DIRPATH}/echo-httproute.yaml
${ECHO_SA_FILEPATH}=    ${ECHO_RESOURCES_DIRPATH}/test-serviceaccount.yaml
${ECHO_SA_RBAC_FILEPATH}=    ${ECHO_RESOURCES_DIRPATH}/test-serviceaccount-rbac.yaml
${KUBE_RBAC_PROXY_IMAGE}=    registry.redhat.io/openshift4/ose-kube-rbac-proxy-rhel9:latest
${ECHO_SERVER_IMAGE}=    ealen/echo-server:latest


*** Keywords ***
Deploy Echo Service
    [Documentation]    Deploys echo service pod and service for testing
    [Arguments]    ${namespace}=opendatahub
    Log    message=Deploying echo service in ${namespace} namespace
    Create File From Template    ${ECHO_DEPLOYMENT_TEMPLATE}    ${ECHO_DEPLOYMENT_FILLED}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${ECHO_DEPLOYMENT_FILLED} -n ${namespace}
    Should Be Equal As Integers    ${rc}    0
    Wait For Pods To Be Ready    label_selector=app=echo-service
    ...    namespace=${namespace}
    Log    message=Echo service deployed successfully

Create Test Service Account
    [Documentation]    Creates a test service account for token authentication with RBAC permissions
    [Arguments]    ${namespace}=opendatahub
    ${rc}    ${sa_out}=    Run And Return Rc And Output
    ...    oc apply -f ${ECHO_SA_FILEPATH} -n ${namespace}
    Should Be Equal As Integers    ${rc}    0
    ${rc}    ${rbac_out}=    Run And Return Rc And Output
    ...    oc apply -f ${ECHO_SA_RBAC_FILEPATH} -n ${namespace}
    Should Be Equal As Integers    ${rc}    0
    Log    message=Test service account and RBAC created in ${namespace}

Create HTTPRoute For Echo Service
    [Documentation]    Creates Gateway API HTTPRoute to expose echo service through gateway
    [Arguments]    ${namespace}=opendatahub
    Log    message=Creating HTTPRoute for echo service
    ${rc}    ${route_out}=    Run And Return Rc And Output
    ...    oc apply -f ${ECHO_HTTPROUTE_FILEPATH} -n ${namespace}
    Should Be Equal As Integers    ${rc}    0
    Log    message=HTTPRoute created, waiting for acceptance
    Wait For HTTPRoute To Be Accepted    echo-service-route    ${namespace}    timeout=60s
    Log    message=HTTPRoute accepted and ready

Wait For HTTPRoute To Be Accepted
    [Documentation]    Waits for HTTPRoute to be accepted by the gateway
    [Arguments]    ${route_name}    ${namespace}    ${timeout}=60s
    Wait Until Keyword Succeeds    ${timeout}    5s    HTTPRoute Is Accepted    ${route_name}    ${namespace}

HTTPRoute Is Accepted
    [Documentation]    Checks if HTTPRoute has Accepted condition set to True
    [Arguments]    ${route_name}    ${namespace}
    ${rc}    ${status}=    Run And Return Rc And Output
    ...    oc get httproute ${route_name} -n ${namespace}
    ...    -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}'    # robocop: disable=line-too-long
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal As Strings    ${status}    True
    Log    message=HTTPRoute ${route_name} is accepted

Get Gateway URL
    [Documentation]    Gets the gateway hostname from the Gateway resource
    ${rc}    ${url}=    Run And Return Rc And Output
    ...    oc get gateway data-science-gateway -n openshift-ingress -o jsonpath='{.status.addresses[0].value}'
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${url}

Remove Echo Service
    [Documentation]    Removes echo service deployment and related resources
    [Arguments]    ${namespace}=opendatahub
    Log    message=Removing echo service resources from ${namespace}
    Create File From Template    ${ECHO_DEPLOYMENT_TEMPLATE}    ${ECHO_DEPLOYMENT_FILLED}
    Run And Return Rc And Output
    ...    oc delete httproute echo-service-route -n ${namespace} --ignore-not-found=true
    Run And Return Rc And Output
    ...    oc delete clusterrolebinding echo-service-tokenreview --ignore-not-found=true
    Run And Return Rc And Output
    ...    oc delete -f ${ECHO_DEPLOYMENT_FILLED} -n ${namespace} --ignore-not-found=true
    Run And Return Rc And Output
    ...    oc delete -f ${ECHO_SA_RBAC_FILEPATH} -n ${namespace} --ignore-not-found=true
    Run And Return Rc And Output
    ...    oc delete -f ${ECHO_SA_FILEPATH} -n ${namespace} --ignore-not-found=true
    Log    message=Echo service resources removed
