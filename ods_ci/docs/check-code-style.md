# Intro

Code contributed to this repo must follow the _[ODS-CI RobotFramework Style Guide](https://docs.google.com/document/d/11ZJOPI1uq-0Wl6a2V8fkAv_TQhfzp9t_IjXAheaJxmQ/edit?usp=sharing)_

This document explains how to verify the Robot Framework code using the [robocop](https://robocop.readthedocs.io)  and Python code using [Black](https://black.readthedocs.io/en/stable/usage_and_configuration/index.html) code analyzer. Also, how to automatically format some Robot Framework issues using the [robotidy](https://robotidy.readthedocs.io) and Python code issue using [Black](https://black.readthedocs.io/en/stable/usage_and_configuration/index.html) code formatter.


# Analyze the code using Robocop

Robocop is a tool that performs static code analysis of Robot Framework code.

- Install the required libraries:

  ```
  pip install -r requirements-dev.txt

  # If you had them already but want to force upgrade to the latest version:
  pip install --upgrade --force-reinstall -r requirements-dev.txt
  ```

- Analyze one file or folder:
  ```
  # Run the command from the root folder in order to
  # the .robocop configuration to be used
  cd ods-ci

  # Check a file
  robocop tests/Tests/.../203__alerts.robot

  # Check a folder
  robocop tests/Tests/.../200__metrics/

  # Robocop will return a list of issues that
  # need to be fixed before committing the code

  # With "--report all" can opbtain more info (issues by id, rules by severity, ...):
  robocop --report all tests/
  ```

- Excluding robocop rules:
  - In the [.robocop](https://github.com/red-hat-data-services/ods-ci/blob/main/.robocop) configuration file you can see the rules we have already disabled.
  -  You can disable a rule for a particular line of code adding a comment like this (more examples [here](https://robocop.readthedocs.io/en/stable/including_rules.html#ignore-rule-from-source-code)):
     ```
     Some Keyword  # robocop: disable
     ```


 # Automatically format the code using Robotidy

 Robotidy is a tool for auto formatting Robot Framework code. It runs various [transformers](https://robotidy.readthedocs.io/en/latest/transformers/index.html) to format the code. Transformers are enabled and configured in the [robotidy.toml](https://github.com/red-hat-data-services/ods-ci/blob/main/ods_ci/robotidy.toml) config file at the root folder.

 - Install the required libraries
    ```
    pip install -r requirements-dev.txt
    ```

- Format a file using all configured transformers:
  ```
  # Run the command from the root folder in order to
  # the robitidy.toml configuration to be used
  cd ods-ci

  # Show formatting changes without modifying the file:
  robotidy tests/Tests/.../203__alerts.robot

  # Show formatting changes AND modify the file:
  robotidy tests/Tests/.../203__alerts.robot --overwrite
  ```

- Some transformers are not enabled because they aren't 100% reliable. We can run them manually if we want:
  ```
  # Example for running the RenameKeywords transformer:
  #  - We set --config /dev/null to force not to use the default config file (robotidy.toml)
  #  - Warning: RenameKeywords has only basic support for keywords with embedded variables - use it on your own risk
  robotidy --config /dev/null --transform RenameKeywords  tests/Resources/Page/ODH/ODHDashboard/ODHDashboard.robot --diff --no-overwrite
  robotidy --config /dev/null --transform RenameKeywords  tests/Resources/Page/ODH/ODHDashboard/ODHDashboard.robot --diff --overwrite
  ```

# Analyze the code using Black

[Black](https://black.readthedocs.io/en/stable/usage_and_configuration/index.html) is the uncompromising Python code formatter. By using it, you agree to cede control over the minutiae of hand-formatting

- Install the required libraries:
  ```
  pip install -r requirements-dev.txt

  # If you had them already but want to force upgrade to the latest version:
  pip install --upgrade --force-reinstall -r requirements-dev.txt

  # It requires Python 3.6.0+ to run. Once Black is installed, you will have a new command-line tool called black available to you in your shell, and you’re ready to start!
  ```

- Analyze one file or folder:
  ```
  # Run the command from the root folder in order to
  cd ods-ci

  # Check single file
  black --check --diff utils/scripts/SplitSuite.py

  # Check a folder
  black --check --diff utils/

  #This shows what needs to be done to the file but doesn’t modify the file
  ```

- Excluding black formatting

  - You can ignore a rule for a particular line of code adding a comment like this.
     ```
      python statement # fmt: skip
     ```

# Automatically format the code using Black
  - Format one file or folder:
  ```
  # Run the command from the root folder in order to
  cd ods-ci

  # format single file
  black utils/scripts/SplitSuite.py

  # format a folder
  black  utils/

  #This shows what needs to be done to the file but doesn’t modify the file
  ```
