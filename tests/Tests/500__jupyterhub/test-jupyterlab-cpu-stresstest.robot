*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary

Suite Setup      Begin Web Test
Suite Teardown   End Web Test


*** Variables ***


#${StressTestCode} = Catenate SEPARATOR=\n
#${StressTestCode}  SEPARATOR=${empty}  import os\n
#${StressTestCode}  import os\n
#...  print("Hello World!")\n
#...  # stress test cpu\n
#...  \n
#...  from multiprocessing import Pool\n
#...  import psutil\n
#...  import time\n
#...  \n
#...  \n
#...  def f(x):\n
#...      set_time = 1\n
#...      timeout = time.time() + 60*float(set_time)\n
#...      while True:\n
#...          if time.time() > timeout:\n
#...              break\n
#...  \n
#...  \n
#...  if __name__ == '__main__':\n
#...      processes = psutil.cpu_count()\n
#...      print('Starting stresstest: utilizing %d cores\n' % processes)\n
#...      pool = Pool(processes)\n
#...      pool.map(f, range(processes))\n
#...      print("Finished running stresstest")\n

*** Test Cases ***
Open RHODS Dashboard
  [Tags]  Sanity
  Wait for RHODS Dashboard to Load

Can Launch Jupyterhub
  [Tags]  Sanity
  ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
  IF  ${version-check}==True
    Launch JupyterHub From RHODS Dashboard Link
  ELSE
    Launch JupyterHub From RHODS Dashboard Dropdown
  END

Can Login to Jupyterhub
  [Tags]  Sanity
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']

Can Spawn Notebook
  [Tags]  Sanity
  ## I know the below is needed, but it's quite time consuming!
  #Fix Spawner Status
  Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook

#Can Launch CPU Stress Test Notebook
#  [Tags]  CPU StressTest
#
#  Wait for JupyterLab Splash Screen  timeout=30
#  Maybe Close Popup
#  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
#  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
#  Launch a new JupyterLab Document
#  Close Other JupyterLab Tabs
#
#
#  ${StressTestCode2}  Catenate  SEPARATOR=\n  import os
#  ...  print("Hello World!")
#  ...  # stress test cpu
#  ...
#  ...  from multiprocessing import Pool
#  ...  import psutil
#  ...  import time
#  ...
#  ...
#  ...  def f(x):
#  ...      set_time = 1
#  ...      timeout = time.time() + 60*float(set_time)
#  ...      while True:
#  ...          if time.time() > timeout:
#  ...              break
#  ...
#  ...
#  ...  if __name__ == '__main__':
#  ...      processes = psutil.cpu_count()
#  ...      print('Starting stresstest: utilizing %d cores\n' % processes)
#  ...      pool = Pool(processes)
#  ...      pool.map(f, range(processes))
#  ...      print("Finished running stresstest")
#
#
#
#  # Add and Run JupyterLab Code Cell in Active Notebook  ${StressTestCode2}
#
#  # Add and Run JupyterLab Code Cell in Active Notebook  ${StressTestCode}
#
#  # Add and Run JupyterLab Code Cell in Active Notebook  import os
#  # Add and Run JupyterLab Code Cell in Active Notebook  print("Hello World!")
#  #Python Version Check
#  Capture Page Screenshot
#  Wait Until JupyterLab Code Cell Is Not Active
#  Capture Page Screenshot
#
#  #JupyterLab Code Cell Error Output Should Not Be Visible
#
#  #Add and Run JupyterLab Code Cell in Active Notebook  !pip freeze
#  #Wait Until JupyterLab Code Cell Is Not Active
#  Run Cell And Check Output  print("done")  done
#  Capture Page Screenshot
#
#  #Get the text of the last output cell
#  #${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
#  #Should Not Match  ${output}  ERROR*

Real Stress Test
  [Tags]  CPU StressTest
  Wait for JupyterLab Splash Screen  timeout=60
  Maybe Close Popup
  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document
  Close Other JupyterLab Tabs
  Capture Page Screenshot
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/erwangranger/PublicNotebooks.git
  Click Element  xpath://div[.="CLONE"]
  Sleep  10
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  PublicNotebooks/CPU.Stress.1.core.ipynb
  Click Element  xpath://div[.="Open"]
  Wait Until CPU.Stress.1.core.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs
  Sleep  5
  Capture Page Screenshot
  Open With JupyterLab Menu  Run  Run All Cells
  Capture Page Screenshot
  Wait Until JupyterLab Code Cell Is Not Active  timeout=300
  Capture Page Screenshot
  Run Cell And Check Output  print("done")  done
  Capture Page Screenshot
  JupyterLab Code Cell Error Output Should Not Be Visible
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*
  Add and Run JupyterLab Code Cell in Active Notebook  !rm -rf ~/Untitled*
  Add and Run JupyterLab Code Cell in Active Notebook  !rm -rf  ~/PublicNotebooks/
  Capture Page Screenshot

Can Close Notebook when done
  Clean Up Server
  Stop JupyterLab Notebook Server
  # Capture Page Screenshot
  # Go To  ${ODH_DASHBOARD_URL}
