*** Settings ***
Documentation       Contains Triage URLs Mappings


*** Variables ***
${CODEFLARE_OPERATOR_AVAILABILITY_TRIAGE_URL}                       https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Distributed-Workloads/codeflare-operator-availability.md
${CODEFLARE_OPERATOR_ABSENT_OVER_TIME_TRIAGE_URL}                   https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Distributed-Workloads/codeflare-operator-absent-over-time.md
${CODEFLARE_OPERATOR_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}            https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Distributed-Workloads/codeflare-operator-probe-success-burn-rate.md
${DSP_APP_COMPONENT_READINESS_STATUS_TRIAGE_URL}                    https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Data-Science-Pipelines/data-science-pipelines-application-component-readiness-status.md
${DSP_APP_ERROR_BURN_RATE_TRIAGE_URL}                               https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Data-Science-Pipelines/data-science-pipelines-application-error-burn-rate.md
${DSP_OPERATOR_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}                  https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Data-Science-Pipelines/data-science-pipelines-operator-probe-success-burn-rate.md
${KSERVE_CONTROLLER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}             https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Model-Serving/rhods-kserve-controller-probe-success-burn-rate.md
${KUEUE_OPERATOR_AVAILABILITY_TRIAGE_URL}                           https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Distributed-Workloads/kueue-operator-availability.md
${RHODS_MODELMESH_CONTROLLER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}    https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Model-Serving/rhods-modelmesh-controller-probe-success-burn-rate.md
${RHODS_ODH_CONTROLLER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}          https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Model-Serving/rhods-odh-controller-probe-success-burn-rate.md
${KUBERAY_OPERATOR_AVAILABILITY_TRIAGE_URL}                         https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Distributed-Workloads/kuberay-operator-availability.md
${RHODS_DASHBOARD_ROUTE_ERROR_BURN_RATE_TRIAGE_URL}                 https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/RHODS-Dashboard/rhods-error-burn-rate.md
${RHODS_DASHBOARD_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}               https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/RHODS-Dashboard/rhods-dashboard-probe-success-burn-rate.md
${TRAINING_OPERATOR_AVAILABILITY_TRIAGE_URL}                        https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Distributed-Workloads/training-operator-availability.md
${RHOAI_TRUSTYAI_CONTROLLER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}     https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Model-Serving/rhoai-trustyai-controller-probe-success-burn-rate.md
${RHODS_KFNBC_NOTEBOOK_CONTROLLER_ALERT_TRIAGE_URL}                 https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Jupyter/rhods-kfnbc-notebook-controller-alert.md
${RHODS_ODH_NOTEBOOK_CONTROLLER_ALERT_TRIAGE_URL}                   https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Jupyter/rhods-odh-notebook-controller-alert.md
${NOTEBOOK_PVC_USAGE_TRIAGE_URL}                                    https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/tree/main/RHODS
${RHODS_JUPYTER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}                 https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/RHODS/Jupyter/rhods-jupyter-probe-success-burn-rate.md


&{TRIAGE_URLS}                          CodeFlare Operator is not running=${CODEFLARE_OPERATOR_AVAILABILITY_TRIAGE_URL}
...                                     CodeFlare Operator taking too long to be up=${CODEFLARE_OPERATOR_ABSENT_OVER_TIME_TRIAGE_URL}
...                                     CodeFlare Operator Probe Success.*=${CODEFLARE_OPERATOR_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}
...                                     Data Science Pipeline.*Unavailable=${DSP_APP_COMPONENT_READINESS_STATUS_TRIAGE_URL}
...                                     Data Science Pipelines Application Route Error.*=${DSP_APP_ERROR_BURN_RATE_TRIAGE_URL}
...                                     Data Science Pipelines Operator Probe Success.*=${DSP_OPERATOR_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}
...                                     Kserve Controller Probe Success.*=${KSERVE_CONTROLLER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}
...                                     Kueue Operator is not running=${KUEUE_OPERATOR_AVAILABILITY_TRIAGE_URL}
...                                     Modelmesh Controller Probe Success.*=${RHODS_MODELMESH_CONTROLLER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}
...                                     ODH Model Controller Probe Success.*=${RHODS_ODH_CONTROLLER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}
...                                     KubeRay Operator is not running=${KUBERAY_OPERATOR_AVAILABILITY_TRIAGE_URL}
...                                     RHODS Dashboard Route Error.*=${RHODS_DASHBOARD_ROUTE_ERROR_BURN_RATE_TRIAGE_URL}
...                                     RHODS Dashboard Probe Success.*=${RHODS_DASHBOARD_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}
...                                     KubeFlow Training Operator is not running=${TRAINING_OPERATOR_AVAILABILITY_TRIAGE_URL}
...                                     TrustyAI Controller Probe Success.*=${RHOAI_TRUSTYAI_CONTROLLER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}
...                                     Kubeflow notebook controller pod is not running=${RHODS_KFNBC_NOTEBOOK_CONTROLLER_ALERT_TRIAGE_URL}
...                                     ODH notebook controller pod is not running=${RHODS_ODH_NOTEBOOK_CONTROLLER_ALERT_TRIAGE_URL}
...                                     User notebook pvc usage.*=${NOTEBOOK_PVC_USAGE_TRIAGE_URL}
...                                     RHODS Jupyter Probe Success.*=${RHODS_JUPYTER_PROBE_SUCCESS_BURN_RATE_TRIAGE_URL}
