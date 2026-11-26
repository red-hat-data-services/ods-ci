"""Tests for install_nfd.sh NFD image selection logic.

Validates that the script selects the correct NFD operand image based on
the detected OCP version:
- OCP 4.x (known minor): uses the pinned image digest from the map
- OCP 4.x (unknown minor): falls back to 4.17 digest with a warning
- OCP 5.0+: omits spec.operand.image so the NFD operator uses its managed
  default via NODE_FEATURE_DISCOVERY_IMAGE env var
- Unknown major version: exits with an error before mutating the template
- Template is never mutated; rendering uses a unique temporary copy
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

_FAKE_4X_DIGEST = "registry.redhat.io/openshift4/ose-node-feature-discovery-rhel9@sha256:aaaa1111"


def _setup_mock_env(tmp_dir, ocp_version):
    """Create a mock environment to run install_nfd.sh without a live cluster.

    Mocks ``oc``, ``sleep``, and creates stub YAML files so the script can
    run to completion (or fail as expected) purely on version-selection logic.

    The mock ``oc apply -f FILE`` saves a copy of NFD-related applied
    content to ``$NFD_APPLIED_SAVE`` so tests can verify the rendered
    manifest even though the script cleans up its temporary file on exit.
    Only files containing ``NodeFeatureDiscovery`` are saved (the script
    also applies non-NFD stubs like sriov_operator.yaml).

    Returns ``(nfd_work, mock_bin, applied_path)`` where *applied_path* is
    the file the mock ``oc apply`` writes the applied content to.
    """
    mock_bin = os.path.join(tmp_dir, "bin")
    os.makedirs(mock_bin, exist_ok=True)

    applied_path = os.path.join(tmp_dir, "applied.yaml")

    # --- mock oc --------------------------------------------------------
    oc_path = os.path.join(mock_bin, "oc")
    with open(oc_path, "w") as f:
        f.write(
            textwrap.dedent(f"""\
            #!/bin/bash
            if [[ "$1" == "version" ]]; then
                echo '{{"openshiftVersion": "{ocp_version}"}}'
            elif [[ "$1" == "apply" && "$2" == "-f" && -f "$3" ]]; then
                if [[ -n "$NFD_APPLIED_SAVE" ]] && grep -q "NodeFeatureDiscovery" "$3" 2>/dev/null; then
                    cp "$3" "$NFD_APPLIED_SAVE"
                fi
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

    return nfd_work, mock_bin, applied_path


def _run_install_nfd(ocp_version, *, pre_render_digest=None):
    """Run install_nfd.sh with a mocked OCP version.

    Returns ``(rc, stdout, applied_yaml, template_yaml)``.
    ``applied_yaml`` is the content that ``oc apply`` received (captured by
    the mock).  ``template_yaml`` is the original template after the run
    (should be unchanged).

    If *pre_render_digest* is given, the template's ``image:`` line is
    replaced with that digest before running, simulating a checkout that
    already contains a baked-in pin.
    """
    with tempfile.TemporaryDirectory() as tmp_dir:
        nfd_work, mock_bin, applied_path = _setup_mock_env(tmp_dir, ocp_version)

        if pre_render_digest:
            tmpl = os.path.join(nfd_work, "nfd_deploy.yaml")
            with open(tmpl) as f:
                content = f.read()
            content = content.replace("image: <imageUrl>", f"image: {pre_render_digest}")
            with open(tmpl, "w") as f:
                f.write(content)

        env = os.environ.copy()
        env["PATH"] = mock_bin + os.pathsep + env["PATH"]
        env["NFD_APPLIED_SAVE"] = applied_path

        result = subprocess.run(
            ["bash", os.path.join(nfd_work, "install_nfd.sh")],
            check=False,
            capture_output=True,
            text=True,
            env=env,
            cwd=nfd_work,
            timeout=30,
        )

        applied_content = ""
        if os.path.exists(applied_path):
            with open(applied_path) as f:
                applied_content = f.read()

        template_path = os.path.join(nfd_work, "nfd_deploy.yaml")
        template_content = ""
        if os.path.exists(template_path):
            with open(template_path) as f:
                template_content = f.read()

        return result.returncode, result.stdout, applied_content, template_content


