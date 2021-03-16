# ODS-CI

ODH CI is a framework to test Red Hat Open Data Science features and functionality
using QE tiered testing.

# Requirements
  Fedora or CentOS that supports chrome drivers
  `lsb_release` binary
    - Provided by redhat-lsb-core in RPM based
    - This is used to query your distribution so that the appropriate webdriver binary can be added to you `PATH` correctly


# Quick Start
  1. Create a variables for all of the global test values
     ```bash
     # Create the initial test variables from the example template variables file
     cp test-variables.yml.example test-variables.yml
     ```

  1. Edit the test variables file to include information required for this test run.
     You will need to add info required for test execution:

     * URLs based on the test case you are executing
       ** OpenShift Console
       ** Open Data Hub Dashboard
       ** JupyterHub
     * Test user credentials
     * Browser webdriver to use for testing


  1. Run this script that will create the virtual environment, install the required packages and kickoff the Robot test suite
    ```bash
    sh run_robot_test.sh
    ```
    This script is a wrapper for creating the python virtual environment and running the Robot Framework CLI.  You can run any of the test cases by creating the python virual environment, install the packages in requirements.txt and running the `robot` command directly


## License

This project is open sourced under MIT License.
