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
    ...     logging.debug("debug message")
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
        assert util.execute_command("true") == ""

    def test_fail(self):
        assert util.execute_command("false") == ""

    def test_stdout(self):
        assert util.execute_command("echo stdout") == "stdout\n"

    def test_stderr(self):
        assert util.execute_command("echo stderr >&2") == "stderr\n"

    def test_output_printing_spaces(self):
        with contextlib.redirect_stdout(io.StringIO()) as output:
            assert util.execute_command("echo hello world") == "hello world\n"
        assert output.getvalue() == ">: hello world\n"

    def test_output_printing_tab(self):
        with contextlib.redirect_stdout(io.StringIO()) as output:
            # use printf, not the shell builtin, nor echo binary, because some shells (e.g. /bin/sh on Ubuntu) don't support -e
            #  and the echo binary on macOS also does not support -e
            assert util.execute_command("printf '%b\n' 'hello\tworld'") == "hello\tworld\n"
        assert output.getvalue() == ">: hello   world\n"

    def test_string_cmd(self):
        assert util.execute_command("echo hello world", print_stdout=False) == "hello world\n"

    def test_list_cmd_single_list_item(self):
        assert util.execute_command(["echo hello world"], print_stdout=False) is None

    def test_list_cmd_multiple_list_items(self):
        # List arguments are executed directly, without shell parsing.
        assert util.execute_command(["echo", "hello", "world"], print_stdout=False) == "hello world\n"

    def test_list_cmd_special_characters_executed_verbatim(self):
        # Commit 92ecba28 passes oc login arguments directly so passwords with
        # shell metacharacters are not interpreted. Redaction must not alter that.
        password = "k#D7)10%9R?Ig9Bp"
        assert util.execute_command(["printf", "%s", password], print_stdout=False) == password

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


class TestRedactCommand(unittest.TestCase):
    def test_list_password_flag(self):
        cmd = ["oc", "login", "-u", "kubeadmin", "-p", "s3cr3t!", "https://api.example:6443"]
        redacted = util.redact_command(cmd)
        assert redacted == ["oc", "login", "-u", "kubeadmin", "-p", util.REDACTED, "https://api.example:6443"]
        assert cmd[5] == "s3cr3t!"  # the original command is left untouched

    def test_string_password_flag(self):
        redacted = util.redact_command("oc login -u kubeadmin --password s3cr3t! https://api.example:6443")
        assert "s3cr3t!" not in redacted
        assert "kubeadmin" in redacted

    def test_from_literal_secret(self):
        redacted = util.redact_command(
            "oc create secret generic openid-idp-client-secret --from-literal=clientSecret=abc123 -n openshift-config"
        )
        assert "abc123" not in redacted
        assert "--from-literal=clientSecret=*****" in redacted

    def test_quoted_from_literal_value(self):
        redacted = util.redact_command('cmd --from-literal=AWS_SECRET_ACCESS_KEY="top secret"')
        assert "top secret" not in redacted

    def test_url_credentials(self):
        redacted = util.redact_command("git clone https://user:token@github.com/org/repo.git")
        assert "https://user:*****@github.com/org/repo.git" in redacted
        assert "token@" not in redacted

    def test_execute_command_logs_redacted(self):
        with capture_logging(logging.INFO, formatter=logging.Formatter("%(message)s")) as string_io:
            util.execute_command(["echo", "-p", "s3cr3t!"], print_stdout=False)
        log_output = string_io.getvalue()
        assert "CMD:" in log_output
        assert "s3cr3t!" not in log_output

    def test_json_response_body(self):
        body = '{"client_id": "abc", "client_secret": "s3cr3t", "registration_access_token": "JWT123"}'
        redacted = util.redact_text(body)
        assert "s3cr3t" not in redacted
        assert "JWT123" not in redacted
        assert '"client_id": "abc"' in redacted

    def test_quoted_assignment_with_spaces(self):
        redacted = util.redact_command('curl -d "password=alpha beta" https://auth/token')
        assert "alpha" not in redacted
        assert "beta" not in redacted

    def test_argv_assignment_with_spaces(self):
        redacted = util.redact_command(
            ["oc", "create", "secret", "generic", "x", "--from-literal=clientSecret=alpha beta"]
        )
        assert "alpha" not in " ".join(redacted)
        assert "beta" not in " ".join(redacted)

    def test_json_escaped_quote(self):
        body = '{"client_secret":"abc\\"def","status":"keep"}'
        redacted = util.redact_text(body)
        assert "abc" not in redacted
        assert "def" not in redacted
        assert "keep" in redacted
