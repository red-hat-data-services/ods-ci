# ODS-CI

ODH CI is a framework to test Red Hat Open Data Science features and functionality
using QE tiered testing.

# Requirements
  Fedora or CentOS that supports chrome drivers
  `lsb_release` binary
    - Provided by redhat-lsb-core in RPM based


# Quick Start
  1. Create a variables for all of the global test values
     ```bash
     # Create the initial test variables from the example template variables file
     cp test-variables.yml.example test-variables.yml
     ```

  1. Edit the test variables file to include information required for this test run.
     You will need to add info required for test execution:

     * openshift console url
     * user credentials 
     * Browser to test again


  1. Run this script that will create the virtual environment, install the required packages and kickoff the Robot test suite
    ```bash
    sh run_robot_test.sh
    ```



## License

This project is open sourced under MIT License.