class TestNFDImageSelection(unittest.TestCase):
    """Regression tests for NFD operand image selection in install_nfd.sh."""

    # --- OCP 4.x: pinned digest selection --------------------------------

    def test_known_4x_version_uses_pinned_digest(self):
        """OCP 4.17 should use the pinned sha256 digest from the image map."""
        rc, stdout, applied, _tmpl = _run_install_nfd("4.17.3")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("Using image SHA for 4.17", stdout)
        self.assertIn("sha256:", applied)
        self.assertNotIn("<imageUrl>", applied)

    def test_known_4x_latest_version(self):
        """OCP 4.22 (latest in map) should use its own pinned digest."""
        rc, stdout, applied, _tmpl = _run_install_nfd("4.22.1")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("Using image SHA for 4.22", stdout)
        self.assertIn("sha256:", applied)
        self.assertNotIn("<imageUrl>", applied)

    def test_unknown_4x_minor_falls_back_to_417(self):
        """OCP 4.99 (unknown minor) should fall back to 4.17 with a warning."""
        rc, stdout, applied, _tmpl = _run_install_nfd("4.99.0")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("WARNING", stdout)
        self.assertIn("4.17", stdout)
        self.assertIn("sha256:", applied)
        self.assertNotIn("<imageUrl>", applied)

    # --- OCP 5+: operator-managed image ----------------------------------

    def test_ocp_50_omits_operand_image(self):
        """OCP 5.0 should omit operand.image so the operator uses its managed default."""
        rc, stdout, applied, _tmpl = _run_install_nfd("5.0.0")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("major version >= 5", stdout)
        self.assertIn("managed default", stdout)
        self.assertNotIn("<imageUrl>", applied)
        self.assertNotIn("sha256:", applied)
        self.assertNotIn("image:", applied)
        self.assertIn("imagePullPolicy", applied)

    def test_ocp_60_omits_operand_image(self):
        """OCP 6.0 (future major) should also omit operand.image."""
        rc, stdout, applied, _tmpl = _run_install_nfd("6.0.0")
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertIn("major version >= 5", stdout)
        self.assertNotIn("image:", applied)
        self.assertIn("imagePullPolicy", applied)

    # --- Unsupported / malformed versions --------------------------------

    def test_unsupported_major_version_fails_fast(self):
        """OCP 3.x should fail with an error, not silently apply a wrong image."""
        rc, stdout, _applied, _tmpl = _run_install_nfd("3.11.0")
        self.assertNotEqual(rc, 0, "Script should fail for unsupported major version")
        self.assertIn("ERROR", stdout)
        self.assertIn("Unsupported", stdout)

    def test_malformed_version_empty_fails_fast(self):
        """Empty version string should fail, not silently apply a wrong image."""
        rc, stdout, _applied, _tmpl = _run_install_nfd("")
        self.assertNotEqual(rc, 0, "Script should fail for empty version")
        self.assertIn("ERROR", stdout)

    def test_malformed_version_non_numeric_fails_fast(self):
        """Non-numeric version should fail, not silently apply a wrong image."""
        rc, stdout, _applied, _tmpl = _run_install_nfd("abc.def.ghi")
        self.assertNotEqual(rc, 0, "Script should fail for non-numeric version")
        self.assertIn("ERROR", stdout)

    # --- Template preservation -------------------------------------------

    def test_template_unchanged_after_4x(self):
        """The checked-out template must not be mutated by a 4.x run."""
        rc, _stdout, _applied, template = _run_install_nfd("4.17.3")
        self.assertEqual(rc, 0)
        self.assertIn("<imageUrl>", template, "Template was mutated — should contain placeholder")

    def test_template_unchanged_after_5x(self):
        """The checked-out template must not be mutated by a 5.x run."""
        rc, _stdout, _applied, template = _run_install_nfd("5.0.0")
        self.assertEqual(rc, 0)
        self.assertIn("<imageUrl>", template, "Template was mutated — should contain placeholder")

    def test_no_template_mutation_on_unsupported_version(self):
        """An unsupported version must not mutate the deploy template before failing."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            nfd_work, mock_bin, _applied_path = _setup_mock_env(tmp_dir, "3.11.0")
            env = os.environ.copy()
            env["PATH"] = mock_bin + os.pathsep + env["PATH"]

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

    def test_no_temp_file_left_after_run(self):
        """The temporary rendered file must be cleaned up after the script exits."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            nfd_work, mock_bin, applied_path = _setup_mock_env(tmp_dir, "4.17.3")
            env = os.environ.copy()
            env["PATH"] = mock_bin + os.pathsep + env["PATH"]
            env["NFD_APPLIED_SAVE"] = applied_path

            subprocess.run(
                ["bash", os.path.join(nfd_work, "install_nfd.sh")],
                check=False,
                capture_output=True,
                text=True,
                env=env,
                cwd=nfd_work,
                timeout=30,
            )

            leftover = [f for f in os.listdir(nfd_work) if f.startswith("nfd_deploy.") and f != "nfd_deploy.yaml"]
            self.assertEqual(leftover, [], f"Temp file(s) left behind: {leftover}")

    # --- Pre-rendered / legacy manifest handling -------------------------

    def test_5x_removes_prerendered_4x_digest(self):
        """OCP 5.0 must omit image even if the template already has a baked-in 4.x digest.

        Regression: the previous version only deleted lines containing the
        literal ``<imageUrl>`` placeholder, so a pre-rendered digest survived.
        """
        rc, stdout, applied, _tmpl = _run_install_nfd("5.0.0", pre_render_digest=_FAKE_4X_DIGEST)
        self.assertEqual(rc, 0, f"Script failed: {stdout}")
        self.assertNotIn(_FAKE_4X_DIGEST, applied, "Pre-rendered 4.x digest survived into 5.x manifest")
        self.assertNotIn("image:", applied)
        self.assertIn("imagePullPolicy", applied)

    def test_4x_replaces_prerendered_digest(self):
        """OCP 4.17 must replace a stale pre-rendered digest in the template."""
        rc, _stdout, applied, _tmpl = _run_install_nfd("4.17.3", pre_render_digest=_FAKE_4X_DIGEST)
        self.assertEqual(rc, 0)
        self.assertNotIn(_FAKE_4X_DIGEST, applied, "Stale digest was not replaced")
        self.assertIn("sha256:", applied)

    # --- Cross-version in one checkout -----------------------------------

    def test_4x_then_5x_in_same_checkout(self):
        """Running 4.17 then 5.0 in the same checkout must produce a clean 5.x manifest.

        Because the script renders into a temp copy, the template stays intact
        and the second run starts fresh.
        """
        with tempfile.TemporaryDirectory() as tmp_dir:
            nfd_work, mock_bin, applied_path = _setup_mock_env(tmp_dir, "4.17.3")
            env = os.environ.copy()
            env["PATH"] = mock_bin + os.pathsep + env["PATH"]
            env["NFD_APPLIED_SAVE"] = applied_path
            cmd = ["bash", os.path.join(nfd_work, "install_nfd.sh")]
            template_path = os.path.join(nfd_work, "nfd_deploy.yaml")

            # First run: OCP 4.17
            r1 = subprocess.run(cmd, check=False, capture_output=True, text=True, env=env, cwd=nfd_work, timeout=30)
            self.assertEqual(r1.returncode, 0, f"4.17 run failed: {r1.stdout}")
            with open(applied_path) as f:
                applied_4x = f.read()
            self.assertIn("sha256:", applied_4x)

            # Template should still have the placeholder
            with open(template_path) as f:
                tmpl_after_4x = f.read()
            self.assertIn("<imageUrl>", tmpl_after_4x, "Template mutated after 4.x run")

            # Second run: change mock to OCP 5.0
            oc_path = os.path.join(mock_bin, "oc")
            with open(oc_path, "w") as f:
                f.write(
                    textwrap.dedent("""\
                    #!/bin/bash
                    if [[ "$1" == "version" ]]; then
                        echo '{"openshiftVersion": "5.0.0"}'
                    elif [[ "$1" == "apply" && "$2" == "-f" && -f "$3" ]]; then
                        if [[ -n "$NFD_APPLIED_SAVE" ]] && grep -q "NodeFeatureDiscovery" "$3" 2>/dev/null; then
                            cp "$3" "$NFD_APPLIED_SAVE"
                        fi
                    fi
                    exit 0
                """)
                )
            os.chmod(oc_path, stat.S_IRWXU)

            r2 = subprocess.run(cmd, check=False, capture_output=True, text=True, env=env, cwd=nfd_work, timeout=30)
            self.assertEqual(r2.returncode, 0, f"5.0 run failed: {r2.stdout}")
            with open(applied_path) as f:
                applied_5x = f.read()

            self.assertNotIn("sha256:", applied_5x, "4.x digest leaked into 5.x applied manifest")
            self.assertNotIn("image:", applied_5x)
            self.assertIn("imagePullPolicy", applied_5x)

    # --- Idempotent repeated renders -------------------------------------

    def _run_twice(self, ocp_version):
        """Run install_nfd.sh twice and return applied content after each run."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            nfd_work, mock_bin, applied_path = _setup_mock_env(tmp_dir, ocp_version)
            env = os.environ.copy()
            env["PATH"] = mock_bin + os.pathsep + env["PATH"]
            env["NFD_APPLIED_SAVE"] = applied_path
            cmd = ["bash", os.path.join(nfd_work, "install_nfd.sh")]

            r1 = subprocess.run(cmd, check=False, capture_output=True, text=True, env=env, cwd=nfd_work, timeout=30)
            with open(applied_path) as f:
                after_first = f.read()

            r2 = subprocess.run(cmd, check=False, capture_output=True, text=True, env=env, cwd=nfd_work, timeout=30)
            with open(applied_path) as f:
                after_second = f.read()

            return r1, after_first, r2, after_second

    def test_repeated_render_4x_is_idempotent(self):
        """Running install_nfd.sh twice for OCP 4.17 should produce identical output."""
        r1, after_first, r2, after_second = self._run_twice("4.17.3")
        self.assertEqual(r1.returncode, 0, f"First run failed: {r1.stdout}")
        self.assertEqual(r2.returncode, 0, f"Second run failed: {r2.stdout}")
        self.assertEqual(after_first, after_second, "Applied output changed between runs")
        self.assertIn("sha256:", after_second)

    def test_repeated_render_5x_is_idempotent(self):
        """Running install_nfd.sh twice for OCP 5.0 should produce identical output."""
        r1, after_first, r2, after_second = self._run_twice("5.0.0")
        self.assertEqual(r1.returncode, 0, f"First run failed: {r1.stdout}")
        self.assertEqual(r2.returncode, 0, f"Second run failed: {r2.stdout}")
        self.assertEqual(after_first, after_second, "Applied output changed between runs")
        self.assertNotIn("sha256:", after_second)
        self.assertIn("imagePullPolicy", after_second)
