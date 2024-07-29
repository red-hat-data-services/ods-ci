import pytest
import testcontainers.core.container
import testcontainers.core.waiting_utils

from . import ROOT_PATH, docker_utils


@pytest.mark.slow
def test_poetry_venv_initialization():
    image = "quay.io/modh/odsci-jenkins:latest"
    user = "build"
    uid = 1000

    poetry_init_command = "./run_robot_test.sh --skip-oclogin true --test-variables-file test-variables-odh-overwrite.yml --extra-robot-args '--runemptysuite --include []'"

    container = testcontainers.core.container.DockerContainer(image=image)
    container.with_env("POETRY_PYPI_MIRROR_URL", "")
    container.with_command("/bin/sh -c 'sleep infinity'")

    with container.start():
        docker_utils.container_cp(container.get_wrapped_container(), str(ROOT_PATH), "/", user=uid)
        result = docker_utils.container_exec(
            container.get_wrapped_container(),
            user=user,
            workdir="/ods-ci/ods_ci",
            stream=True,
            cmd=["/bin/sh", "-c", poetry_init_command],
        )

        for line in result.output:
            line = line.decode("utf-8").rstrip()
            print("-->", line)

            if line.startswith("Using a pre-created virtual environment in '/home/build/.local/ods-ci/"):
                break

            if line.startswith("Installing dependencies from lock file"):
                raise AssertionError("We did not see the expected line before poetry started installing dependencies")
        else:
            raise AssertionError("We did not see the expected line")
