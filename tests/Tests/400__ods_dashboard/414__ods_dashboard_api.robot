*** Settings ***
Documentation     Suite for a basic security test of Dashboard APIs. The tests verifies that user
...               reach endpoints based on their user permissions
Library           OpenShiftLibrary
Library           SeleniumLibrary
Resource          ../../Resources/Common.robot
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboardAPI.resource
Resource          ../../Resources/Page/ODH/AiApps/Rhosak.resource
Suite Setup       Endpoint Testing Setup
Suite Teardown    Endpoint Testing Teardown


*** Variables ***
${CLUSTER_SETTINGS_ENDPOINT}=        api/cluster-settings
${CLUSTER_SETTINGS_ENDPOINT_BODY}=   {"userTrackingEnabled":true}

${BUILDS_ENDPOINT}=        api/builds
${BUILDS_ENDPOINT_BODY}=   {"name":"CUDA","status":"Running"}

${CONFIG_ENDPOINT}=        api/config
${CONFIG_ENDPOINT_BODY}=   {"spec":{"dashboardConfig":{"disableTracking":false}}}

${CONSOLE_LINKS_ENDPOINT}=        api/console-links
${DOCS_ENDPOINT}=        api/docs
${GETTING_STARTED_ENDPOINT}=        api/getting-started
${QUICKSTARTS_ENDPOINT}=        api/quickstarts
${SEGMENT_KEY_ENDPOINT}=        api/segment-key
${GPU_ENDPOINT}=        api/gpu

${NOTEBOOK_NS}=          rhods-notebooks
${DASHBOARD_NS}=         redhat-ods-applications
${NOTEBOOK_USERNAME}=    ""
${CM_ENDPOINT_PT0}=         api/configmaps
${CM_ENDPOINT_PT1}=         ${CM_ENDPOINT_PT0}/${NOTEBOOK_NS}/jupyterhub-singleuser-profile-
${CM_ENDPOINT_PT2}=         -envs
${CM_ENDPOINT_BODY}=            {"kind":"ConfigMap","apiVersion":"v1","metadata":{"name":"jupyterhub-singleuser-profile-<NB_USERNAME>-envs","namespace":"rhods-notebooks"}}
${DUMMY_CM_NAME}=           test-dummy-configmap
${CM_DASHBOARD_ENDPOINT}=         api/configmaps/${DASHBOARD_NS}/${DUMMY_CM_NAME}
${CM_DASHBOARD_ENDPOINT_BODY}=         {"kind":"ConfigMap","apiVersion":"v1","metadata":{"name":"${DUMMY_CM_NAME}","namespace":"${DASHBOARD_NS}"},"data":{"key":"newvalue"}}
${CM_OUTSIDE_DASHBOARD_ENDPOINT_BODY}=         {"kind":"ConfigMap","apiVersion":"v1","metadata":{"name":"${DUMMY_CM_NAME}","namespace":"redhat-ods-monitoring"},"data":{"key":"newvalue"}}
${CM_OUTSIDE_DASHBOARD_ENDPOINT}=         api/configmaps/redhat-ods-monitoring/prometheus
${DUMMY_SECRET_NAME}=           test-dummy-secret
${SECRET_DASHBOARD_ENDPOINT}=         api/secrets/${DASHBOARD_NS}/${DUMMY_SECRET_NAME}
${SECRET_OUTSIDE_DASHBOARD_ENDPOINT}=         api/secrets/redhat-ods-monitoring/${DUMMY_SECRET_NAME}
${SECRET_ENDPOINT_PT0}=         api/secrets
${SECRET_ENDPOINT_PT1}=         ${SECRET_ENDPOINT_PT0}/${NOTEBOOK_NS}/jupyterhub-singleuser-profile-
${SECRET_ENDPOINT_PT2}=         -envs
${SECRET_ENDPOINT_BODY}=        {"kind":"Secret","apiVersion":"v1","metadata":{"name":"jupyterhub-singleuser-profile-<NB_USERNAME>-envs","namespace":"rhods-notebooks"},"type":"Opaque"}
${SECRET_DASHBOARD_ENDPOINT_BODY}=        {"kind":"Secret","apiVersion":"v1","metadata":{"name":"${DUMMY_SECRET_NAME}","namespace":"${DASHBOARD_NS}"},"type":"Opaque"}
${SECRET_OUTSIDE_DASHBOARD_ENDPOINT_BODY}=        {"kind":"Secret","apiVersion":"v1","metadata":{"name":"${DUMMY_SECRET_NAME}","namespace":"redhat-ods-monitoring"},"type":"Opaque"}

${GROUPS_CONFIG_ENDPOINT}=        api/groups-config

