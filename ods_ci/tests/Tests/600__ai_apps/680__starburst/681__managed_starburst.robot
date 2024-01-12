*** Settings ***
Documentation    Suite to test Managed Starburst integration
Resource         ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource
Resource         ../../../Resources/Page/LoginPage.robot
Resource         ../../../../tasks/Resources/SERH_OLM/install.resource
Suite Setup      Starburst Setup Suite
Suite Teardown    RHOSi Teardown


*** Variables ***
${GET_SQL_FUNC}=           import pandas\ndef get_sql(sql, connector):\n\tcur = connector.cursor()\n\tcur.execute(sql)\n\treturn pandas.DataFrame(cur.fetchall(), columns=[c[0] for c in cur.description])\nprint("get_sql function defined")    # robocop: disable
${INIT_CELL_CODE}=         import os\nimport trino\nTRINO_USERNAME="dummy-user"\nTRINO_HOSTNAME = os.environ.get('TRINO_HOSTNAME')\nTRINO_PORT= 80\nconn = trino.dbapi.connect(\nhost=TRINO_HOSTNAME,\nport=TRINO_PORT,\nuser=TRINO_USERNAME\n)\nprint("connection to trino set")    # robocop: disable
${QUERY_CATALOGS}=         SHOW CATALOGS
${QUERY_SCHEMAS}=          SHOW SCHEMAS from tpch
${QUERY_TABLES}=           SHOW TABLES from tpch.sf1
${QUERY_CUSTOMERS}=        SELECT name FROM tpch.sf1.customer limit 3
${QUERY_JOIN}=             SELECT c.name FROM tpch.sf1.customer c JOIN tpch.sf1.orders o ON c.custkey = o.custkey ORDER BY o.orderdate DESC limit 3    # robocop: disable
${QUERY_CATALOGS_PY}=      sql = '${QUERY_CATALOGS}'\ndf = get_sql(sql, conn)\nprint(df['Catalog'].values)\n
${QUERY_SCHEMAS_PY}=       sql = '${QUERY_SCHEMAS}'\ndf = get_sql(sql, conn)\nprint(df['Schema'].values)\n
${QUERY_TABLES_PY}=        sql = '${QUERY_TABLES}'\ndf = get_sql(sql, conn)\nprint(df['Table'].values)\n
${QUERY_CUSTOMERS_PY}=     sql = '${QUERY_CUSTOMERS}'\ndf = get_sql(sql, conn)\nprint(df['name'].values)\n    # robocop: disable
${QUERY_JOIN_PY}=     sql = '${QUERY_JOIN}'\ndf = get_sql(sql, conn)\nprint(df['name'].values)\n    # robocop: disable


*** Test Cases ***
Verify Managed Starburst Is Deployed
    [Documentation]    Checks that Managed Starburst is deployed in the cluster
    [Tags]    MISV-79    MISV-84
    ${installed}=    Is Managed Starburst Installed
    Should Be Equal    ${installed}    ${TRUE}
    Status Of Managed Starburst CR Should Be    Deployed
    Managed Starburst Pods Should Be Deployed

Verify User Can Access Trino Web console
    [Documentation]    Checks Trino Web UI can be accessed
    [Tags]    MISV-86
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Trino Web UI    user=${TEST_USER_3.USERNAME}
    Check Trino Web UI Is Loaded

Verify User Can Access Managed Starburst Web console
    [Documentation]    Checks Starburst Web UI can be accessed
    [Tags]    MISV-85
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Managed Staburst Web UI    user=${TEST_USER_3.USERNAME}
    Check Managed Starburst Web UI Is Loaded
    Check Worksheet Tool Is Accessible

Verify User Can Query Starburst Using CLI
    [Documentation]    Runs some sample queries against Staburst using trino CLI
    [Tags]    MISV-88
    ${host}=    Get Starburst Route
    Run Query And Check Output    query_code=${QUERY_CATALOGS}
    ...    expected_output=['system' 'tpch']    cli=${TRUE}
    ...    host=${host}
    Run Query And Check Output    query_code=${QUERY_SCHEMAS}
    ...    expected_output=['information_schema' 'sf1' 'sf100' 'sf1000' 'sf10000' 'sf100000' 'sf300' 'sf3000' 'sf30000' 'tiny']    # robocop: disable
    ...    cli=${TRUE}    host=${host}
    Run Query And Check Output    query_code=${QUERY_TABLES}
    ...    expected_output=['customer' 'lineitem' 'nation' 'orders' 'part' 'partsupp' 'region' 'supplier']
    ...    cli=${TRUE}    host=${host}
    Run Query And Check Output    query_code=${QUERY_CUSTOMERS}
    ...    expected_output=('Customer#[0-9]+'\s?)+
    ...    use_regex=${TRUE}    cli=${TRUE}    host=${host}
    Run Query And Check Output    query_code=${QUERY_JOIN}
    ...    expected_output=('Customer#[0-9]+'\s?)+
    ...    use_regex=${TRUE}    cli=${TRUE}    host=${host}

