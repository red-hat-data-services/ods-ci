*** Settings ***
Library             SeleniumLibrary
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/Page/Operators/ISVs.resource
Resource            ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource
Suite Setup          Starburst Enterprise Suite Setup
Suite Teardown       Starburst Enterprise Suite Teardown


*** Variables ***
${OPERATOR_NAME}=     starburst-enterprise-helm-operator-rhmp
${SUBSCRIPTION_NAME}=    starburst-enterprise-helm-operator-rhmp-odsci
${NAMESPACE}=    ods-ci-starburst
${CHANNEL}=    alpha
${CATALOG_SOURCE_NAME}=    redhat-marketplace
${CATALOG_SOURCE_NAMESPACE}=    openshift-marketplace
${SEP_ROUTE_NAME}=    web-ui
${SEP_DISPLAYED_NAME}=    Starburst Enterprise
${DS_PROJECT_NAME}=    ds-sep
${DS_WORKBENCH_NAME}=    ds-sep-bench
${DS_PRJ_DESCRIPTION}=    DS project to test Starburst Enterprise integration
${NB_IMAGE}=    Minimal Python
${SEP_CR_FILEPATH}=    ${FILES_RESOURCES_DIRPATH}/starburst-enterprise-cr.json    # taken (and slightly changed) from https://github.com/starburstdata/redhat-marketplace-operators/blob/main/operators/starburst-enterprise-helm-operator-rhmp/402.1.0/manifests/starburst-enterprise-helm-operator-rhmp.clusterserviceversion.yaml
${SEP_SECRET_TEMPLATE_FILEPATH}=    ${FILES_RESOURCES_DIRPATH}/starburst-template-secret.yaml
${GET_SQL_FUNC}=    import pandas\ndef get_sql(sql, connector):\n\tcur = connector.cursor()\n\tcur.execute(sql)\n\treturn pandas.DataFrame(cur.fetchall(), columns=[c[0] for c in cur.description])\nprint("get_sql function defined")    # robocop: disable
${INIT_CELL_CODE}=    import os\nimport trino\nTRINO_USERNAME="dummy-user"\nTRINO_HOSTNAME = os.environ.get('TRINO_HOSTNAME')\nTRINO_PORT= 80\nconn = trino.dbapi.connect(\nhost=TRINO_HOSTNAME,\nport=TRINO_PORT,\nuser=TRINO_USERNAME\n)\nprint("connection to trino set")    # robocop: disable
${QUERY_CATALOGS}=    SHOW CATALOGS
${QUERY_SCHEMAS}=    SHOW SCHEMAS from tpch
${QUERY_TABLES}=    SHOW TABLES from tpch.sf1
${QUERY_CUSTOMERS}=    SELECT name FROM tpch.sf1.customer limit 3
${QUERY_JOIN}=    SELECT c.name FROM tpch.sf1.customer c JOIN tpch.sf1.orders o ON c.custkey = o.custkey ORDER BY o.orderdate DESC limit 3    # robocop: disable
${QUERY_CATALOGS_PY}=    sql = '${QUERY_CATALOGS}'\ndf = get_sql(sql, conn)\nprint(df['Catalog'].values)\n
${QUERY_SCHEMAS_PY}=    sql = '${QUERY_SCHEMAS}'\ndf = get_sql(sql, conn)\nprint(df['Schema'].values)\n
${QUERY_TABLES_PY}=    sql = '${QUERY_TABLES}'\ndf = get_sql(sql, conn)\nprint(df['Table'].values)\n
${QUERY_CUSTOMERS_PY}=    sql = '${QUERY_CUSTOMERS}'\ndf = get_sql(sql, conn)\nprint(df['name'].values)\n    # robocop: disable
${QUERY_JOIN_PY}=    sql = '${QUERY_JOIN}'\ndf = get_sql(sql, conn)\nprint(df['name'].values)\n    # robocop: disable


*** Test Cases ***
Verify Starburst Enterprise Operator Can Be Installed
    [Documentation]    Installs Starburst enterprise operator and check if
    ...                its tile/card appears in RHODS Enabled page
    [Tags]    ODS-2247    Tier2
    #Create Starburst Route If Not Exists    name=${STARBURST_ROUTE_NAME}
    Log    message=Operator is installed as part of Suite Setup
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Verify Service Is Enabled         starburstenterprise


*** Keywords ***
Starburst Enterprise Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${NAMESPACE}
    Install ISV Operator From OperatorHub Via CLI    operator_name=${OPERATOR_NAME}
    ...    subscription_name=${SUBSCRIPTION_NAME}    namespace=${NAMESPACE}
    ...    channel=${CHANNEL}    catalog_source_name=${CATALOG_SOURCE_NAME}
    ...    cs_namespace=${CATALOG_SOURCE_NAMESPACE}    operator_group_target_ns=${NAMESPACE}
    Wait Until Operator Subscription Last Condition Is
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${SUBSCRIPTION_NAME}
    ...    namespace=${NAMESPACE}
    Create Starburst Enteprise License Secret
    Deploy Custom Resource    kind=StarburstEnterprise    namespace=${namespace}
    ...    filepath=${SEP_CR_FILEPATH}
    Wait Until Operator Pods Are Running    namespace=${NAMESPACE}
    ...    expected_pods_dict=${EXP_PODS_INFO}
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}

Starburst Enterprise Suite Teardown
    Close All Browsers
    # to do - uninstall starburst

Create Route And Workbench
    ${rc}  ${host}=    Create Starburst Route    name=${SEP_ROUTE_NAME}
    ...    namespace=${NAMESPACE}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${DS_PROJECT_NAME}    description=${DS_PRJ_DESCRIPTION}
    ${envs_var_cm}=         Create Dictionary    TRINO_USERNAME=${TEST_USER_3.USERNAME}   TRINO_HOSTNAME=${host}
    ...    k8s_type=Config Map  input_type=${KEYVALUE_TYPE}
    ${envs_list}=    Create List   ${envs_var_cm}
    Create Workbench    workbench_title=${DS_WORKBENCH_NAME}  workbench_description=${WORKBENCH_3_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_existent=Default
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}
    Wait Until Workbench Is Started     workbench_title=${DS_WORKBENCH_NAME}
    Launch And Access Workbench    workbench_title=${DS_WORKBENCH_NAME}
    ...    username=${TEST_USER_3.USERNAME}     password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}

Create Starburst Enteprise License Secret
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<NAMESPACE>/${NAMESPACE}/g" ${SEP_SECRET_TEMPLATE_FILEPATH}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<VALUE>/${STARBURST.LICENSE_ENCODED}/g" ${SEP_SECRET_TEMPLATE_FILEPATH}
    Oc Apply    kind=Secret    src=${SEP_SECRET_TEMPLATE_FILEPATH}
