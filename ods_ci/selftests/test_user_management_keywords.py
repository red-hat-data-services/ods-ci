"""Structural tests for User Management keywords in ODHDashboardSettings.resource.

Verifies keyword structure, version-gating patterns, and selector consistency
without requiring a browser or cluster. These are static parse-time checks.

Related to RHOAIENG-102838: fix group management selectors for RHOAI 3.5.
"""

from pathlib import Path
from typing import ClassVar

import pytest
from robot.api import get_model

SETTINGS_RESOURCE = (
    Path(__file__).resolve().parents[1]
    / "tests"
    / "Resources"
    / "Page"
    / "ODH"
    / "ODHDashboard"
    / "ODHDashboardSettings.resource"
)

PRE_UPGRADE_ROBOT = (
    Path(__file__).resolve().parents[1] / "tests" / "Tests" / "0200__rhoai_upgrade" / "0201__pre_upgrade.robot"
)


def _get_keyword(model, name: str):
    """Find a keyword by name in a parsed Robot model."""
    for section in model.sections:
        if not hasattr(section, "body"):
            continue
        for item in section.body:
            if hasattr(item, "name") and item.name == name:
                return item
    return None


def _keyword_body_text(keyword) -> str:
    """Flatten a keyword body into a single string for pattern matching."""
    lines = []
    for item in keyword.body:
        lines.append(str(item))
        if hasattr(item, "body"):
            for child in item.body:
                lines.append(str(child))
                if hasattr(child, "body"):
                    for grandchild in child.body:
                        lines.append(str(grandchild))
    return "\n".join(lines)


@pytest.fixture(scope="module")
def settings_model():
    """Parse ODHDashboardSettings.resource."""
    assert SETTINGS_RESOURCE.exists(), f"Resource file not found: {SETTINGS_RESOURCE}"
    return get_model(str(SETTINGS_RESOURCE), data_only=True)


@pytest.fixture(scope="module")
def pre_upgrade_model():
    """Parse pre_upgrade.robot."""
    assert PRE_UPGRADE_ROBOT.exists(), f"Test file not found: {PRE_UPGRADE_ROBOT}"
    return get_model(str(PRE_UPGRADE_ROBOT), data_only=True)


class TestResourceFileParsesCleanly:
    """The resource file must parse without errors."""

    def test_settings_resource_parses(self, settings_model):
        assert settings_model is not None

    def test_pre_upgrade_parses(self, pre_upgrade_model):
        assert pre_upgrade_model is not None


class TestVersionGatedKeywords:
    """Keywords that interact with the User Management UI must have version gating."""

    VERSION_GATED_KEYWORDS: ClassVar[list[str]] = [
        "Add OpenShift Groups To Data Science Administrators",
        "Add OpenShift Groups To Data Science User Groups",
        "Launch Dashboard And Check User Management Option Is Available For The User",
        "Clear User Management Settings",
        "Save Changes In User Management Setting",
    ]

    @pytest.mark.parametrize("keyword_name", VERSION_GATED_KEYWORDS)
    def test_keyword_has_version_check(self, settings_model, keyword_name):
        kw = _get_keyword(settings_model, keyword_name)
        assert kw is not None, f"Keyword '{keyword_name}' not found"
        body = _keyword_body_text(kw)
        assert (
            "Is RHODS Version Greater Or Equal Than" in body or "3.5.0" in body
        ), f"Keyword '{keyword_name}' must contain a version check for 3.5.0"


class TestNewHelperKeywordsExist:
    """New 3.5 helper keywords must exist with correct arguments."""

    def test_add_group_in_section(self, settings_model):
        kw = _get_keyword(settings_model, "Add Group In Section")
        assert kw is not None, "Add Group In Section keyword must exist"

    def test_remove_group_from_section(self, settings_model):
        kw = _get_keyword(settings_model, "Remove Group From Section")
        assert kw is not None, "Remove Group From Section keyword must exist"

    def test_get_group_names_in_section(self, settings_model):
        kw = _get_keyword(settings_model, "Get Group Names In Section")
        assert kw is not None, "Get Group Names In Section keyword must exist"

    def test_set_exact_groups_in_section(self, settings_model):
        kw = _get_keyword(settings_model, "Set Exact Groups In Section")
        assert kw is not None, "Set Exact Groups In Section keyword must exist"

    def test_set_exact_admin_groups(self, settings_model):
        kw = _get_keyword(settings_model, "Set Exact Data Science Administrator Groups")
        assert kw is not None

    def test_set_exact_user_groups(self, settings_model):
        kw = _get_keyword(settings_model, "Set Exact Data Science User Groups")
        assert kw is not None