${IMG_NAME}=            custom-test-image
${IMG_URL}=             quay.io/thoth-station/s2i-lab-elyra:v0.1.1
${IMG_DESCRIPTION}=     Testing Only This image is only for illustration purposes, and comes with no support. Do not use.
&{IMG_SOFTWARE}=        Software1=x.y.z
&{IMG_PACKAGES}=        elyra=2.2.4    foo-pkg=a.b.c
${IMG_ENDPOINT_PT0}=        api/images
${IMG_ENDPOINT_PT1}=        byon
${IMG_ENDPOINT_BODY}=        {"name":"Test-Byon-Image","description":"","packages":[],"software":[],"url":"test-url"}

${NB_EVENTS_ENDPOINT_PT0}=      api/nb-events
${NB_EVENTS_ENDPOINT_PT1}=      ${NB_EVENTS_ENDPOINT_PT0}/${NOTEBOOK_NS}/

${STATUS_ENDPOINT_PT0}=      api/status
${STATUS_ENDPOINT_PT1}=      ${STATUS_ENDPOINT_PT0}/${DASHBOARD_NS}/allowedUsers

${VALIDATE_ISV_ENDPOINT}=       api/validate-isv?appName=anaconda-ce&values={"Anaconda_ce_key":"wrong-key"}
${VALIDATE_ISV_RESULT_ENDPOINT}=         api/validate-isv/results?appName=anaconda-ce

${NB_ENDPOINT_PT0}=      api/notebooks
${NB_ENDPOINT_PT1}=      ${NB_ENDPOINT_PT0}/${NOTEBOOK_NS}/
${NB_ENDPOINT_PT2}=      /status
${NB_ENDPOINT_BODY}=      {"apiVersion":"kubeflow.org/v1","kind":"Notebook","metadata":{"labels":{"app":"jupyter-nb-<NB_USERNAME>","opendatahub.io/odh-managed":"true","opendatahub.io/user":"<NB_USERNAME>"},"name":"jupyter-nb-<NB_USERNAME>","namespace":"rhods-notebooks"},"spec":{"template":{"spec":{"enableServiceLinks":false,"containers":[{"image":"image-registry.openshift-image-registry.svc:5000/${DASHBOARD_NS}/s2i-minimal-notebook:py3.8-1.16.0-hotfix-2fada07","imagePullPolicy":"Always","workingDir":"/opt/app-root/src","name":"jupyter-nb-<NB_USERNAME>","env":[{"name":"JUPYTER_IMAGE","value":"image-registry.openshift-image-registry.svc:5000/${DASHBOARD_NS}/s2i-minimal-notebook:py3.8-1.16.0-hotfix-2fada07"}],"resources":{"limits":{"cpu":"2","memory":"8Gi"},"requests":{"cpu":"1","memory":"8Gi"}},"volumeMounts":[{"mountPath":"/opt/app-root/src","name":"jupyterhub-nb-<NB_USERNAME>-pvc"}],"ports":[{"name":"notebook-port","containerPort":8888,"protocol":"TCP"}]}],"volumes":[{"name":"jupyterhub-nb-<NB_USERNAME>-pvc","persistentVolumeClaim":{"claimName":"jupyterhub-nb-<NB_USERNAME>-pvc"}}]}}}}

