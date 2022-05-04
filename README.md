# ODS-CI

ODS-CI is a framework to test Red Hat Open Data Science features and functionality
using QE tiered testing.

# Requirements
  Linux distribution that supports Selenium automation of a chromium web browser using [ChromeDriver](https://chromedriver.chromium.org)
  * chromedriver binaries can be downloaded from https://chromedriver.chromium.org/downloads. The chromedriver version must match the installed version of chromium/google-chrome

# Quick Start
  1. Create a variables file for all of the global test values
     ```bash
     # Create the initial test variables from the example template variables file
     cp test-variables.yml.example test-variables.yml
     ```

  1. Edit the test variables file to include information required for this test run.
     You will need to add info required for test execution:

     * URLs based on the test case you are executing.<br>
        ** OpenShift Console.<br>
        ** Open Data Hub Dashboard.<br>
        ** JupyterHub.<br>
     * Test user credentials.
     * Browser webdriver to use for testing.


  1. Run this script that will create the virtual environment, install the required packages and kickoff the Robot test suite
    ```bash
    sh run_robot_test.sh
    ```
    This script is a wrapper for creating the python virtual environment and running the Robot Framework CLI.  You can run any of the test cases by creating the python virual environment, install the packages in requirements.txt and running the `robot` command directly

# Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

# ODS-CI Container Image
See build [README](build/README.md) on how you can build a container to run ODS-CI automation in OpenShift.

# License
This project is open sourced under MIT License.
