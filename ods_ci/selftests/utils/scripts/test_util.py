import contextlib
import doctest
import functools
import io
import logging
import subprocess
import sys
import unittest
import unittest.mock

import pytest

from ods_ci.utils.scripts import util


@contextlib.contextmanager
def capture_logging(level: int | None = None, formatter: logging.Formatter | None = None):
    """Temporarily replaces all logging handlers with a StringIO logging handler.

    Note: Pytest has the `caplog` fixture (`LogCaptureFixture` class) which functions similarly.

    Usage example:

    >>> with capture_logging(logging.DEBUG, formatter=logging.Formatter("%(message)s")) as string_io:
    ...     logging.debug('debug message')
    >>> print(string_io.getvalue(), end="")
    debug message
    """
    string_io = io.StringIO()
    ch = logging.StreamHandler(string_io)
    if level:
        ch.setLevel(level)

    if formatter:
        ch.setFormatter(formatter)

    handlers = logging.root.handlers
    logging.root.handlers = []
    logging.root.addHandler(ch)
    try:
        yield string_io
    finally:
        logging.root.removeHandler(ch)
        logging.root.handlers = handlers


# https://stackoverflow.com/questions/5681330/using-doctests-from-within-unittests
def load_tests(loader: unittest.TestLoader, tests: unittest.TestSuite, pattern: str) -> unittest.TestSuite:
    tests.addTest(doctest.DocTestSuite())
    return tests


class TestExecuteCommand(unittest.TestCase):
    def test_failed_to_run(self):
        # without mocking, the test would be sensitive to `/bin/sh --version`
        with unittest.mock.patch.object(
            subprocess.Popen, "__init__", new=functools.partialmethod(subprocess.Popen.__init__, executable="/bin/bash")
        ):
            assert "No such file or directory" in util.execute_command("/this-file-does-not-exist", print_stdout=False)

    def test_success(self):
        assert util.execute_command("/bin/true") == ""

    def test_fail(self):
        assert util.execute_command("/bin/false") == ""

    def test_stdout(self):
        assert util.execute_command("echo stdout") == "stdout\n"

    def test_stderr(self):
        assert util.execute_command("echo stderr >&2") == "stderr\n"

    def test_string_cmd(self):
        assert util.execute_command("echo hello world", print_stdout=False) == "hello world\n"

    def test_list_cmd(self):
        # this is surprising, but it's what subprocess.Popen does
        assert util.execute_command(["echo", "hello", "world"], print_stdout=False) == "\n"

    def test_multiple_output_lines(self):
        python = sys.executable
        assert util.execute_command(f"""{python} -c 'print("a\\n"*13, end="")'""", print_stdout=False) == "a\n" * 13

    @pytest.mark.slow
    def test_many_long_output_lines(self):
        python = sys.executable
        assert (
            util.execute_command(f"""{python} -c 'print(("a" * 40 + "\\n")*1_000_000, end="")'""", print_stdout=False)
            == ("a" * 40 + "\n") * 1_000_000
        )
