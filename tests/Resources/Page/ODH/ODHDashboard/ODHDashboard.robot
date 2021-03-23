*** Settings ***
Library         JupyterLibrary

*** Keywords ***
Launch ${dashboard_app} From ODH Dashboard Link
  Click Link  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]/../div[contains(@class,"pf-c-card__footer")]/a
  Switch Window  NEW

Launch ${dashboard_app} From ODH Dashboard Dropdown
  Click Button  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]/..//button[contains(@class,pf-c-dropdown__toggle)]
  Click Link  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]/..//a[.="Launch"]
  Switch Window  NEW
