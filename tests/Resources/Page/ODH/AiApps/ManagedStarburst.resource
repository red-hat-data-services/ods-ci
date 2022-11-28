*** Settings ***
Library    OperatingSystem
Library    OpenShiftLibrary



*** Variables ***
${STARBURST_CR_DEFAULT_NAMESPACE}=    redhat-starburst-operator

*** Keywords ***
Create Starburst Route
    [Arguments]    ${name}
    ${rc}=    Run And Return Rc    oc expose svc starburst --name ${name} -n ${STARBURST_CR_DEFAULT_NAMESPACE}
    ${route}=    Oc Get  kind=Route  name=${name}  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}  fiels=[spec.host]
    [Return]    ${rc}    ${host}

Create Starburst Route If Not Exists
    [Arguments]    ${name}
    ${found}=    Run Keyword And Return Status    
    ...    Oc Get    kind=Route  name=${name}  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}
    IF    ${found} == ${FALSE}
        ${rc}  ${host}=    Create Starburst Route    name=${name}
    ELSE
        Log    message=Route ${name} already present under ${STARBURST_CR_DEFAULT_NAMESPACE} namespace
        ${host}=    Oc Get  kind=Route  name=${name}  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}  fiels=[spec.host]
    END
    [Return]    ${host}
