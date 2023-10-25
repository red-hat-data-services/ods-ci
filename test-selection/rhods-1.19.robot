####################################################################################################################################################
# Test selection for RHODS 1.19:
# - Defines individual tests or full tests suites specific to RHODS RHODS 1.19
# - Run with: sh run_robot_test.sh --extra-robot-args '--argumentfile test-selection/rhods-1.19.robot'
# - Related docs:
#   - Robot Framework argument files: http://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#argument-files
#   - https://jperala.fi/2020/03/25/how-to-run-robot-framework-tests-from-command-line/
################################################ ###################################################################################################
# Included tests by tag:
-i ODS-1862
-i ODS-644

# Should we have tags for test suites and/or components?
# -i Jupyter
# -i Suite-ODS-Dashboard-Settings
