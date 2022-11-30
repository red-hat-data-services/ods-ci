*** Settings ***
Documentation    Suite to test Managed Starburst integration
Resource        ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource
Resource        ../../../Resources/Page/LoginPage.robot
Suite Setup    Starburst Setup Suite

*** Variables ***
${GET_SQL_FUNC}=        import pandas\ndef get_sql(sql, connector):\n\tcur = connector.cursor()\n\tcur.execute(sql)\n\treturn pandas.DataFrame(cur.fetchall(), columns=[c[0] for c in cur.description])\nprint("get_sql function defined")    # robocop: disable
${INIT_CELL_CODE}=      import os\nimport trino\nTRINO_USERNAME="dummy-user"\nTRINO_HOSTNAME = os.environ.get('TRINO_HOSTNAME')\nTRINO_PORT= 80\nconn = trino.dbapi.connect(\nhost=TRINO_HOSTNAME,\nport=TRINO_PORT,\nuser=TRINO_USERNAME\n)\nprint("connection to trino set")    # robocop: disable
${QUERY_CATALOGS}=      sql = 'SHOW CATALOGS'\ndf = get_sql(sql, conn)\nprint(df['Catalog'].values)\n
${QUERY_SCHEMAS}=       sql = 'SHOW SCHEMAS from tpch'\ndf = get_sql(sql, conn)\nprint(df['Schema'].values)\n
${QUERY_TABLES}=        sql = 'SHOW TABLES from tpch.sf1'\ndf = get_sql(sql, conn)\nprint(df['Table'].values)\n
${QUERY_CUSTOMERS}=     sql = 'SELECT * FROM tpch.sf1.customer limit 3'\ndf = get_sql(sql, conn)\nprint(df['name'].values)\n    # robocop: disable


*** Test Cases ***
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


Verify User Can Query Starburst Using JupyterLab
    [Tags]    MISV-89
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    # Verify Service Is Enabled    app_name=starburst
    Launch JupyterHub Spawner From Dashboard
    ${host}=     Get Starburst Route
    &{notebook_envs}=  Create Dictionary  TRINO_HOSTNAME=${host}
    Spawn Notebook With Arguments    username=${TEST_USER_3.USERNAME}  password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}    envs=&{notebook_envs}
    # Open Browser    url=https://jupyter-nb-htpasswd-2dcluster-2dadmin-2duser-rhods-notebooks.apps.qeaisrhods-rsa.ikfk.s1.devshift.org/notebook/rhods-notebooks/jupyter-nb-htpasswd-2dcluster-2dadmin-2duser/lab
    # Open Browser    url=https://jupyter-nb-htpasswd-2dcluster-2dadmin-2duser-rhods-notebooks.apps.qeaisrhods-rsa.ikfk.s1.devshift.org/notebook/rhods-notebooks/jupyter-nb-htpasswd-2dcluster-2dadmin-2duser/lab
    # ...     browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    # Run Keyword And Warn On Failure   Login To Openshift  ${TEST_USER_3.USERNAME}  ${TEST_USER_3.PASSWORD}  ${TEST_USER_3.AUTH_TYPE}
    # Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
    # Maybe Close Popup
    Open New Notebook In Jupyterlab Menu
    # Clone Git Repository  REPO_URL=${GIT_REPO_NOTEBOOKS}
    # Open Consumer Notebook  dir_path=${NOTEBOOK_DIR_PATH}  filename=${NOTEBOOK_CONS_FILENAME}
    # ${prod_tab_id} =    Get Selected Tab ID
    # Open With JupyterLab Menu  Run  Run All Cells
    # Wait Until JupyterLab Code Cell Is Not Active In a Given Tab  tab_id_to_wait=${prod_tab_id}
    Run Cell And Check For Errors    !pip install pandas;pip install trino
    Run Cell And Check For Errors    ${GET_SQL_FUNC}
    Run Cell And Check For Errors    ${INIT_CELL_CODE}
    Run Query And Check Output    query_code=${QUERY_CATALOGS}
    ...    expected_output=['system' 'tpch']
    Run Query And Check Output    query_code=${QUERY_SCHEMAS}
    ...    expected_output=['information_schema' 'sf1' 'sf100' 'sf1000' 'sf10000' 'sf100000' 'sf300' 'sf3000' 'sf30000' 'tiny']
    Run Query And Check Output    query_code=${QUERY_TABLES}
    ...    expected_output=['customer' 'lineitem' 'nation' 'orders' 'part' 'partsupp' 'region' 'supplier']
    Run Query And Check Output    query_code=${QUERY_CUSTOMERS}
    ...    expected_output=('Customer#[0-9]+'\s?)+
    ...    use_regex=${TRUE}
    Capture Page Screenshot    
    ## ${output}=    Run Cell And Get Output    ${QUERY_CATALOGS}
    ## Run Keyword And Continue On Failure    Should Be Equal As Strings    ${output}    ['system' 'tpch']
    ## ${output}=    Run Cell And Get Output    ${QUERY_SCHEMAS}
    ## ${output}=    Replace String    ${output}    \n    ${EMPTY}
    ## Run Keyword And Continue On Failure    Should Be Equal As Strings    ${output}
    ## ...    ['information_schema' 'sf1' 'sf100' 'sf1000' 'sf10000' 'sf100000' 'sf300' 'sf3000' 'sf30000' 'tiny']
    ## ${output}=    Run Cell And Get Output    ${QUERY_TABLES}
    ## ${output}=    Replace String    ${output}    \n    ${EMPTY}
    ## Run Keyword And Continue On Failure    Should Be Equal As Strings    ${output}
    ## ...    ['customer' 'lineitem' 'nation' 'orders' 'part' 'partsupp' 'region' 'supplier']
    ## 
    ## ${output}=    Run Cell And Get Output    ${QUERY_CUSTOMERS}
    ## Run Keyword And Continue On Failure    Should Match Regexp    ${output}    ('Customer#[0-9]+'\s?)+
     
    


*** Keywords ***
Starburst Setup Suite
    [Documentation]    Setup for Managed Staburst Test Suite
    Set Library Search Order    SeleniumLibrary
    #RHOSi Setup

Run Query And Check Output
    [Arguments]    ${query_code}    ${expected_output}    ${use_regex}=${FALSE}
    ${output}=    Run Cell And Get Output    ${query_code}
    ${output}=    Replace String    ${output}    \n    ${EMPTY}
    IF    ${use_regex} == ${FALSE}
        Run Keyword And Continue On Failure    Should Be Equal As Strings    ${output}
        ...    ${expected_output}
    ELSE
        Run Keyword And Continue On Failure    Should Match Regexp    ${output}    ${expected_output}
        
    END
