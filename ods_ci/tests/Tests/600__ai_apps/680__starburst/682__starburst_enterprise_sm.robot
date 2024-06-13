*** Settings ***
Documentation       Test suite to test integration with Starburst Enterprise operator in RHODS SM
Library             SeleniumLibrary
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/Page/Operators/ISVs.resource
Resource            ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Suite Setup          Starburst Enterprise Suite Setup
Suite Teardown       Starburst Enterprise Suite Teardown
Test Tags            ExcludeOnODH


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
${QUERY_CATALOGS_PY}=    sql = '${QUERY_CATALOGS}'\ndf = get_sql(sql, conn)\nprint(df['Catalog'].values)\n    # robocop: disable
${QUERY_SCHEMAS_PY}=    sql = '${QUERY_SCHEMAS}'\ndf = get_sql(sql, conn)\nprint(df['Schema'].values)\n    # robocop: disable
${QUERY_TABLES_PY}=    sql = '${QUERY_TABLES}'\ndf = get_sql(sql, conn)\nprint(df['Table'].values)\n
${QUERY_CUSTOMERS_PY}=    sql = '${QUERY_CUSTOMERS}'\ndf = get_sql(sql, conn)\nprint(df['name'].values)\n    # robocop: disable
${QUERY_JOIN_PY}=    sql = '${QUERY_JOIN}'\ndf = get_sql(sql, conn)\nprint(df['name'].values)\n    # robocop: disable


*** Test Cases ***
Verify Starburst Enterprise Operator Can Be Installed
    [Documentation]    Installs Starburst enterprise operator and check if
    ...                its tile/card appears in RHODS Enabled page
    [Tags]    ODS-2247    Tier2
    Log    message=Operator is installed and CR is deployed as part of Suite Setup
    Verify Service Is Enabled         ${SEP_DISPLAYED_NAME}

Verify User Can Perform Basic Queries Against Starburst From A DS Workbench    # robocop: disable
    [Documentation]    Creates, launches a DS Workbench and query the Starburst
    ...                default catalogs
    [Tags]    ODS-2249    Tier2
    [Setup]    Create Route And Workbench
    Launch And Access Workbench    workbench_title=${DS_WORKBENCH_NAME}
    ...    username=${TEST_USER_3.USERNAME}     password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}
    Open New Notebook In Jupyterlab Menu
    Run Cell And Check For Errors    !pip install pandas;pip install trino
    Run Cell And Check For Errors    ${GET_SQL_FUNC}
    Run Cell And Check For Errors    ${INIT_CELL_CODE}
    Run Query And Check Output    query_code=${QUERY_CATALOGS_PY}
    ...    expected_output=['system' 'tpch']
    Run Query And Check Output    query_code=${QUERY_SCHEMAS_PY}
    ...    expected_output=['information_schema' 'sf1' 'sf100' 'sf1000' 'sf10000' 'sf100000' 'sf300' 'sf3000' 'sf30000' 'tiny']    # robocop: disable
    Run Query And Check Output    query_code=${QUERY_TABLES_PY}
    ...    expected_output=['customer' 'lineitem' 'nation' 'orders' 'part' 'partsupp' 'region' 'supplier']    # robocop: disable
    Run Query And Check Output    query_code=${QUERY_CUSTOMERS_PY}
    ...    expected_output=('Customer#[0-9]+'\s?)+
    ...    use_regex=${TRUE}
    Run Query And Check Output    query_code=${QUERY_JOIN_PY}
    ...    expected_output=('Customer#[0-9]+'\s?)+
    ...    use_regex=${TRUE}
    Capture Page Screenshot


