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

# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change.


- Configure name and email in git:

  ```
  git config --global user.name "Your Name"
  git config --global user.email "youremail@yourdomain.com"
  ```

- Fork this repo

- In your fork, create a branch for your feature

   ```git checkout -b add-contributing-section-to-readme```

- Develop your feature and create a git commit:
  - Add your changes to the commit

     ```git add README.md```

   - Sign off your commit using the -s, --signoff option. Write a good commit message (see [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/))


     ```git commit -s -m "Add Contributing section to Readme"```

- [Create a personal access token in Github](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) to be able to push your changes

- Push your changes:  ```git push```

- Send a PR to ods-ci using Github's web interface 

- Test your PR in Jenkins using the rhods-ci-pr-test pipeline
   - https://opendatascience-jenkins-csb-rhods.apps.ocp4.prod.psi.redhat.com/job/rhods-ci-pr-test
   - Log in if required
   - Build with Parameters (if you don't see this option contact the QE team)
     - Set the PR id (e.g. 42) in ODS_GIT_REPO_PULL_REQUEST_ID
     - Select TEST_CLUSTER
     - Build
   
- Once finished, add a comment to the PR with the test run results and a link:

  - Example:

  ```
  https://opendatascience-jenkins-csb-rhods.apps.ocp4.prod.psi.redhat.com/job/rhods-ci-pr-test/49/console
      
  Result: passing except for the Git plugin missing from the minimal image
  ```

- Participate in the feedback of your PR until is merged

## License

This project is open sourced under MIT License.