class TestSelectorConsistency:
    """Verify that selectors in new keywords match the verified dashboard source."""

    # These data-testid values are verified in red-hat-data-services/odh-dashboard
    # rhoai-3.5 branch (GroupSettingsSection.tsx, TypeaheadSelect.tsx)
    EXPECTED_SELECTORS_35: ClassVar[list[str]] = [
        'data-testid="add-group-button"',
        'role="combobox"',
        'role="option"',
        'data-testid="save-new-group-button"',
        "remove-group-button",  # Used in Evaluate to build data-testid via Build XPath Literal
        'data-testid="remove-group-modal"',
        'data-testid="modal-remove-button"',
    ]

    # These selectors are for <=3.4 compatibility (PR3160-compatible)
    EXPECTED_SELECTORS_34: ClassVar[list[str]] = [
        'contains(@aria-label, "Select the groups that contain all")',
        'data-testid="group-setting-select"',
        'data-testid="select-multi-typeahead-',
    ]

    def test_35_selectors_present(self, settings_model):
        """All 3.5 data-testid selectors from the dashboard source must appear."""
        # Read raw file to check selectors
        content = SETTINGS_RESOURCE.read_text()
        for selector in self.EXPECTED_SELECTORS_35:
            assert selector in content, f"Missing 3.5 selector: {selector}"

    def test_34_selectors_present(self, settings_model):
        """<=3.4 fallback selectors must still be present."""
        content = SETTINGS_RESOURCE.read_text()
        for selector in self.EXPECTED_SELECTORS_34:
            assert selector in content, f"Missing <=3.4 selector: {selector}"

    def test_old_literal_aria_label_removed(self, settings_model):
        """The old exact aria-label match must not appear (replaced by contains())."""
        content = SETTINGS_RESOURCE.read_text()
        assert (
            '@aria-label="Select the OpenShift groups that contain all Data Science administrators."' not in content
        ), "Old literal aria-label for administrators must be replaced"
        assert (
            '@aria-label="Select the OpenShift groups that contain all Data Science users."' not in content
        ), "Old literal aria-label for users must be replaced"


class TestSectionVariablesPreserved:
    """Section data-testid variables must remain unchanged."""

    def test_admin_section_variable(self, settings_model):
        content = SETTINGS_RESOURCE.read_text()
        assert '${ADMIN_GROUPS_SECTION}=    //div[@data-testid="data-science-administrator-groups"]' in content

    def test_user_section_variable(self, settings_model):
        content = SETTINGS_RESOURCE.read_text()
        assert '${USER_GROUPS_SECTION}=    //div[@data-testid="data-science-user-groups"]' in content

    def test_save_button_variable(self, settings_model):
        content = SETTINGS_RESOURCE.read_text()
        assert '${SAVE_BUTTON}=    //button[contains(., "Save changes")]' in content


class TestClearKeywordSafety:
    """Clear must fail on >=3.5, not silently no-op."""

    def test_clear_fails_on_35(self, settings_model):
        kw = _get_keyword(settings_model, "Clear User Management Settings")
        assert kw is not None
        body = _keyword_body_text(kw)
        assert "Fail" in body, "Clear must call Fail on >=3.5, not silently succeed"
        assert (
            "minimum 1" in body.lower() or "minimum" in body.lower()
        ), "Clear failure message should mention the minimum group constraint"


class TestSaveKeywordPreservesClusterSettings:
    """Save must still work for Cluster settings (called via Save Changes In Cluster Settings)."""

    def test_save_changes_in_cluster_settings_delegates(self, settings_model):
        kw = _get_keyword(settings_model, "Save Changes In Cluster Settings")
        assert kw is not None
        body = _keyword_body_text(kw)
        assert "Save Changes In User Management Setting" in body

    def test_save_uses_section_sentinel_not_button_presence(self, settings_model):
        """Save must detect >=3.5 User Management by section sentinel, not by missing button."""
        kw = _get_keyword(settings_model, "Save Changes In User Management Setting")
        body = _keyword_body_text(kw)
        assert "ADMIN_GROUPS_SECTION" in body, "Save must use section sentinel to detect User Management page"
        assert "3.5.0" in body, "Save must check version"


