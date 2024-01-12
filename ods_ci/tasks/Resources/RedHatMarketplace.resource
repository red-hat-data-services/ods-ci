*** Settings ***
Documentation    Collections of keywords to register a cluster to RHM
Library    OpenShiftLibrary
Library    OperatingSystem


*** Variables ***
${RH_MARKETPLACE_NS}=    openshift-redhat-marketplace


*** Keywords ***
Is Cluster Registered
    [Documentation]    Returns TRUE if the cluster contains resources created by
    ...                the registration process to RedHat Marketplace
    ${result}=  Run Keyword And Return Status
    ...  Run Keywords
    ...  Oc Get  kind=Project  field_selector=metadata.name=${RH_MARKETPLACE_NS}  AND
    ...  Oc Get  kind=Secret  namespace=${RH_MARKETPLACE_NS}
    ...    field_selector=metadata.name=redhat-marketplace-pull-secret  AND
    ...  Oc Get  kind=Subscription  namespace=${RH_MARKETPLACE_NS}
    ...    field_selector=metadata.name=redhat-marketplace-operator
    RETURN  ${result}

Check Cluster Is Not Already Registered
    [Documentation]    Checks the cluster is not registered. Fails if it is registered
    [Arguments]    ${warn_on_failure}=${FALSE}
    ${registered}=    Is Cluster Registered
    IF    ${registered} == ${TRUE}
        IF    ${warn_on_failure} == ${TRUE}
            Log    message=Cluster may be already registered to RHM. Check the cluster...
            ...    console=yes
            ...    level=WARN
        ELSE
            Fail    msg=Cluster may be already registered to RHM. Check the cluster...
        END
    END

Create RedHat Marketplace Project
    [Documentation]    Creates the projects ${RH_MARKETPLACE_NS}
    ${rc}  ${out}=    Run And Return Rc And Output    oc create namespace ${RH_MARKETPLACE_NS}

Install RedHat Marketplace Operator
    [Documentation]    Installs the RHM operator
    Run    oc apply -f "https://marketplace.redhat.com/provisioning/v1/rhm-operator/rhm-operator-subscription?approvalStrategy=Automatic"

Create RedHat Marketplace Secret
    [Documentation]    Creates pull secret for fetching operators from RHM
    [Arguments]    ${token}
    Run    oc create secret generic redhat-marketplace-pull-secret -n openshift-redhat-marketplace --from-literal=PULL_SECRET=${token}
    ${rc}  ${output}=    Run And Return Rc And Output    curl -sL https://marketplace.redhat.com/provisioning/v1/scripts/update-global-pull-secret | bash -s ${token}    # robocop: disable
