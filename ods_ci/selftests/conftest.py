from __future__ import annotations

import os
from typing import TYPE_CHECKING

import testcontainers.core.container

if TYPE_CHECKING:
    from pytest import ExitCode, Session

# We'd get selinux violations with podman otherwise, so either ryuk must be privileged, or we need to disable selinux.
# https://github.com/testcontainers/testcontainers-java/issues/2088#issuecomment-1169830358
os.environ["TESTCONTAINERS_RYUK_PRIVILEGED"] = "true"


# https://docs.pytest.org/en/latest/reference/reference.html#pytest.hookspec.pytest_sessionfinish
def pytest_sessionfinish(session: Session, exitstatus: int | ExitCode) -> None:
    testcontainers.core.container.Reaper.delete_instance()