*** Keywords ***
Starburst Enterprise Suite Setup    # robocop: disable
    [Documentation]    Installs Starburst Enterprise operator and launch RHODS Dashboard
    Skip If RHODS Is Managed
    Set Library Search Order    SeleniumLibrary
    ${PROJECTS_TO_DELETE}=    Create List    ${DS_PROJECT_NAME}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${PROJECTS_TO_DELETE}
    RHOSi Setup
    ${manager_containers}=  Create List  manager
    ${manager}=         Create Dictionary    label_selector=control-plane=controller-manager    n_pods=1
    ...    n_containers=1    containers_names=${manager_containers}
    ${coordinator_containers}=    Create List  coordinator
    ${coordinator}=         Create Dictionary    label_selector=role=coordinator    n_pods=1
    ...    n_containers=1    containers_names=${coordinator_containers}
    ${worker_containers}=    Create List  worker
    ${worker}=         Create Dictionary    label_selector=role=worker    n_pods=2
    ...    n_containers=1    containers_names=${worker_containers}
    ${pods_dicts}=    Create List   ${manager}    ${coordinator}    ${worker}
    Set Suite Variable    ${EXP_PODS_INFO}    ${pods_dicts}
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${NAMESPACE}
    Install ISV Operator From OperatorHub Via CLI    operator_name=${OPERATOR_NAME}
    ...    subscription_name=${SUBSCRIPTION_NAME}    namespace=${NAMESPACE}
    ...    channel=${CHANNEL}    catalog_source_name=${CATALOG_SOURCE_NAME}
    ...    cs_namespace=${CATALOG_SOURCE_NAMESPACE}
    ...    operator_group_name=${OPERATOR_NAME}
    ...    operator_group_ns=${NAMESPACE}
    ...    operator_group_target_ns=${NAMESPACE}
    Wait Until Operator Subscription Last Condition Is
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${SUBSCRIPTION_NAME}
    ...    namespace=${NAMESPACE}
    Create Starburst Enteprise License Secret
    Wait Until CRD Exists    crd_fullname=starburstenterprises.charts.starburstdata.com
    Deploy Custom Resource    kind=StarburstEnterprise    namespace=${namespace}
    ...    filepath=${SEP_CR_FILEPATH}
    Wait Until Operator Pods Are Running    namespace=${NAMESPACE}
    ...    expected_pods_dict=${EXP_PODS_INFO}
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}

Starburst Enterprise Suite Teardown
    [Documentation]    Uninstalls Starburst Enterprise operator
    Skip If RHODS Is Managed
    Delete Data Science Projects From CLI    ${PROJECTS_TO_DELETE}
    Delete Custom Resource    kind=StarburstEnterprise
    ...    namespace=${NAMESPACE}    name=starburstenterprise-sample
    Uninstall ISV Operator From OperatorHub Via CLI
    ...    subscription_name=${SUBSCRIPTION_NAME}    namespace=${NAMESPACE}
    Delete Starburst Enterprise License Secret
    Oc Delete    kind=Project  name=${NAMESPACE}
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}    wait_for_cards=${FALSE}
    Remove Disabled Application From Enabled Page    app_id=starburstenterprise
    Close All Browsers

Create Route And Workbench
    [Documentation]    Creates the Starburst Enterprise route, the DS Project and workbench
    ${rc}  ${host}=    Create Starburst Route    name=${SEP_ROUTE_NAME}
    ...    namespace=${NAMESPACE}
    Set Suite Variable    ${SEP_HOST}    ${host}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${DS_PROJECT_NAME}    description=${DS_PRJ_DESCRIPTION}
    ${envs_var_cm}=         Create Dictionary    TRINO_USERNAME=${TEST_USER_3.USERNAME}
    ...    TRINO_HOSTNAME=${host}    k8s_type=Config Map  input_type=${KEYVALUE_TYPE}
    ${envs_list}=    Create List   ${envs_var_cm}
    Create Workbench    workbench_title=${DS_WORKBENCH_NAME}  workbench_description=${DS_WORKBENCH_NAME}
    ...                 prj_title=${DS_PROJECT_NAME}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}
    ...                 envs=${envs_list}
    Wait Until Workbench Is Started     workbench_title=${DS_WORKBENCH_NAME}

Create Starburst Enteprise License Secret
    [Documentation]    Applies the Starburst Enteprise license
    ${secret_filepath}=    Set Variable    ${FILES_RESOURCES_DIRPATH}/starburst-secret.yaml
    Copy File    ${SEP_SECRET_TEMPLATE_FILEPATH}    ${secret_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<NAMESPACE>/${NAMESPACE}/g" ${secret_filepath}    # robocop: disable
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<VALUE>/${STARBURST.LICENSE_ENCODED}/g" ${secret_filepath}    # robocop: disable
    Oc Apply    kind=Secret    src=${secret_filepath}
    Remove File    ${secret_filepath}

Delete Starburst Enterprise License Secret
    [Documentation]    Deletes the secret containing the Starburst Enterprise license
    Oc Delete    kind=Secret    name=starburstdata
    ...    namespace=${NAMESPACE}
