# Generate test configuration yaml file
Script to generate test config file - test-variables.yml

## Prerequisites
Python 3.x

## How to Run:
1. Change directory to the project directory.

```
# cd ods-ci
```

2. Now run the script.

```
# python3 utils/scripts/testconfig/generateTestConfigFile.py -u <gitlab_user> -p <gitlab_password> -t modh-qe-4
```

In case if you have already cloned config repo(odhcluster.git), then use the command,

```
# python3 utils/scripts/testconfig/generateTestConfigFile.py -s -t <test_cluster> -d <directory where config repo is cloned>
```

## Usage

```
# python3 utils/scripts/testconfig/generateTestConfigFile.py -h