class TestPreUpgradeUsesExactSetKeywords:
    """pre_upgrade.robot must use the new exact-set keywords for >=3.5."""

    def test_pre_upgrade_has_version_branch(self, pre_upgrade_model):
        content = PRE_UPGRADE_ROBOT.read_text()
        assert "Is RHODS Version Greater Or Equal Than" in content
        assert "Set Exact Data Science Administrator Groups" in content
        assert "Set Exact Data Science User Groups" in content

    def test_pre_upgrade_preserves_legacy_path(self, pre_upgrade_model):
        content = PRE_UPGRADE_ROBOT.read_text()
        assert "Clear User Management Settings" in content, "Legacy <=3.4 path must still call Clear"
        assert "Save Changes In User Management Setting" in content, "Legacy <=3.4 path must still call Save"

    def test_pre_upgrade_preserves_configmap(self, pre_upgrade_model):
        content = PRE_UPGRADE_ROBOT.read_text()
        assert "USERGROUPS_CONFIG_MAP" in content
        assert "adm_groups" in content
        assert "allwd_groups" in content


class TestSetExactGroupsAssertsFinalState:
    """Set Exact Groups In Section must assert convergence."""

    def test_asserts_final_set(self, settings_model):
        kw = _get_keyword(settings_model, "Set Exact Groups In Section")
        assert kw is not None
        body = _keyword_body_text(kw)
        assert "Lists Should Be Equal" in body, "Set Exact Groups must assert final group list matches desired"


class TestRemoveGroupDocumentsConstraint:
    """Remove Group From Section must document the last-group constraint."""

    def test_remove_checks_aria_disabled(self, settings_model):
        kw = _get_keyword(settings_model, "Remove Group From Section")
        assert kw is not None
        body = _keyword_body_text(kw)
        assert "aria-disabled" in body, "Remove must check aria-disabled for last-group constraint"

    def test_remove_waits_for_enabled(self, settings_model):
        kw = _get_keyword(settings_model, "Remove Group From Section")
        body = _keyword_body_text(kw)
        assert "Wait Until Element Is Enabled" in body, "Remove must wait for HTML enabled (isSaving/isRemoving)"

    def test_remove_waits_for_modal(self, settings_model):
        kw = _get_keyword(settings_model, "Remove Group From Section")
        body = _keyword_body_text(kw)
        assert "remove-group-modal" in body
        assert "modal-remove-button" in body


class TestEmptyDesiredGroupsFails:
    """Empty desired list must fail before mutating anything."""

    def test_set_exact_guards_empty_list(self, settings_model):
        kw = _get_keyword(settings_model, "Set Exact Groups In Section")
        assert kw is not None
        body = _keyword_body_text(kw)
        assert "Get Length" in body or "count" in body.lower(), "Set Exact Groups must check length of desired list"
        assert "Fail" in body, "Must Fail on empty desired list"


class TestBuildXPathLiteralExists:
    """Build XPath Literal keyword must exist for safe XPath construction."""

    def test_keyword_exists(self, settings_model):
        kw = _get_keyword(settings_model, "Build XPath Literal")
        assert kw is not None, "Build XPath Literal keyword must exist"

    def test_select_and_save_uses_it(self, settings_model):
        kw = _get_keyword(settings_model, "Select And Save Group In Section")
        body = _keyword_body_text(kw)
        assert "Build XPath Literal" in body, "Must use Build XPath Literal for XPath safety"

    def test_remove_uses_it(self, settings_model):
        kw = _get_keyword(settings_model, "Remove Group From Section")
        body = _keyword_body_text(kw)
        assert "Build XPath Literal" in body, "Must use Build XPath Literal for XPath safety"


class TestSelectAndSaveChecksEnabled:
    """Select And Save must check both HTML disabled and aria-disabled."""

    def test_checks_aria_disabled(self, settings_model):
        kw = _get_keyword(settings_model, "Select And Save Group In Section")
        body = _keyword_body_text(kw)
        assert "aria-disabled" in body, "Save must check aria-disabled for PF6 compatibility"

    def test_waits_for_enabled(self, settings_model):
        kw = _get_keyword(settings_model, "Select And Save Group In Section")
        body = _keyword_body_text(kw)
        assert "Wait Until Element Is Enabled" in body, "Must wait for HTML enabled"


class TestOptionXPathExactMatch:
    """Option XPath must use exact match, not starts-with."""

    def test_no_starts_with_in_option_xpath(self, settings_model):
        """starts-with could match a similarly-prefixed group name."""
        content = SETTINGS_RESOURCE.read_text()
        # The option XPath should NOT use starts-with for creatable option matching
        assert (
            "starts-with(normalize-space(.), 'Select" not in content
        ), "Option XPath must use exact match, not starts-with, to avoid matching similarly-prefixed group names"