Verify User Can Query Starburst Using JupyterLab    # robocop: disable
    [Documentation]    Runs some sample queries against Staburst using
    ...                a Jupyter notebook created by a RHODS user by mean Spawner
    [Tags]    MISV-89
    [Teardown]    Fix Spawner Status    username=${TEST_USER_3.USERNAME}
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    # Verify Service Is Enabled    app_name=starburst
    Launch JupyterHub Spawner From Dashboard
    ${host}=     Get Starburst Route
    &{notebook_envs}=  Create Dictionary  TRINO_HOSTNAME=${host}
    Spawn Notebook With Arguments    username=${TEST_USER_3.USERNAME}  password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}    envs=&{notebook_envs}
    Open New Notebook In Jupyterlab Menu
    Run Cell And Check For Errors    !pip install pandas;pip install trino
    Run Cell And Check For Errors    ${GET_SQL_FUNC}
    Run Cell And Check For Errors    ${INIT_CELL_CODE}
    Run Query And Check Output    query_code=${QUERY_CATALOGS_PY}
    ...    expected_output=['system' 'tpch']
    Run Query And Check Output    query_code=${QUERY_SCHEMAS_PY}
    ...    expected_output=['information_schema' 'sf1' 'sf100' 'sf1000' 'sf10000' 'sf100000' 'sf300' 'sf3000' 'sf30000' 'tiny']    # robocop: disable
    Run Query And Check Output    query_code=${QUERY_TABLES_PY}
    ...    expected_output=['customer' 'lineitem' 'nation' 'orders' 'part' 'partsupp' 'region' 'supplier']
    Run Query And Check Output    query_code=${QUERY_CUSTOMERS_PY}
    ...    expected_output=('Customer#[0-9]+'\s?)+
    ...    use_regex=${TRUE}
    Run Query And Check Output    query_code=${QUERY_JOIN_PY}
    ...    expected_output=('Customer#[0-9]+'\s?)+
    ...    use_regex=${TRUE}
    Capture Page Screenshot

Verify User Cannot Access Web UI With Invalid License
    [Tags]    MISV-87
    [Setup]    Get Original License Secret
    Apply Fake Starburst License
    Restart Coordinator And Workers Pods
    Starburst Deployment Should Not Be Successful
    [Teardown]    Restore Starburst Original License And Verify Deployment


*** Keywords ***
Starburst Setup Suite
    [Documentation]    Setup for Managed Staburst Test Suite
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Get Original License Secret
    ${current_secret}=    Oc Get    kind=Secret  name=starburst-license  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}
    Set Suite Variable    ${ORIGINAL_SECRET}    ${current_secret[0]}

Apply Fake Starburst License
    ${new_secret}=    Copy Dictionary    ${ORIGINAL_SECRET}    deepcopy=${TRUE}
    Remove From Dictionary    ${new_secret}[metadata]  managedFields  resourceVersion  uid  creationTimestamp  annotations
    Set To Dictionary    ${new_secret}[data]    starburstdata.license=ZmFrZSBsaWNlbnNlIQo=
    ${rc}    ${out}=    Run And Return Rc And Output    echo ${new_secret} | oc apply -f -

Restart Coordinator And Workers Pods
    Oc Delete    kind=Pod   namespace=${STARBURST_CR_DEFAULT_NAMESPACE}  label_selector=role=worker
    Oc Delete    kind=Pod   namespace=${STARBURST_CR_DEFAULT_NAMESPACE}  label_selector=role=coordinator

Starburst Deployment Should Not Be Successful
    ${status}=    Run Keyword And Return Status    Wait Until Managed Starburst Installation Is Completed
    ...    cr_chk_retries=1    cr_chk_retries_interval=10s
    ...    pods_chk_retries=10    pods_chk_retries_interval=10s
    IF    ${status} == ${TRUE}
        Fail    msg=Coordinator and workers pod should be in error if license is not valid
    END

Restore Starburst Original License And Verify Deployment
    ${new_secret}=    Copy Dictionary    ${ORIGINAL_SECRET}    deepcopy=${TRUE}
    Remove From Dictionary    ${new_secret}[metadata]  managedFields  resourceVersion  uid  creationTimestamp  annotations
    ${rc}    ${out}=    Run And Return Rc And Output    echo ${new_secret} | oc apply -f -
    Restart Coordinator And Workers Pods
    ${status}=    Run Keyword And Return Status    Wait Until Managed Starburst Installation Is Completed
    ...    cr_chk_retries=1    cr_chk_retries_interval=10s
    ...    pods_chk_retries=50    pods_chk_retries_interval=10s
    IF    ${status} == ${FALSE}
        Fail    msg=Coordinator and workers pod should be successfully running
    END