${PVC_ENDPOINT_PT0}=      api/pvc
${PVC_ENDPOINT_PT1}=      ${PVC_ENDPOINT_PT0}/${NOTEBOOK_NS}/
${PVC_ENDPOINT_BODY}=     {"apiVersion":"v1","kind":"PersistentVolumeClaim","metadata":{"name":"<PVC_NAME>","namespace":"rhods-notebooks"},"spec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"2Gi"}},"volumeMode":"Filesystem"},"status":{"phase":"Pending"}}

${ROLE_BIND_ENDPOINT_PT0}=      api/rolebindings
${ROLE_BIND_ENDPOINT_PT1}=      ${ROLE_BIND_ENDPOINT_PT0}/${DASHBOARD_NS}/${NOTEBOOK_NS}-image-pullers
${ROLE_BIND_ENDPOINT_BODY}=      {"kind":"RoleBinding","apiVersion":"rbac.authorization.k8s.io/v1","metadata":{"name":"rhods-notebooks-image-pullers-test","namespace":"${DASHBOARD_NS}"},"subjects":[{"kind":"Group","apiGroup":"rbac.authorization.k8s.io","name":"system:serviceaccounts:rhods-notebooks"}],"roleRef":{"apiGroup":"rbac.authorization.k8s.io","kind":"ClusterRole","name":"system:image-puller"}}

${APP_TO_REMOVE}=                rhosak
${COMPONENTS_ENDPOINT_PT0}=      api/components
${COMPONENTS_ENDPOINT_PT1}=      ${COMPONENTS_ENDPOINT_PT0}/remove?appName=${APP_TO_REMOVE}

${HEALTH_ENDPOINT}=     api/health

*** Test Cases ***
Verify Access To cluster-settings API Endpoint
    [Documentation]     Verifies the endpoint "cluster-settings" works as expected
    ...                 based on the permissions of the users who query the endpoint
    [Tags]    ODS-1709
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint GET Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PUT Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    ...                                       body=${CLUSTER_SETTINGS_ENDPOINT_BODY}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint PUT Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${ADMIN_TOKEN}
    ...                                       body=${CLUSTER_SETTINGS_ENDPOINT_BODY}
    Operation Should Be Allowed

Verify Access To builds API Endpoint
    [Documentation]     Verifies the endpoint "builds" works as expected
    ...                 based on the permissions of the users who query the endpoint

    [Tags]    ODS-1711
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${BUILDS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${BUILDS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To config API Endpoint
    [Documentation]     Verifies the endpoint "config" works as expected
    ...                 based on the permissions of the users who query the endpoint

    [Tags]    ODS-1712
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${CONFIG_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${CONFIG_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PATCH Call    endpoint=${CONFIG_ENDPOINT}    token=${BASIC_USER_TOKEN}
    ...                                          body=${CONFIG_ENDPOINT_BODY}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint PATCH Call    endpoint=${CONFIG_ENDPOINT}    token=${ADMIN_TOKEN}
    ...                                          body=${CONFIG_ENDPOINT_BODY}
    Operation Should Be Allowed

Verify Access To console-links API Endpoint
    [Documentation]     Verifies the endpoint "console-links" works as expected
    ...                 based on the permissions of the users who query the endpoint

    [Tags]    ODS-1713
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${CONSOLE_LINKS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${CONSOLE_LINKS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To docs API Endpoint
    [Documentation]     Verifies the endpoint "docs" works as expected
    ...                 based on the permissions of the user who query the endpoint

    [Tags]    ODS-1714
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${DOCS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${DOCS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To getting-started API Endpoint
    [Documentation]     Verifies the endpoint "getting_started" works as expected
    ...                 based on the permissions of the users who query the endpoint

    [Tags]    ODS-1715
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${GETTING_STARTED_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${GETTING_STARTED_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To quickstarts API Endpoint
    [Documentation]     Verifies the endpoint "quickstarts" works as expected
    ...                 based on the permissions of the users who query the endpoint

    [Tags]    ODS-1716
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${QUICKSTARTS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${QUICKSTARTS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To segment-key API Endpoint
    [Documentation]     Verifies the endpoint "segment-key" works as expected
    ...                 based on the permissions of the users who query the endpoint

    [Tags]    ODS-1717
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${SEGMENT_KEY_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${SEGMENT_KEY_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To gpu API Endpoint
    [Documentation]     Verifies the endpoint "gpu" works as expected
    ...                 based on the permissions of the users who query the endpoint

    [Tags]    ODS-1718
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${GPU_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${GPU_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To pvc API Endpoint
    [Documentation]     Verifies the endpoint "pvc" works as expected
    ...                 based on the permissions of the users who query the endpoint to get/create PVCs
    ...                 The syntax to reach this endpoint is:
    ...                 `pvc/<notebook_namespace>/jupyter-nb-<username_nb>`
    [Tags]    ODS-1728
    ...       Tier1    Sanity
    ...       Security
    ${PVC_BASIC_USER}=   Get User Notebook PVC Name    ${TEST_USER_3.USERNAME}
    ${PVC_ENDPOINT_BASIC_USER}=     Set Variable    ${PVC_ENDPOINT_PT1}${PVC_BASIC_USER}
    ${create_pvc_body}=     Set Username In PVC Payload     username=${PVC_BASIC_USER}
    Perform Dashboard API Endpoint POST Call   endpoint=${PVC_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                        body=${create_pvc_body}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${PVC_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${PVC_ENDPOINT_BASIC_USER}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    ${PVC_BASIC_USER_2}=   Get User Notebook PVC Name    ${TEST_USER_4.USERNAME}
    ${PVC_ENDPOINT_BASIC_USER_2}=     Set Variable    ${PVC_ENDPOINT_PT1}${PVC_BASIC_USER_2}
    ${create_pvc_body_2}=     Set Username In PVC Payload     username=${PVC_BASIC_USER_2}
    Perform Dashboard API Endpoint POST Call   endpoint=${PVC_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                        body=${create_pvc_body_2}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${PVC_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                        body=${create_pvc_body_2}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${PVC_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${PVC_ENDPOINT_BASIC_USER_2}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    ${test_pvcs}=   Create List     ${PVC_BASIC_USER}   ${PVC_BASIC_USER_2}
    [Teardown]    Delete Test PVCs     pvc_names=${test_pvcs}

Verify Access To Notebook configmaps API Endpoint
    [Documentation]     Verifies the endpoint "configmaps" works as expected
    ...                 based on the permissions of the users who query the endpoint to get
    ...                 the user configmap map of a notebook server.
    ...                 The syntax to reach this endpoint is:
    ...                 `configmaps/<notebook_namespace>/jupyterhub-singleuser-profile-{username}-envs`

    [Tags]    ODS-1719
    ...       Tier1    Sanity
    ...       Security
    Spawn Minimal Python Notebook Server     username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ${NOTEBOOK_BASIC_USER}=   Get Safe Username    ${TEST_USER_3.USERNAME}
    ${CM_ENDPOINT_BASIC_USER}=     Set Variable    ${CM_ENDPOINT_PT1}${NOTEBOOK_BASIC_USER}${CM_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_ENDPOINT_BASIC_USER}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    ${cm_basic_user_body}=     Set Username In ConfigMap Payload    notebook_username=${NOTEBOOK_BASIC_USER}
    Perform Dashboard API Endpoint PUT Call   endpoint=${CM_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${cm_basic_user_body}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint DELETE Call   endpoint=${CM_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint POST Call   endpoint=${CM_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${cm_basic_user_body}
    Operation Should Be Allowed
    Spawn Minimal Python Notebook Server     username=${TEST_USER_4.USERNAME}    password=${TEST_USER_4.PASSWORD}
    ${NOTEBOOK_BASIC_USER_2}=   Get Safe Username    ${TEST_USER_4.USERNAME}
    ${CM_ENDPOINT_BASIC_USER_2}=     Set Variable    ${CM_ENDPOINT_PT1}${NOTEBOOK_BASIC_USER_2}${CM_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    ${cm_basic_user_2_body}=     Set Username In ConfigMap Payload    notebook_username=${NOTEBOOK_BASIC_USER_2}
    Perform Dashboard API Endpoint PUT Call   endpoint=${CM_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${cm_basic_user_2_body}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PUT Call   endpoint=${CM_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                       body=${cm_basic_user_2_body}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint DELETE Call   endpoint=${CM_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${CM_ENDPOINT_BASIC_USER_2}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint POST Call   endpoint=${CM_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${cm_basic_user_2_body}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${CM_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                       body=${cm_basic_user_2_body}
    Operation Should Be Allowed
    [Teardown]     Delete Test Notebooks CRs And PVCs From CLI

Verify Access To Notebook secrets API Endpoint
    [Documentation]     Verifies the endpoint "secrets" works as expected
    ...                 based on the permissions of the users who query the endpoint to get
    ...                 the user secret of a notebook server.
    ...                 The syntax to reach this endpoint is:
    ...                 `secrets/<notebook_namespace>/jupyterhub-singleuser-profile-{username}-envs`

    [Tags]    ODS-1720
    ...       Tier1    Sanity
    ...       Security
    Spawn Minimal Python Notebook Server     username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ${NOTEBOOK_BASIC_USER}=   Get Safe Username    ${TEST_USER_3.USERNAME}
    ${SECRET_ENDPOINT_BASIC_USER}=     Set Variable    ${SECRET_ENDPOINT_PT1}${NOTEBOOK_BASIC_USER}${SECRET_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_ENDPOINT_BASIC_USER}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    ${secret_basic_user_body}=     Set Username In Secret Payload    notebook_username=${NOTEBOOK_BASIC_USER}
    Perform Dashboard API Endpoint PUT Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${secret_basic_user_body}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint POST Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${secret_basic_user_body}
    Operation Should Be Allowed
    Spawn Minimal Python Notebook Server     username=${TEST_USER_4.USERNAME}    password=${TEST_USER_4.PASSWORD}
    ${NOTEBOOK_BASIC_USER_2}=   Get Safe Username    ${TEST_USER_4.USERNAME}
    ${SECRET_ENDPOINT_BASIC_USER_2}=     Set Variable    ${SECRET_ENDPOINT_PT1}${NOTEBOOK_BASIC_USER_2}${SECRET_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    ${secret_basic_user_2_body}=     Set Username In Secret Payload    notebook_username=${NOTEBOOK_BASIC_USER_2}
    Perform Dashboard API Endpoint PUT Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${secret_basic_user_2_body}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PUT Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                       body=${secret_basic_user_2_body}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_ENDPOINT_BASIC_USER_2}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint POST Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${secret_basic_user_2_body}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                       body=${secret_basic_user_2_body}
    Operation Should Be Allowed
    [Teardown]     Delete Test Notebooks CRs And PVCs From CLI

Verify Access To Dashboard configmaps API Endpoint
    [Documentation]     Verifies the endpoint "configmaps" works as expected
    ...                 based on the permissions of the users who query the endpoint
    ...                 to get a configmap from the Dashboard namespace.
    ...                 The syntax to reach this endpoint is:
    ...                 `configmaps/<dashboard_namespace>/<configmap_name>`
    [Tags]    ODS-1722
    ...       Tier1    Sanity
    ...       Security
    Create A Dummy ConfigMap In Dashboard Namespace
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PUT Call   endpoint=${CM_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${CM_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PUT Call   endpoint=${CM_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                       body=${CM_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint DELETE Call   endpoint=${CM_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${CM_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint POST Call   endpoint=${CM_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                        body=${CM_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${CM_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                        body=${CM_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Allowed
    Create A Dummy ConfigMap Outside Dashboard Namespace
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_OUTSIDE_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_OUTSIDE_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PUT Call   endpoint=${CM_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${CM_OUTSIDE_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PUT Call   endpoint=${CM_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                       body=${CM_OUTSIDE_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${CM_OUTSIDE_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${CM_OUTSIDE_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${CM_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                        body=${CM_OUTSIDE_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${CM_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                        body=${CM_OUTSIDE_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    [Teardown]      Delete Dummy ConfigMaps

Verify Access To Dashboard secrets API Endpoint
    [Documentation]     Verifies the endpoint "secrets" works as expected
    ...                 based on the permissions of the users who query the endpoint
    ...                 to get a secret from the Dashboard namespace.
    ...                 The syntax to reach this endpoint is:
    ...                 `secrets/<namespace>/<secret_name>`
    [Tags]    ODS-1721
    ...       Tier1    Sanity
    ...       Security
    Create A Dummy Secret In Dashboard Namespace
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PUT Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${SECRET_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PUT Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                       body=${SECRET_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint POST Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                        body=${SECRET_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                        body=${SECRET_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Allowed

    Create A Dummy Secret Outside Dashboard Namespace
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_OUTSIDE_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_OUTSIDE_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PUT Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${SECRET_OUTSIDE_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PUT Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                       body=${SECRET_OUTSIDE_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_OUTSIDE_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_OUTSIDE_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                        body=${SECRET_OUTSIDE_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${SECRET_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                        body=${SECRET_OUTSIDE_DASHBOARD_ENDPOINT_BODY}
    Operation Should Be Forbidden

    [Teardown]      Delete Dummy Secrets

Verify Access To groups-config API Endpoint
    [Documentation]     Verifies the endpoint "groups-config" works as expected
    ...                 based on the permissions of the users who query the endpoint

    [Tags]    ODS-1723
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${GROUPS_CONFIG_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Unauthorized
    ${current_config}=    Perform Dashboard API Endpoint GET Call   endpoint=${GROUPS_CONFIG_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PUT Call   endpoint=${GROUPS_CONFIG_ENDPOINT}    token=${BASIC_USER_TOKEN}
    ...                                       body=${current_config.text}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint PUT Call   endpoint=${GROUPS_CONFIG_ENDPOINT}    token=${ADMIN_TOKEN}
    ...                                       body=${current_config.text}
    Operation Should Be Allowed

Verify Access To images API Endpoint
    [Documentation]     Verifies the endpoint "images" works as expected
    ...                 based on the permissions of the users who query the endpoint

    [Tags]    ODS-1724
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint POST Call   endpoint=${IMG_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                       body=${IMG_ENDPOINT_BODY}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint POST Call   endpoint=${IMG_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                       body=${IMG_ENDPOINT_BODY}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${IMG_ENDPOINT_PT0}/${IMG_ENDPOINT_PT1}   token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    ${current_images}=    Perform Dashboard API Endpoint GET Call   endpoint=${IMG_ENDPOINT_PT0}/${IMG_ENDPOINT_PT1}    token=${ADMIN_TOKEN}
    Log         ${current_images.json()}
    ${image_id}=    Set Variable         ${current_images.json()[0]['id']}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PUT Call   endpoint=${IMG_ENDPOINT_PT0}/${image_id}    token=${BASIC_USER_TOKEN}
    ...                                       body=${current_images.json()[0]}  str_to_json=${FALSE}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint PUT Call   endpoint=${IMG_ENDPOINT_PT0}/${image_id}    token=${ADMIN_TOKEN}
    ...                                       body=${current_images.json()[0]}  str_to_json=${FALSE}
    Perform Dashboard API Endpoint DELETE Call   endpoint=${IMG_ENDPOINT_PT0}/${image_id}    token=${BASIC_USER_TOKEN}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint DELETE Call   endpoint=${IMG_ENDPOINT_PT0}/${image_id}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To nb-events API Endpoint
    [Documentation]     Verifies the endpoint "nb-events" works as expected
    ...                 based on the permissions of the users who query the endpoint to get
    ...                 the events from user notebook
    ...                 The syntax to reach this endpoint is:
    ...                 `nb-events/<notebook_namespace>/jupyter-nb-<username_nb>`
    ...                 ProductBug: RHODS-5204
    [Tags]    ODS-1725
    ...       Tier1    Sanity
    ...       Security
    ...       ProductBug
    Spawn Minimal Python Notebook Server     username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ${NB_PODNAME_BASIC_USER}=   Get User CR Notebook Name    ${TEST_USER_3.USERNAME}
    ${NB_EVENTS_ENDPOINT_BASIC_USER}=     Set Variable    ${NB_EVENTS_ENDPOINT_PT1}${NB_PODNAME_BASIC_USER}
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_EVENTS_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_EVENTS_ENDPOINT_BASIC_USER}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Spawn Minimal Python Notebook Server     username=${TEST_USER_4.USERNAME}    password=${TEST_USER_4.PASSWORD}
    ${NB_PODNAME_BASIC_USER_2}=   Get User CR Notebook Name    ${TEST_USER_4.USERNAME}
    ${NB_EVENTS_ENDPOINT_BASIC_USER_2}=     Set Variable    ${NB_EVENTS_ENDPOINT_PT1}${NB_PODNAME_BASIC_USER_2}
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_EVENTS_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_EVENTS_ENDPOINT_PT1}    token=${BASIC_USER_TOKEN}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_EVENTS_ENDPOINT_PT1}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    [Teardown]     Delete Test Notebooks CRs And PVCs From CLI

Verify Access To status API Endpoint
    [Documentation]     Verifies the endpoint "status" works as expected
    ...                 based on the permissions of the users
    [Tags]    ODS-1726
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${STATUS_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${STATUS_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint POST Call   endpoint=${STATUS_ENDPOINT_PT1}    token=${BASIC_USER_TOKEN}
    ...                                        body=${EMPTY}    str_to_json=${FALSE}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint POST Call   endpoint=${STATUS_ENDPOINT_PT1}    token=${ADMIN_TOKEN}
    ...                                        body=${EMPTY}    str_to_json=${FALSE}
    Operation Should Be Allowed

Verify Access To validate-isv API Endpoint
    [Documentation]     Verifies the endpoint "validate-isv" works as expected
    ...                 based on the permissions of the users
    [Tags]    ODS-1727
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${VALIDATE_ISV_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${VALIDATE_ISV_RESULT_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${VALIDATE_ISV_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${VALIDATE_ISV_RESULT_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed

Verify Access to notebooks API Endpoint
    [Documentation]     Verifies the endpoint "notebooks" works as expected
    ...                 based on the permissions of the users who query the endpoint to get
    ...                 the user notebook CR.
    ...                 The syntax to reach this endpoint is:
    ...                 `notebooks/<notebook_namespace>/jupyter-nb-<username_nb>`
    ...                 ProductBug: RHODS-5204
    [Tags]    ODS-1729
    ...       Tier1    Sanity
    ...       Security
    ...       ProductBug
    Spawn Minimal Python Notebook Server     username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ${NB_BASIC_USER}=   Get User CR Notebook Name    ${TEST_USER_3.USERNAME}
    ${NB_ENDPOINT_BASIC_USER}=     Set Variable    ${NB_ENDPOINT_PT1}${NB_BASIC_USER}
    ${NB_ENDPOINT_BASIC_USER_STATUS}=     Set Variable    ${NB_ENDPOINT_BASIC_USER}${NB_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_ENDPOINT_BASIC_USER}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_ENDPOINT_BASIC_USER_STATUS}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_ENDPOINT_BASIC_USER_STATUS}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    ${NOTEBOOK_BASIC_USER}=   Get Safe Username    ${TEST_USER_3.USERNAME}
    ${NB_ENDPOINT_BASIC_USER_BODY}=       Set Username In Notebook Payload    notebook_username=${NOTEBOOK_BASIC_USER}
    Perform Dashboard API Endpoint PATCH Call   endpoint=${NB_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    ...                                        body=${NB_ENDPOINT_BASIC_USER_BODY}
    Operation Should Be Allowed
    Spawn Minimal Python Notebook Server     username=${TEST_USER_4.USERNAME}    password=${TEST_USER_4.PASSWORD}
    ${NB_BASIC_USER_2}=   Get User CR Notebook Name    ${TEST_USER_4.USERNAME}
    ${NB_ENDPOINT_BASIC_USER_2}=     Set Variable    ${NB_ENDPOINT_PT1}${NB_BASIC_USER_2}
    ${NB_ENDPOINT_BASIC_USER_2_STATUS}=     Set Variable    ${NB_ENDPOINT_BASIC_USER_2}${NB_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_ENDPOINT_BASIC_USER_2_STATUS}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_ENDPOINT_PT1}    token=${BASIC_USER_TOKEN}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint GET Call   endpoint=${NB_ENDPOINT_PT1}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    ${NB_BASIC_USER_2_SAFENAME}=   Get Safe Username    ${TEST_USER_4.USERNAME}
    ${NB_ENDPOINT_BASIC_USER_2_BODY}=       Set Username In Notebook Payload    notebook_username=${NB_BASIC_USER_2_SAFENAME}
    Perform Dashboard API Endpoint PATCH Call   endpoint=${NB_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    ...                                        body=${NB_ENDPOINT_BASIC_USER_2_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PATCH Call   endpoint=${NB_ENDPOINT_BASIC_USER_2}    token=${ADMIN_TOKEN}
    ...                                        body=${NB_ENDPOINT_BASIC_USER_2_BODY}
    Operation Should Be Allowed
    ${NOTEBOOK_BASIC_USER_3}=   Get Safe Username    ${TEST_USER.USERNAME}
    ${NB_ENDPOINT_BASIC_USER_3_BODY}=       Set Username In Notebook Payload    notebook_username=${NOTEBOOK_BASIC_USER_3}
    Perform Dashboard API Endpoint POST Call   endpoint=${NB_ENDPOINT_PT0}/    token=${BASIC_USER_TOKEN}
    ...                                        body=${NB_ENDPOINT_BASIC_USER_3_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${NB_ENDPOINT_PT0}/    token=${ADMIN_TOKEN}
    ...                                        body=${NB_ENDPOINT_BASIC_USER_3_BODY}
    Operation Should Be Allowed     accept_code_500=${TRUE}
    [Teardown]    Delete Test Notebooks CRs And PVCs From CLI

Verify Access to rolebindings API Endpoint
    [Documentation]     Verifies the endpoint "rolebindings" works as expected
    ...                 based on the permissions of the users who query the endpoint
    ...                 The syntax to reach this endpoint is:
    ...                 `rolebindings/<dashboard_namespace>/<notebook_namespace>-image-pullers`
    ...                 ProductBug: RHODS-5204
    [Tags]    ODS-1730
    ...       Tier1    Sanity
    ...       Security
    ...       ProductBug
    Perform Dashboard API Endpoint GET Call   endpoint=${ROLE_BIND_ENDPOINT_PT1}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${ROLE_BIND_ENDPOINT_PT1}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${ROLE_BIND_ENDPOINT_PT0}/${NOTEBOOK_NS}/    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${ROLE_BIND_ENDPOINT_PT0}/${NOTEBOOK_NS}/    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${ROLE_BIND_ENDPOINT_PT0}/${DASHBOARD_NS}/    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${ROLE_BIND_ENDPOINT_PT0}/${DASHBOARD_NS}/    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint POST Call   endpoint=${ROLE_BIND_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    ...                                        body=${ROLE_BIND_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint POST Call   endpoint=${ROLE_BIND_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    ...                                        body=${ROLE_BIND_ENDPOINT_BODY}
    Operation Should Be Allowed
    [Teardown]   OpenshiftLibrary.Oc Delete    kind=RoleBinding  namespace=${DASHBOARD_NS}  name=rhods-notebooks-image-pullers-test

Verify Access To components API Endpoint
    [Documentation]     Verifies the endpoint "components" works as expected
    ...                 based on the permissions of the users who query the endpoint
    ...                 The syntaxes to reach this endpoint are:
    ...                 `components/` and `components/remove?appName=<app_to_remove>`
    [Tags]    ODS-1731
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${COMPONENTS_ENDPOINT_PT0}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${COMPONENTS_ENDPOINT_PT0}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${COMPONENTS_ENDPOINT_PT1}    token=${BASIC_USER_TOKEN}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint GET Call   endpoint=${COMPONENTS_ENDPOINT_PT1}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To health API Endpoint
    [Documentation]     Verifies the endpoint "health" works as expected
    ...                 based on the permissions of the users who query the endpoint
    ...                 The syntaxes to reach this endpoint is:
    ...                 `health/`
    [Tags]    ODS-1752
    ...       Tier1    Sanity
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${HEALTH_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${HEALTH_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed


*** Keywords ***
Endpoint Testing Setup
    [Documentation]     Fetches an access token for both a RHODS admin and basic user
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    ${ADMIN_TOKEN}=   Log In As RHODS Admin
    Set Suite Variable    ${ADMIN_TOKEN}
    ${BASIC_USER_TOKEN}=   Log In As RHODS Basic User
    Set Suite Variable    ${BASIC_USER_TOKEN}

Endpoint Testing Teardown
    [Documentation]     Switches to original OC context
    RHOSi Teardown

Log In As RHODS Admin
    [Documentation]     Perfom OC login using a RHODS admin user
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    ${oauth_proxy_cookie}=     Get OAuth Cookie
    Close Browser
    [Return]    ${oauth_proxy_cookie}

Log In As RHODS Basic User
    [Documentation]     Perfom OC login using a RHODS basic user
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    ${oauth_proxy_cookie}=     Get OAuth Cookie
    Close Browser
    [Return]    ${oauth_proxy_cookie}

Spawn Minimal Python Notebook Server
    [Documentation]    Suite Setup
    [Arguments]       ${username}    ${password}
    Launch Dashboard    ocp_user_name=${username}    ocp_user_pw=${password}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=s2i-minimal-notebook

Create A Dummy Secret In Dashboard Namespace
    [Documentation]     Creates a dummy secret to use in tests to avoid getting sensitive secrets
    # OpenshiftLibrary.Oc Create      kind=Secret    namespace=${DASHBOARD_NS}   src={"data": {"secret_key": "super_dummy_secret"}}
    Run     oc create secret generic ${DUMMY_SECRET_NAME} --from-literal=super_key=super_dummy_secret -n ${DASHBOARD_NS}

Create A Dummy Secret Outside Dashboard Namespace
    [Documentation]     Creates a dummy secret ouside dashboard namespace to use in tests to avoid getting sensitive secrets
    # OpenshiftLibrary.Oc Create      kind=Secret    namespace=${DASHBOARD_NS}   src={"data": {"secret_key": "super_dummy_secret"}}
    Run     oc create secret generic ${DUMMY_SECRET_NAME} --from-literal=super_key=super_dummy_secret -n redhat-ods-monitoring

Create A Dummy ConfigMap In Dashboard Namespace
    [Documentation]     Creates a dummy secret to use in tests to avoid getting sensitive secrets
    # OpenshiftLibrary.Oc Create      kind=Secret    namespace=${DASHBOARD_NS}   src={"data": {"secret_key": "super_dummy_secret"}}
    Run     oc create configmap ${DUMMY_CM_NAME} --from-literal=super_key=super_dummy_cm -n ${DASHBOARD_NS}

Create A Dummy ConfigMap Outside Dashboard Namespace
    [Documentation]     Creates a dummy secret ouside dashboard namespace to use in tests to avoid getting sensitive secrets
    # OpenshiftLibrary.Oc Create      kind=Secret    namespace=${DASHBOARD_NS}   src={"data": {"secret_key": "super_dummy_secret"}}
    Run     oc create configmap ${DUMMY_CM_NAME} --from-literal=super_key=super_dummy_cm -n redhat-ods-monitoring

Delete Dummy Secrets
    [Documentation]     Deletes the dummy secret created during tests
    OpenshiftLibrary.Oc Delete    kind=Secret  namespace=${DASHBOARD_NS}  name=${DUMMY_SECRET_NAME}
    OpenshiftLibrary.Oc Delete    kind=Secret  namespace=redhat-ods-monitoring  name=${DUMMY_SECRET_NAME}

Delete Dummy ConfigMaps
    [Documentation]     Deletes the dummy secret created during tests
    OpenshiftLibrary.Oc Delete    kind=ConfigMap  namespace=${DASHBOARD_NS}  name=${DUMMY_CM_NAME}
    OpenshiftLibrary.Oc Delete    kind=ConfigMap  namespace=redhat-ods-monitoring  name=${DUMMY_CM_NAME}

Delete Test Notebooks CRs And PVCs From CLI
    [Documentation]     Stops all the notebook servers spanwed during a test by
    ...                 deleting their CRs. At the end it closes any opened browsers
    ${CR_1}=   Get User CR Notebook Name    ${TEST_USER_3.USERNAME}
    ${CR_2}=   Get User CR Notebook Name    ${TEST_USER_4.USERNAME}
    ${test_crs}=   Create List     ${CR_1}   ${CR_2}
    FOR   ${nb_cr}    IN  @{test_crs}
        OpenshiftLibrary.Oc Delete    kind=Notebook    namespace=${NOTEBOOK_NS}    name=${nb_cr}
    END
    Close All Browsers
    ${PVC_BASIC_USER}=   Get User Notebook PVC Name    ${TEST_USER_3.USERNAME}
    ${PVC_BASIC_USER_2}=   Get User Notebook PVC Name    ${TEST_USER_4.USERNAME}
    ${test_pvcs}=   Create List     ${PVC_BASIC_USER}   ${PVC_BASIC_USER_2}
    Delete Test PVCs     pvc_names=${test_pvcs}

Set Username In Secret Payload
    [Documentation]     Fill in the json body for creating/updating a Secrets with the username
    [Arguments]     ${notebook_username}
    ${complete_secret}=     Replace String    ${SECRET_ENDPOINT_BODY}    <NB_USERNAME>    ${notebook_username}
    [Return]    ${complete_secret}

Set Username In ConfigMap Payload
    [Documentation]     Fill in the json body for creating/updating a ConfigMaps with the username
    [Arguments]     ${notebook_username}
    ${complete_cm}=     Replace String    ${CM_ENDPOINT_BODY}    <NB_USERNAME>    ${notebook_username}
    [Return]    ${complete_cm}

Set Username In PVC Payload
    [Documentation]     Fill in the json body for creating/updating a PVCs with the username
    [Arguments]     ${username}
    ${complete_pvc}=     Replace String    ${PVC_ENDPOINT_BODY}    <PVC_NAME>    ${username}
    [Return]    ${complete_pvc}

Set Username In Notebook Payload
    [Documentation]     Fill in the json body for creating/updating a Notebook with the username
    [Arguments]     ${notebook_username}
    ${complete_pvc}=     Replace String    ${NB_ENDPOINT_BODY}    <NB_USERNAME>    ${notebook_username}
    [Return]    ${complete_pvc}

Delete Test PVCs
    [Documentation]     Delets the PVCs received as arguments
    [Arguments]     ${pvc_names}
    FOR   ${pvc}    IN  @{pvc_names}
        OpenshiftLibrary.Oc Delete    kind=PersistentVolumeClaim    namespace=${NOTEBOOK_NS}    name=${pvc}
    END
