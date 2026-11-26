"""Tests for install_nfd.sh NFD image selection logic.

Validates that the script selects the correct NFD operand image based on
the detected OCP version:
- OCP 4.x (known minor): uses the pinned image digest from the map
- OCP 4.x (unknown minor): falls back to 4.17 digest with a warning
- OCP 5.0+: omits spec.operand.image so the NFD operator uses its managed
  default via NODE_FEATURE_DISCOVERY_IMAGE env var
- Unknown major version: exits with an error before mutating the template
"""

import os
import shutil
import stat
import subprocess
import tempfile
import textwrap
import unittest

# Path to the real NFD install directory
_NFD_DIR = os.path.join(
    os.path.dirname(__file__),
    os.pardir,
    os.pardir,
    os.pardir,
    os.pardir,
    os.pardir,
    os.pardir,
    "tasks",
    "Resources",
    "Provisioning",
    "GPU",
    "NFD",
)
_NFD_DIR = os.path.normpath(_NFD_DIR)


def _setup_mock_env(tmp_dir, ocp_version):
    """Create a mock environment to run install_nfd.sh without a live cluster.

    Mocks ``oc``, ``sleep``, and creates stub YAML files so the script can
    run to completion (or fail as expected) purely on version-selection logic.

    Returns the path to the temporary NFD directory containing the script copy.
    """
    mock_bin = os.path.join(tmp_dir, "bin")
    os.makedirs(mock_bin, exist_ok=True)

    # --- mock oc --------------------------------------------------------
    oc_path = os.path.join(mock_bin, "oc")
    with open(oc_path, "w") as f:
        f.write(
            textwrap.dedent(f"""\
            #!/bin/bash
            if [[ "$1" == "version" ]]; then
                echo '{{"openshiftVersion": "{ocp_version}"}}'
            fi
            exit 0
        """)
        )
    os.chmod(oc_path, stat.S_IRWXU)

    # --- mock sleep -----------------------------------------------------
    sleep_path = os.path.join(mock_bin, "sleep")
    with open(sleep_path, "w") as f:
        f.write("#!/bin/bash\nexit 0\n")
    os.chmod(sleep_path, stat.S_IRWXU)

    # --- copy script and templates --------------------------------------
    nfd_work = os.path.join(tmp_dir, "NFD")
    os.makedirs(nfd_work, exist_ok=True)

    for name in ("install_nfd.sh", "nfd_deploy.yaml"):
        shutil.copy2(os.path.join(_NFD_DIR, name), nfd_work)

    # Create stub YAML files the script tries to oc-apply
    for name in ("nfd_operator.yaml", "sriov_operator.yaml", "sriov_network_node_policy.yaml"):
        stub = os.path.join(nfd_work, name)
        if not os.path.exists(stub):
            with open(stub, "w") as f:
                f.write("# stub\n")

    return nfd_work, mock_bin


def _run_install_nfd(ocp_version):
    """Run install_nfd.sh with a mocked OCP version and return (rc, stdout, deploy_yaml)."""
    with tempfile.TemporaryDirectory() as tmp_dir:
        nfd_work, mock_bin = _setup_mock_env(tmp_dir, ocp_version)
        env = os.environ.copy()
        env["PATH"] = mock_bin + os.pathsep + env["PATH"]

        result = subprocess.run(
            ["bash", os.path.join(nfd_work, "install_nfd.sh")],
            check=False,
            capture_output=True,
            text=True,
            env=env,
            cwd=nfd_work,
            timeout=30,
        )

        deploy_path = os.path.join(nfd_work, "nfd_deploy.yaml")
        deploy_content = ""
        if os.path.exists(deploy_path):
            with open(deploy_path) as f:
                deploy_content = f.read()

        return result.returncode, result.stdout, deploy_content


