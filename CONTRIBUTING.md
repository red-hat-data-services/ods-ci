# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change.


- Configure name and email in git:

  ```
  git config --global user.name "Your Name"
  git config --global user.email "youremail@yourdomain.com"
  ```

- Fork this repo

- In your fork, create a branch for your feature

   ```git checkout -b add-test-ods-542-alerts```

- Develop your feature and create a git commit:
  - Add your changes to the commit
    ```
    git add tests/Tests/200__monitor_and_manage/200__metrics/203__alerts.robot
    ```
   - Check the code formatting following the steps at [check-code-style.md](https://github.com/red-hat-data-services/ods-ci/blob/master/docs/check-code-style.md)

   - Sign off your commit using the -s, --signoff option. Write a good commit message (see [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/))
    ```
     git commit -s -m "Add alerts tests"
     ```

- [Create a personal access token in Github](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) to be able to push your changes

- Push your changes:  ```git push```

- Send a PR to ods-ci using Github's web interface

- Test your PR in Jenkins using the rhods-ci-pr-test pipeline
   - https://opendatascience-jenkins-csb-rhods.apps.ocp-c1.prod.psi.redhat.com/job/rhods-ci-pr-test
   - Log in if required
   - Build with Parameters (if you don't see this option contact the QE team)
     - Set the PR id (e.g. 42) in ODS_GIT_REPO_PULL_REQUEST_ID
     - Select TEST_CLUSTER
     - Build

- Once finished, add a comment to the PR with the test run results, and a link like in the example below:

  ```
  https://opendatascience-jenkins-csb-rhods.apps.ocp-c1.prod.psi.redhat.com/job/rhods-ci-pr-test/49/console

  Result: passing except for the Git plugin missing from the minimal image
  ```

- Participate in the feedback of your PR until is merged
