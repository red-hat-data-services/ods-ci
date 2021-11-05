*** Settings ***
Resource    ../../../Resources/ODS.robot

*** Variables ***

@{RECORD_GROUPS}  Availability Metrics  SLOs - JupyterHub  SLOs - ODH Dashboard  SLOs - RHODS Operator  SLOs - Traefik Proxy  Usage Metrics

@{ALERT_GROUPS}  Builds  DeadManSnitch  RHODS-PVC-Usage  SLOs-haproxy_backend_http_responses_total  SLOs-probe_success

*** Test Cases ***

Test Existence of Prometheus Alerting Rules
  [Tags]  Sanity  ODS-509
  Check Prometheus Alerting Rules

Test Existence of Prometheus Recording Rules
  [Tags]  Sanity  ODS-510
  Check Prometheus Recording Rules

*** Keywords ***

Check Prometheus Recording Rules
  Prometheus.Verify Rules  ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  record  @{RECORD_GROUPS}

Check Prometheus Alerting Rules
  Prometheus.Verify Rules  ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  alert  @{ALERT_GROUPS}