class TestNFDImageSelection(unittest.TestCase):
    """Regression tests for NFD operand image selection in install_nfd.sh."""

    def test_known_4x_version_uses_pinned_digest(self):
        """OCP 4.17 should use the pinned sha256 digest from the image map."""
        rc, stdout, deploy = _run_install_nfd("4.17.3")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("Using image SHA for 4.17", stdout)
        self.assertIn("sha256:", deploy)
        self.assertNotIn("<imageUrl>", deploy)

    def test_known_4x_latest_version(self):
        """OCP 4.22 (latest in map) should use its own pinned digest."""
        rc, stdout, deploy = _run_install_nfd("4.22.1")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("Using image SHA for 4.22", stdout)
        self.assertIn("sha256:", deploy)
        self.assertNotIn("<imageUrl>", deploy)

    def test_unknown_4x_minor_falls_back_to_417(self):
        """OCP 4.99 (unknown minor) should fall back to 4.17 with a warning."""
        rc, stdout, deploy = _run_install_nfd("4.99.0")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("WARNING", stdout)
        self.assertIn("4.17", stdout)
        self.assertIn("sha256:", deploy)
        self.assertNotIn("<imageUrl>", deploy)

    def test_ocp_50_omits_operand_image(self):
        """OCP 5.0 should omit operand.image so the operator uses its managed default."""
        rc, stdout, deploy = _run_install_nfd("5.0.0")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("major version >= 5", stdout)
        self.assertIn("managed default", stdout)
        # The <imageUrl> placeholder line should be removed entirely
        self.assertNotIn("<imageUrl>", deploy)
        # The image field should not appear with any digest
        self.assertNotIn("sha256:", deploy)
        # The rest of the operand spec should remain
        self.assertIn("imagePullPolicy", deploy)

    def test_ocp_60_omits_operand_image(self):
        """OCP 6.0 (future major) should also omit operand.image."""
        rc, stdout, deploy = _run_install_nfd("6.0.0")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("major version >= 5", stdout)
        self.assertNotIn("<imageUrl>", deploy)
        self.assertNotIn("sha256:", deploy)

    def test_unsupported_major_version_fails_fast(self):
        """OCP 3.x should fail with an error, not silently apply a wrong image."""
        rc, stdout, _deploy = _run_install_nfd("3.11.0")
        self.assertNotEqual(rc, 0, "Script should fail for unsupported major version")
        self.assertIn("ERROR", stdout)
        self.assertIn("Unsupported", stdout)

    def test_no_template_mutation_on_unsupported_version(self):
        """An unsupported version must not mutate the deploy template before failing."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            nfd_work, mock_bin = _setup_mock_env(tmp_dir, "3.11.0")
            env = os.environ.copy()
            env["PATH"] = mock_bin + os.pathsep + env["PATH"]

            # Read template before running
            deploy_path = os.path.join(nfd_work, "nfd_deploy.yaml")
            with open(deploy_path) as f:
                before = f.read()

            subprocess.run(
                ["bash", os.path.join(nfd_work, "install_nfd.sh")],
                check=False,
                capture_output=True,
                text=True,
                env=env,
                cwd=nfd_work,
                timeout=30,
            )

            with open(deploy_path) as f:
                after = f.read()

            self.assertEqual(before, after, "Template was mutated despite unsupported version")

    def test_malformed_version_empty_fails_fast(self):
        """Empty version string should fail, not silently apply a wrong image."""
        rc, stdout, _deploy = _run_install_nfd("")
        self.assertNotEqual(rc, 0, "Script should fail for empty version")
        self.assertIn("ERROR", stdout)

    def test_malformed_version_non_numeric_fails_fast(self):
        """Non-numeric version should fail, not silently apply a wrong image."""
        rc, stdout, _deploy = _run_install_nfd("abc.def.ghi")
        self.assertNotEqual(rc, 0, "Script should fail for non-numeric version")
        self.assertIn("ERROR", stdout)

    def _run_twice(self, ocp_version):
        """Run install_nfd.sh twice and return (rc1, deploy_after_1, rc2, deploy_after_2)."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            nfd_work, mock_bin = _setup_mock_env(tmp_dir, ocp_version)
            env = os.environ.copy()
            env["PATH"] = mock_bin + os.pathsep + env["PATH"]
            cmd = ["bash", os.path.join(nfd_work, "install_nfd.sh")]
            deploy_path = os.path.join(nfd_work, "nfd_deploy.yaml")

            r1 = subprocess.run(cmd, check=False, capture_output=True, text=True, env=env, cwd=nfd_work, timeout=30)
            with open(deploy_path) as f:
                after_first = f.read()

            r2 = subprocess.run(cmd, check=False, capture_output=True, text=True, env=env, cwd=nfd_work, timeout=30)
            with open(deploy_path) as f:
                after_second = f.read()

            return r1, after_first, r2, after_second

    def test_repeated_render_4x_is_idempotent(self):
        """Running install_nfd.sh twice for OCP 4.17 should not corrupt the template."""
        r1, after_first, r2, after_second = self._run_twice("4.17.3")
        self.assertEqual(r1.returncode, 0, f"First run failed: {r1.stdout}")
        self.assertEqual(r2.returncode, 0, f"Second run failed: {r2.stdout}")
        self.assertEqual(after_first, after_second, "Template changed between runs")
        self.assertIn("sha256:", after_second)

    def test_repeated_render_5x_is_idempotent(self):
        """Running install_nfd.sh twice for OCP 5.0 should not corrupt the template."""
        r1, after_first, r2, after_second = self._run_twice("5.0.0")
        self.assertEqual(r1.returncode, 0, f"First run failed: {r1.stdout}")
        self.assertEqual(r2.returncode, 0, f"Second run failed: {r2.stdout}")
        self.assertEqual(after_first, after_second, "Template changed between runs")
        self.assertNotIn("sha256:", after_second)
        self.assertIn("imagePullPolicy", after_second)
