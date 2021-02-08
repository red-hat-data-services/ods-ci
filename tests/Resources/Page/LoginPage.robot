*** Settings ***
Library  Selenium2Library


*** Variables ***
${UI} =  https://console-openshift-console.apps.modh-qe.dev.datahub.redhat.com/
${KUBEADMIN} =  kubeadmin
${KUBEPASSWD} =  DYYw5-KSmW7-F9gQt-gzJpV
${BROWSER} =  chrome

*** Keywords ***
Login To Openshift
    Open Browser  ${UI}  browser=${BROWSER}  options=add_argument("--ignore-certificate-errors")
    Wait Until Page Contains  Log in with  timeout=15
    Click Element  xpath=/html/body/div/div/main/div/ul/li[1]/a
    Wait Until Page Contains  Log in to your account
    Input Text  id=inputUsername  ${KUBEADMIN}
    Input Text  id=inputPassword  ${KUBEPASSWD}
    Click Element  xpath=/html/body/div/div/main/div/form/div[4]/button