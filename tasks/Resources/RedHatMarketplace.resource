*** Settings ***
Library    OpenShiftLibrary
Library    ../../venv/lib64/python3.8/site-packages/robot/libraries/OperatingSystem.py


*** Variables ***
${RH_MARKETPLACE_NS}=    openshift-redhat-marketplace

*** Keywords ***
Is Cluster Registered
    ${result}=  Run Keyword And Return Status
    ...  Run Keywords
    ...  Oc Get  kind=Project  field_selector=metadata.name=${RH_MARKETPLACE_NS}  AND
    ...  Oc Get  kind=Secret  namespace=${RH_MARKETPLACE_NS}
    ...          field_selector=metadata.name=redhat-marketplace-pull-secret  AND
    ...  Oc Get  kind=Subscription  namespace=${RH_MARKETPLACE_NS}
    ...          field_selector=metadata.name=redhat-marketplace-operator
    [Return]  ${result}

Check Cluster Is Not Already Registered
    ${registered}=    Is Cluster Registered
    IF    ${registered} == ${TRUE}
        Fail    msg=Cluster may be already registered to RHM. Check the cluster...       
    END

Install RedHat Marketplace Operator
    Run    oc apply -f "https://marketplace.redhat.com/provisioning/v1/rhm-operator/rhm-operator-subscription?approvalStrategy=Automatic"

Create RedHat Marketplace Secret
    [Arguments]    ${token}
    Run    oc create secret generic redhat-marketplace-pull-secret -n openshift-redhat-marketplace --from-literal=PULL_SECRET=${token}
    Run And Return Rc And Output    curl -sL https://marketplace.redhat.com/provisioning/v1/scripts/update-global-pull-secret | bash -s ${token}
