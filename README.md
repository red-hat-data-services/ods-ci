# ODS-CI
ODS-CI is a framework to test Red Hat Open Data Science features and functionality
using QE tiered testing.
# Requirements
  Linux distribution that supports Selenium automation of a chromium web browser using [ChromeDriver](https://chromedriver.chromium.org)
  * chromedriver binaries can be downloaded from https://chromedriver.chromium.org/downloads. The chromedriver version must match the installed version of chromium/google-chrome

  [Poetry](https://python-poetry.org/docs/#installation) installed and added to your $PATH

# Quick Start
  1. Create a variables file for all of the global test values
     ```bash
     # Create the initial test variables from the example template variables file
     cp test-variables.yml.example test-variables.yml
     ```
  1. Edit the test variables file to include information required for this test run.
     You will need to add info required for test execution:
     * URLs based on the test case you are executing.<br>
        *   OpenShift Console.<br>
        *   Open Data Hub Dashboard.<br>
        *   JupyterHub.<br>
     * Test user credentials.
     * Browser webdriver to use for testing.

  1. Run this script that will create the virtual environment, install the required packages and kickoff the Robot test suite.
  ```bash
     # running all the tests 
     sh ods_ci/run_robot_test.sh 

     # running Smoke test suite via tag
     sh ods_ci/run_robot_test.sh --include Smoke 

     # running a specific test via tag
     sh ods_ci/run_robot_test.sh --include ODS-XYZ 
   ```
   
   * This run_robot_test.sh is a wrapper for creating the python virtual environment and running the Robot Framework CLI.   
   * The wrapper script has several arguments and you can find details in the dedicated document file. See [run_args.md](ods_ci/docs/RUN_ARGUMENTS.md)
   * As alternative, you can run any of the test cases by creating the python virual environment, install the packages in [poetry.lock](poetry.lock) and running the `robot` command directly


# Contributing
See [CONTRIBUTING.md](ods_ci/CONTRIBUTING.md)
# ODS-CI Container Image
See build [README](ods_ci/docs/ODS-CI-IMAGE-README.md) on how you can build and use a container to run ODS-CI automation in OpenShift.
# License
This project is open sourced under MIT License.
