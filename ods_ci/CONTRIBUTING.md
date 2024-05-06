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
  - Before committing the code, verify that it is formatted following the _ODS-CI Robot Framework Style Guide_ (see [how](https://github.com/red-hat-data-services/ods-ci/blob/main/ods_ci/docs/check-code-style.md)
)
  - Add your changes to the commit
    ```
    git add tests/Tests/200__monitor_and_manage/200__metrics/203__alerts.robot
    ```

   - Sign off your commit using the -s, --signoff option. Write a good commit message (see [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/))
    ```
     git commit -s -m "Add alerts tests"
     ```

Please bear in mind that each commit should contain just the necessary changes and relevant to the particular work.
Separate parts of works should be either in a separate PRs or in a separate commits at least if that makes sense for your scenario.

- [Create a personal access token in Github](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) to be able to push your changes

- Push your changes:  ```git push```

- Send a PR to ods-ci using GitHub's web interface

- If the PR can't be merged, rebase your branch against `main`:
  ```
  git remote add upstream https://github.com/red-hat-data-services/ods-ci
  git fetch upstream main
  git checkout add-test-ods-542-alerts
  git rebase upstream/main
  git push origin add-test-ods-542-alerts --force
  ```

- Test your PR executing the changed code and other relevant parts which make sense to assure your changes work as expected.

- Participate in the feedback of your PR until is merged
