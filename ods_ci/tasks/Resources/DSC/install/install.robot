*** Settings ***
Library    String
Library    OpenShiftLibrary
Library    OperatingSystem


*** Variables ***
${DSC_NAME} =    default
@{COMPONENT_LIST} =    dashboard    datasciencepipelines    kserve    modelmeshserving    workbenches    codeflare    ray  # robocop: disable


*** Keywords ***
Installing DataScienceCluster
  Run Keywords
  ...  Log  Installing DataScienceCluster console=yes  AND
  ...  Install DataScienceCluster

DataScienceCluster Should Be installed
  Verify DataScienceCluster Installation
  Log  DataScienceCluster has been installed  console=yes

Install DataScienceCluster
  IF  "${UPDATE_CHANNEL}" != "stable" and "${UPDATE_CHANNEL}" != "beta" and "${UPDATE_CHANNEL}" != "odh-nightlies"
      Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
  END

Verify DataScienceCluster Installation
  Log  Verifying DataScienceCluster installation  console=yes
  ${dashboard} =    Is Component Enabled    dashboard    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${dashboard}" == "true"  # robocop: disable
    Wait For Pods Numbers  5
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app=rhods-dashboard
    ...                   timeout=1200
  END
  ${workbenches} =    Is Component Enabled    workbenches    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${workbenches}" == "true"  # robocop: disable
    Wait For Pods Numbers  1
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app=notebook-controller
    ...                   timeout=400
    Wait For Pods Numbers  1
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app=odh-notebook-controller
    ...                   timeout=400
  END
  ${modelmeshserving} =    Is Component Enabled    modelmeshserving    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${modelmeshserving}" == "true"  # robocop: disable
    Wait For Pods Numbers   3
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app=odh-model-controller
    ...                   timeout=400
    Wait For Pods Numbers   1
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=component=model-mesh-etcd
    ...                   timeout=400
    Wait For Pods Numbers   3
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app.kubernetes.io/name=modelmesh-controller
    ...                   timeout=400
  END
  ${datasciencepipelines} =    Is Component Enabled    datasciencepipelines    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${datasciencepipelines}" == "true"  # robocop: disable
    Wait For Pods Numbers   1
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app.kubernetes.io/name=data-science-pipelines-operator
    ...                   timeout=400
  END
  ${ray} =    Is Component Enabled    ray    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${ray}" == "true"  # robocop: disable
    Wait For Pods Numbers  1
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app.kubernetes.io/name=kuberay
    ...                   timeout=1200
  END
  ${codeflare} =    Is Component Enabled    codeflare    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${codeflare}" == "true"  # robocop: disable
    Wait For Pods Numbers  1
    ...                   namespace=openshift-operators
    ...                   label_selector=app.kubernetes.io/name=codeflare-operator
    ...                   timeout=1200
  END
  # Monitoring stack not deployed with operator V2, only model serving monitoring stack present
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${modelmeshserving}" == "true"  # robocop: disable
    Wait For Pods Numbers   3
    ...                   namespace=redhat-ods-monitoring
    ...                   label_selector=prometheus=rhods-model-monitoring
    ...                   timeout=400
  END
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${dashboard}" == "true" or "${workbenches}" == "true" or "${modelmeshserving}" == "true" or "${datasciencepipelines}" == "true"  # robocop: disable
    Wait For Pods Status  namespace=redhat-ods-applications  timeout=60
    Log  Verified redhat-ods-applications  console=yes
  END
  # Monitoring stack not deployed with operator V2, only model serving monitoring stack present
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${modelmeshserving}" == "true"  # robocop: disable
    Wait For Pods Status  namespace=redhat-ods-monitoring  timeout=1200
    Log  Verified redhat-ods-monitoring  console=yes
  END
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta" or "${UPDATE_CHANNEL}" == "odh-nightlies") or "${workbenches}" == "true"  # robocop: disable
    Oc Get  kind=Namespace  field_selector=metadata.name=rhods-notebooks
    Log  "Verified rhods-notebook"
  END

Wait For Pods Numbers
  [Documentation]   Wait for number of pod during installtion
  [Arguments]     ${count}     ${namespace}     ${label_selector}    ${timeout}
  ${status}   Set Variable   False
  FOR    ${counter}    IN RANGE   ${timeout}
         ${return_code}    ${output}    Run And Return Rc And Output   oc get pod -n ${namespace} -l ${label_selector} | tail -n +2 | wc -l
         IF    ${output} == ${count}
               ${status}  Set Variable  True
               Log To Console  pods ${label_selector} created
               Exit For Loop
         END
         Sleep    1 sec
  END
  IF    '${status}' == 'False'
        Run Keyword And Continue On Failure    FAIL    Timeout- ${output} pods found with the label selector ${label_selector} in ${namespace} namespace
  END

Apply DataScienceCluster CustomResource
    [Documentation]
    [Arguments]        ${dsc_name}=default
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Log to Console    Requested Configuration:
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        TRY
            Log To Console    ${cmp} - ${COMPONENTS.${cmp}}
        EXCEPT
            Log To Console    ${cmp} - Removed
        END
    END
    Create DataScienceCluster CustomResource Using Test Variables
    ${yml} =    Get File    ${file_path}dsc_apply.yml
    Log To Console    Applying DSC yaml
    Log To Console    ${yml}
    ${return_code}    ${output} =    Run And Return Rc And Output    oc apply -f ${file_path}dsc_apply.yml
    Log To Console    ${output}
    Should Be Equal As Integers	 ${return_code}	 0  msg=Error detected while applying DSC CR
    Remove File    ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        IF    $cmp not in $COMPONENTS
            Component Should Not Be Enabled    ${cmp}
        ELSE IF    '${COMPONENTS.${cmp}}' == 'Managed'
            Component Should Be Enabled    ${cmp}
        ELSE IF    '${COMPONENTS.${cmp}}' == 'Removed'
            Component Should Not Be Enabled    ${cmp}
        END
    END

Create DataScienceCluster CustomResource Using Test Variables
    [Documentation]
    [Arguments]    ${dsc_name}=default
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}dsc_template.yml    destination=${file_path}dsc_apply.yml
    Run    sed -i 's/<dsc_name>/${dsc_name}/' ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        IF    $cmp not in $COMPONENTS
            Run    sed -i 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
        ELSE IF    '${COMPONENTS.${cmp}}' == 'Managed'
            Run    sed -i 's/<${cmp}_value>/Managed/' ${file_path}dsc_apply.yml
        ELSE IF    '${COMPONENTS.${cmp}}' == 'Removed'
            Run    sed -i 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
        END
    END

Component Should Be Enabled
    [Arguments]    ${component}    ${dsc_name}=default
    ${status} =    Is Component Enabled    ${component}    ${dsc_name}
    IF    '${status}' != 'true'    Fail

Component Should Not Be Enabled
    [Arguments]    ${component}    ${dsc_name}=default
    ${status} =    Is Component Enabled    ${component}    ${dsc_name}
    IF    '${status}' != 'false'    Fail

Is Component Enabled
    [Documentation]    Returns the enabled status of a single component (true/false)
    [Arguments]    ${component}    ${dsc_name}=default
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get datasciencecluster ${dsc_name} -o json | jq '.spec.components.${component}\[]'  #robocop:disable
    Log    ${output}
    Should Be Equal As Integers	 ${return_code}	 0  msg=Error detected while getting component status
    ${n_output} =    Evaluate    '${output}' == ''
    IF  ${n_output}
          RETURN    false
    ELSE
         IF    ${output} == "Removed"
               RETURN    false
         ELSE IF    ${output} == "Managed"
              RETURN    true
         END
    END
