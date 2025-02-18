# How To Create An ods-ci Release

As an example, for RHODS release 1.21-21 we would create a branch release-1.21-21 and add a 1.21 tag (without -21).

## Steps:
    Use the main repo instead of a fork
    1. git clone https://github.com/red-hat-data-services/ods-ci

        In case you had the repo already cloned, remember to pull new changes from master
        1. git checkout master
        2. git pull

    Remove “stable” tag from local and remote
    2. git tag -d stable
    3. git push --delete origin stable 

    Create a branch and tag for this release.
    Note that the tag format should be x.y.z (without -16). This is required in order to make the automatic release notes work properly
    4. git checkout -b release-1.21-21
    5. git tag 1.21

    Add also the “stable” tag (ISV team needs it) 
    6. git tag stable

    Finally, push branch and tags
    7. git push --set-upstream origin release-1.21-21
    8. git push --tags

    Go to GitHub and publish the release
    9. Go to https://github.com/red-hat-data-services/ods-ci/tags
    10. In tag 1.21, click on the three dots and then Create release
    11. Release title: 1.21
    12. Auto-generate release notes
    13. Publish release


# How to update dependencies with Poetry

[Poetry](https://python-poetry.org) is a tool for dependency management and packaging in Python. When using Poetry, we have a `poetry.lock` file specifying which exact versions of all dependencies we should be using. This file is not updated automatically and should instead be regularly updated by contributors.
If we only want to get the latest version(s) of our dependencies **that respect the requirements**, we can run `poetry update` and then commit the updated `poetry.lock` to the repo.


Note that many dependencies in `pyproject.toml` are specified with the caret (`^`) operator, which binds the dependency to a specific major version. This means that writing `robotframework = ^5` is equivalent to `robotframework = >=5,<6`. The consequence of this is that running only `poetry update` will **never** update robotframework to version 6 or higher.
If a specific dependency needs to be updated to an higher major version then, you should first make sure that the definition in `pyproject.toml` is updated to allow that major version to be installed. You can read more about dependency specification with Poetry [here](https://python-poetry.org/docs/dependency-specification/)


To give a pratical example, these are the steps that we would take to upgrade to Robot Framework 6:

    1. Install Poetry if not already installed: `url -sSL https://install.python-poetry.org | python3 -`
    2. Clone ods-ci and cd into the root of the project
    3. Open `pyproject.toml`
    4. Update `robotframework = "^5"` to `robotframework = "^6"` (this won't allow versions <6 anymore, and will instead fetch any version >=6 and <7)
    5. Save `pyproject.toml`
    6. In the root of the project, run `poetry update`
    7. Assuming all dependencies are resolved, commit the updated `pyproject.toml` and `poetry.lock` files back to ods-ci.

All these operations could also be carried out with the [`poetry add` command](https://python-poetry.org/docs/cli/#add), which doesn't require to manually modify the contraint in `pyproject.toml`, i.e.:

    1. Clone ods-ci and cd into the root of the project
    2. Run `poetry add robotframework@^6.0.0`
    3. Run `poetry update`
    4. Assuming all dependencies are resolved, commit the updated `pyproject.toml` and `poetry.lock` files back to ods-ci.
