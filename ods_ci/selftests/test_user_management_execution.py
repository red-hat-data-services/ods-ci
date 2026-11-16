"""Executable behavior tests for User Management keywords.

Uses robot.running to execute actual keyword bodies against fake browser/version
stub libraries. Validates call ordering, state transitions, version routing,
duplicate handling, exact-set with leftover removal, and XPath selector correctness.

Related to RHOAIENG-102838.
"""

from __future__ import annotations

import logging
import os
import re
import shutil
import sys
import tempfile
import textwrap
from pathlib import Path
from typing import TYPE_CHECKING, Any
from xml.sax.saxutils import escape as _html_escape

from lxml import etree
from robot.api import TestSuite
from semver import VersionInfo

if TYPE_CHECKING:
    from robot.result.executionresult import Result

SETTINGS_RESOURCE = (
    Path(__file__).resolve().parents[1]
    / "tests"
    / "Resources"
    / "Page"
    / "ODH"
    / "ODHDashboard"
    / "ODHDashboardSettings.resource"
)


class FakeBrowserState:
    """Shared mutable state for the fake browser library."""

    def __init__(self) -> None:
        self.reset()

    def reset(self) -> None:
        self.calls: list[tuple[str, tuple[Any, ...]]] = []
        self.groups: dict[str, list[str]] = {"admin": ["default-admins"], "user": ["system:authenticated"]}
        self.version: str = "3.5.0"
        self.page: str = "user-management"
        self.adding_section: str | None = None
        self.adding_group: str | None = None

    def record(self, name: str, *args: Any) -> None:
        self.calls.append((name, args))


_state = FakeBrowserState()


def _section_key(locator: str) -> str:
    if "administrator" in locator:
        return "admin"
    if "user" in locator:
        return "user"
    return "unknown"


def _make_stub_resource() -> str:
    """Generate a minimal .resource file with fake library and real keyword bodies."""
    real_content = SETTINGS_RESOURCE.read_text()
    kw_start = real_content.index("*** Keywords ***")
    keywords_block = real_content[kw_start:]
    return (
        textwrap.dedent("""\
*** Settings ***
Library    test_user_management_execution.FakeBrowserLib
Library    test_user_management_execution.FakeMenuLib    WITH NAME    Menu
Library    Collections

*** Variables ***
${ADMIN_GROUPS_SECTION}=    //div[@data-testid="data-science-administrator-groups"]
${ADMIN_GROUPS_LIST}=    ${ADMIN_GROUPS_SECTION}//div[@role="group" and @aria-label="Current selections"]
${USER_GROUPS_SECTION}=    //div[@data-testid="data-science-user-groups"]
${USER_GROUPS_LIST}=    ${USER_GROUPS_SECTION}//div[@role="group" and @aria-label="Current selections"]
${SAVE_BUTTON}=    //button[contains(., "Save changes")]
${GROUP_BTN_XP}=    //button[@aria-label="Clear input value"]
${ODH_DASHBOARD_URL}=    https://fake-dashboard.example.com
&{BROWSER}=    NAME=chrome    OPTIONS=headless
${PRODUCT}=    RHODS

""")
        + keywords_block
    )


class FakeMenuLib:
    """Stub for Menu library (provides Menu.Navigate To Page)."""

    ROBOT_LIBRARY_SCOPE = "GLOBAL"

    def navigate_to_page(self, *args: Any, **kwargs: Any) -> None:
        _state.record("navigate_to_page", *args)


class FakeBrowserLib:
    """Robot Framework library stubbing SeleniumLibrary + version keywords."""

    ROBOT_LIBRARY_SCOPE = "GLOBAL"

    def is_rhods_version_greater_or_equal_than(self, target: str) -> bool:
        _state.record("version_check", target)
        return VersionInfo.parse(_state.version) >= VersionInfo.parse(target)

    def launch_dashboard(self, **kwargs: Any) -> None:
        _state.record("launch_dashboard")

    def verify_service_account_authorization_not_required(self) -> None:
        _state.record("verify_service_account")

    # Menu.Navigate To Page is a dotted keyword — Robot resolves it as a library named "Menu"
    # with keyword "Navigate To Page". Add a standalone stub via the ROBOT_LIBRARY_DOC_FORMAT trick:
    # Robot also tries the keyword name directly on all libraries.
    def navigate_to_page(self, *args: Any, **kwargs: Any) -> None:
        _state.record("navigate_to_page", *args)

    def click_button(self, locator: str) -> None:
        _state.record("click_button", locator)
        sk = _section_key(locator)
        if "add-group-button" in locator:
            _state.adding_section = sk
        elif "save-new-group-button" in locator:
            if _state.adding_group and _state.adding_section:
                _state.groups[_state.adding_section].append(_state.adding_group)
            _state.adding_group = None
            _state.adding_section = None
        elif "modal-remove-button" in locator:
            pass
        elif "Save changes" in locator:
            _state.record("save_click")

    def click_element(self, locator: str) -> None:
        _state.record("click_element", locator)
        if 'role="option"' in locator:
            for g in [*_state.groups.get(_state.adding_section or "admin", []), _state.adding_group or ""]:
                if g and (g in locator or f'Select "{g}"' in locator):
                    _state.adding_group = g
                    break
        elif "Cancel add group" in locator:
            _state.adding_group = None
            _state.adding_section = None
        elif "remove-group-button" in locator:
            m = re.search(r"remove-group-button ([^'\"]+)", locator)
            if m:
                gn = m.group(1).strip()
                sk = _section_key(locator)
                if gn in _state.groups.get(sk, []):
                    _state.groups[sk].remove(gn)

    def element_should_be_visible(self, locator: str) -> None:
        _state.record("element_visible", locator)

    def wait_until_element_is_visible(self, locator: str, timeout: str = "10s") -> None:
        _state.record("wait_visible", locator)

    def wait_until_element_is_not_visible(self, locator: str, timeout: str = "10s") -> None:
        _state.record("wait_not_visible", locator)

    def wait_until_element_is_enabled(self, locator: str, timeout: str = "5s") -> None:
        _state.record("wait_enabled", locator)

    def wait_until_page_contains_element(self, locator: str, timeout: str = "10s") -> None:
        _state.record("wait_page_contains", locator)
        if "duplicate-group-error" in locator and _state.adding_section:
            sk = _state.adding_section
            if _state.adding_group and _state.adding_group in _state.groups.get(sk, []):
                return
        raise AssertionError(f"Element not found: {locator}")

    def page_should_contain_element(self, locator: str, **kwargs: Any) -> None:
        _state.record("page_contains", locator)
        if "data-science-administrator-groups" in locator and _state.page == "user-management":
            return
        if "data-science-user-groups" in locator and _state.page == "user-management":
            return
        raise AssertionError(f"Element not found: {locator}")

    def page_should_not_contain_element(self, locator: str, **kwargs: Any) -> None:
        _state.record("page_not_contains", locator)
        if "aria-disabled" in locator:
            sk = _section_key(locator)
            if len(_state.groups.get(sk, [])) <= 1:
                raise AssertionError(f"Last group: {locator}")

    def input_text(self, locator: str, text: str) -> None:
        _state.record("input_text", locator, text)
        _state.adding_group = text

    def get_webelements(self, locator: str) -> list[str]:
        _state.record("get_webelements", locator)
        if "Clear input value" in locator:
            return ["btn1", "btn2"]
        if 'data-label="Name"' in locator:
            sk = _section_key(locator)
            return _state.groups.get(sk, [])[:]
        return []

    def get_text(self, element: Any) -> str:
        return str(element)

    def scroll_element_into_view(self, locator: str) -> None:
        _state.record("scroll", locator)

    def press_keys(self, locator: Any, *keys: str) -> None:
        _state.record("press_keys", locator, *keys)

    def verify_cluster_settings_is_not_available(self) -> None:
        _state.record("verify_cluster_settings_not_available")


def _run_robot_test(
    test_body: str,
    version: str = "3.5.0",
    page: str = "user-management",
    initial_admin: list[str] | None = None,
    initial_user: list[str] | None = None,
) -> Result:
    """Execute Robot keywords in an isolated test with fake browser."""
    _state.reset()
    _state.version = version
    _state.page = page
    sys.modules["test_user_management_execution"] = sys.modules[__name__]
    if initial_admin is not None:
        _state.groups["admin"] = list(initial_admin)
    if initial_user is not None:
        _state.groups["user"] = list(initial_user)
    tmpdir = tempfile.mkdtemp()
    resource_path = os.path.join(tmpdir, "settings_test.resource")
    test_path = os.path.join(tmpdir, "test.robot")
    with open(resource_path, "w") as f:
        f.write(_make_stub_resource())
    test_content = textwrap.dedent(f"""\
*** Settings ***
Library    test_user_management_execution.FakeBrowserLib
Library    test_user_management_execution.FakeMenuLib    WITH NAME    Menu
Library    Collections
Resource    {resource_path}

*** Test Cases ***
Test
{textwrap.indent(test_body, "    ")}
""")
    with open(test_path, "w") as f:
        f.write(test_content)
    suite = TestSuite.from_file_system(test_path)
    # Save and restore root logger state — Robot's suite.run() modifies it,
    # which would break capture_logging doctest in test_util.py
    saved_log_level = logging.root.level
    saved_log_handlers = logging.root.handlers[:]
    try:
        result = suite.run(
            output=os.path.join(tmpdir, "output.xml"),
            log=None,
            report=None,
            console="none",
            pythonpath=[str(Path(__file__).parent)],
        )
    finally:
        logging.root.level = saved_log_level
        logging.root.handlers = saved_log_handlers
    shutil.rmtree(tmpdir, ignore_errors=True)
    return result


# ===========================================================================
# Robot execution tests
# ===========================================================================


class TestAddGroupBehavior35:
    def test_add_new_group(self):
        result = _run_robot_test(
            "Add Group In Section    ${ADMIN_GROUPS_SECTION}    new-group",
            version="3.5.0",
            initial_admin=["default-admins"],
        )
        assert result.return_code == 0, result.suite.tests[0].message
        assert "new-group" in _state.groups["admin"]
        call_names = [c[0] for c in _state.calls]
        assert "click_button" in call_names
        assert "input_text" in call_names
        assert "wait_enabled" in call_names

    def test_add_duplicate_skips(self):
        result = _run_robot_test(
            "Add Group In Section    ${ADMIN_GROUPS_SECTION}    default-admins",
            version="3.5.0",
            initial_admin=["default-admins"],
        )
        assert result.return_code == 0
        assert _state.groups["admin"].count("default-admins") == 1
        # Should NOT have clicked add-group-button (skipped entirely)
        add_clicks = [c for c in _state.calls if "add-group-button" in str(c)]
        assert len(add_clicks) == 0, "Duplicate should skip add flow entirely"


class TestAddGroupVersionRouting:
    def test_35_uses_add_group_button(self):
        result = _run_robot_test(
            "Add OpenShift Groups To Data Science Administrators    new-group",
            version="3.5.0",
            initial_admin=["default-admins"],
        )
        assert result.return_code == 0, result.suite.tests[0].message
        add_btn = [c for c in _state.calls if "add-group-button" in str(c)]
        assert len(add_btn) > 0

    def test_34_uses_aria_label_and_succeeds(self):
        result = _run_robot_test(
            "Add OpenShift Groups To Data Science Administrators    new-group",
            version="3.4.0",
            initial_admin=["default-admins"],
        )
        assert result.return_code == 0, result.suite.tests[0].message
        aria = [c for c in _state.calls if "Select the groups that contain all" in str(c)]
        assert len(aria) > 0, "3.4 path must use contains(@aria-label)"
        esc = [c for c in _state.calls if c[0] == "press_keys" and "ESC" in str(c)]
        assert len(esc) > 0, "3.4 path must press ESC to close dropdown"


class TestExactSetBehavior:
    def test_exact_set_with_leftover_default(self):
        result = _run_robot_test(
            "Set Exact Data Science Administrator Groups    rhods-admins    rhods-users",
            version="3.5.0",
            initial_admin=["default-admins"],
        )
        assert result.return_code == 0, result.suite.tests[0].message
        assert sorted(_state.groups["admin"]) == ["rhods-admins", "rhods-users"]

    def test_exact_set_user_groups(self):
        result = _run_robot_test(
            "Set Exact Data Science User Groups    system:authenticated",
            version="3.5.0",
            initial_user=["system:authenticated"],
        )
        assert result.return_code == 0, result.suite.tests[0].message
        assert _state.groups["user"] == ["system:authenticated"]

    def test_exact_set_empty_list_fails(self):
        result = _run_robot_test(
            "Set Exact Data Science Administrator Groups",
            version="3.5.0",
            initial_admin=["default-admins"],
        )
        assert result.return_code != 0

    def test_add_before_remove_ordering(self):
        result = _run_robot_test(
            "Set Exact Data Science Administrator Groups    new-group",
            version="3.5.0",
            initial_admin=["old-group"],
        )
        assert result.return_code == 0, result.suite.tests[0].message
        add_idx = [i for i, c in enumerate(_state.calls) if "add-group-button" in str(c)]
        rm_idx = [i for i, c in enumerate(_state.calls) if "remove-group-button" in str(c)]
        assert add_idx and rm_idx, "Must have both add and remove calls"
        assert max(add_idx) < min(rm_idx), "Adds before removes"


class TestClearBehavior:
    def test_clear_fails_on_35(self):
        result = _run_robot_test("Clear User Management Settings", version="3.5.0")
        assert result.return_code != 0
        assert "minimum" in result.suite.tests[0].message.lower()

    def test_clear_works_on_34(self):
        result = _run_robot_test("Clear User Management Settings", version="3.4.0")
        assert result.return_code == 0, result.suite.tests[0].message
        click_calls = [c for c in _state.calls if c[0] == "click_button" and "Clear input" in str(c)]
        assert len(click_calls) > 0, "3.4 clear must click Clear input value buttons"


class TestSaveBehavior:
    def test_save_skips_on_35_user_management(self):
        result = _run_robot_test(
            "Save Changes In User Management Setting",
            version="3.5.0",
            page="user-management",
        )
        assert result.return_code == 0
        scroll_calls = [c for c in _state.calls if c[0] == "scroll"]
        assert len(scroll_calls) == 0, "Must skip scroll on 3.5 user management"

    def test_save_attempts_scroll_on_cluster_settings(self):
        result = _run_robot_test(
            "Save Changes In User Management Setting",
            version="3.5.0",
            page="cluster-settings",
        )
        assert result.return_code == 0, result.suite.tests[0].message
        scroll_calls = [c for c in _state.calls if c[0] == "scroll"]
        assert len(scroll_calls) > 0, "Cluster settings must attempt save"

    def test_save_works_on_34_user_management(self):
        result = _run_robot_test(
            "Save Changes In User Management Setting",
            version="3.4.0",
            page="user-management",
        )
        assert result.return_code == 0, result.suite.tests[0].message
        scroll_calls = [c for c in _state.calls if c[0] == "scroll"]
        assert len(scroll_calls) > 0, "3.4 must attempt save"


class TestLaunchDashboardWait:
    def test_35_waits_for_add_group_button(self):
        result = _run_robot_test(
            textwrap.dedent("""\
            Launch Dashboard And Check User Management Option Is Available For The User
            ...    user    pass    basic"""),
            version="3.5.0",
        )
        assert result.return_code == 0, result.suite.tests[0].message
        waits = [c for c in _state.calls if c[0] == "wait_visible"]
        add_btn_waits = [c for c in waits if "add-group-button" in str(c)]
        assert len(add_btn_waits) > 0, "3.5 must wait for add-group-button"
        aria_waits = [c for c in waits if "Select the groups" in str(c)]
        assert len(aria_waits) == 0, "3.5 must NOT wait for old aria-label"

    def test_34_waits_for_aria_label(self):
        result = _run_robot_test(
            textwrap.dedent("""\
            Launch Dashboard And Check User Management Option Is Available For The User
            ...    user    pass    basic"""),
            version="3.4.0",
        )
        assert result.return_code == 0, result.suite.tests[0].message
        waits = [c for c in _state.calls if c[0] == "wait_visible"]
        aria_waits = [c for c in waits if "Select the groups" in str(c)]
        assert len(aria_waits) > 0, "3.4 must wait for aria-label selector"
        add_btn_waits = [c for c in waits if "add-group-button" in str(c)]
        assert len(add_btn_waits) == 0, "3.4 must NOT wait for add-group-button"


# ===========================================================================
# XPath tests with lxml (uses production selector construction)
# ===========================================================================


def _xpath_literal(s: str) -> str:
    """Build an XPath string literal with proper quote escaping.

    Mirrors the Build XPath Literal keyword in ODHDashboardSettings.resource.
    """
    if "'" not in s:
        return f"'{s}'"
    if '"' not in s:
        return f'"{s}"'
    # Contains both quote types: split on apostrophes and use concat()
    parts: list[str] = []
    for i, chunk in enumerate(s.split("'")):
        if i > 0:
            parts.append('"\'"')
        if chunk:
            parts.append(f"'{chunk}'")
    return "concat(" + ",".join(parts) + ")"


def _build_option_xpath(group: str) -> str:
    """Build EXACT same XPath as Select And Save Group In Section keyword."""
    name_lit = _xpath_literal(group)
    select_lit = _xpath_literal(f'Select "{group}"')
    return f'//li[@role="option"][normalize-space(.)={name_lit} or normalize-space(.)={select_lit}]'


def _build_remove_xpath(section_xp: str, group: str) -> str:
    """Build EXACT same XPath as Remove Group From Section keyword."""
    testid_lit = _xpath_literal(f"remove-group-button {group}")
    return f"{section_xp}//button[@data-testid={testid_lit}]"


def _make_option_html(groups: list[str], creatable: list[str] | None = None) -> str:
    items = []
    for g in groups:
        items.append(f'<li role="option">{g}</li>')
    for g in creatable or []:
        items.append(f'<li role="option">Select &quot;{g}&quot;</li>')
    return f"<div><ul>{chr(10).join(items)}</ul></div>"


class TestXPathLiteral:
    """Verify _xpath_literal produces correct XPath string literals."""

    def test_no_quotes(self):
        assert _xpath_literal("hello") == "'hello'"

    def test_apostrophe_only(self):
        assert _xpath_literal("O'Brien") == '"O\'Brien"'

    def test_double_quote_only(self):
        assert _xpath_literal('say"hi"') == "'say\"hi\"'"

    def test_both_quotes(self):
        result = _xpath_literal('it\'s"fine"')
        assert result.startswith("concat(")
        # Verify round-trip via lxml
        tree = etree.HTML('<p>it\'s"fine"</p>')
        matches = tree.xpath(f"//p[normalize-space(.)={result}]")
        assert len(matches) == 1


class TestXPathOptionMatching:
    """Verify production option XPath against HTML fixtures."""

    def _eval(self, html: str, group: str) -> list[str]:
        tree = etree.HTML(html)
        return [
            etree.tostring(e, method="text", encoding="unicode").strip() for e in tree.xpath(_build_option_xpath(group))
        ]

    def test_direct_match(self):
        assert self._eval(_make_option_html(["rhods-admins", "rhods-users"]), "rhods-admins") == ["rhods-admins"]

    def test_creatable_match(self):
        assert self._eval(_make_option_html([], creatable=["custom"]), "custom") == ['Select "custom"']

    def test_no_prefix_match(self):
        assert self._eval(_make_option_html(["rhods-admins"]), "rhods") == []

    def test_no_prefix_match_creatable(self):
        assert self._eval(_make_option_html([], creatable=["custom-group"]), "custom") == []

    def test_colon_in_name(self):
        assert self._eval(_make_option_html(["system:authenticated"]), "system:authenticated") == [
            "system:authenticated"
        ]

    def test_hyphen_in_name(self):
        assert self._eval(_make_option_html(["my-test"]), "my-test") == ["my-test"]

    def test_apostrophe_in_name(self):
        """Group names with apostrophes must match via XPath escaping."""
        assert self._eval(_make_option_html(["O'Brien"]), "O'Brien") == ["O'Brien"]

    def test_apostrophe_in_creatable(self):
        result = self._eval(_make_option_html([], creatable=["O'Brien"]), "O'Brien")
        assert result == ['Select "O\'Brien"']

    def test_double_quote_in_name(self):
        assert self._eval(_make_option_html(['say"hi"']), 'say"hi"') == ['say"hi"']

    def test_both_quotes_in_name(self):
        name = 'it\'s"fine"'
        assert self._eval(_make_option_html([name]), name) == [name]


class TestXPathRemoveButton:
    SECTION_XP = '//div[@data-testid="data-science-administrator-groups"]'

    def _eval(self, html: str, section_xp: str, group: str) -> list[str]:
        tree = etree.HTML(html)
        xpath = _build_remove_xpath(section_xp, group)
        return [e.get("data-testid", "") for e in tree.xpath(xpath)]

    def test_exact_match(self):
        html = '<div data-testid="data-science-administrator-groups"><button data-testid="remove-group-button rhods-admins"></button><button data-testid="remove-group-button rhods-users"></button></div>'
        assert self._eval(html, self.SECTION_XP, "rhods-admins") == ["remove-group-button rhods-admins"]

    def test_no_prefix(self):
        html = '<div data-testid="data-science-administrator-groups"><button data-testid="remove-group-button rhods-admins"></button></div>'
        assert self._eval(html, self.SECTION_XP, "rhods") == []

    def test_apostrophe_in_name(self):
        html = '<div data-testid="data-science-administrator-groups"><button data-testid="remove-group-button O\'Brien"></button></div>'
        assert self._eval(html, self.SECTION_XP, "O'Brien") == ["remove-group-button O'Brien"]

    def test_double_quote_in_name(self):
        html = '<div data-testid="data-science-administrator-groups"><button data-testid="remove-group-button say&quot;hi&quot;"></button></div>'
        assert self._eval(html, self.SECTION_XP, 'say"hi"') == ['remove-group-button say"hi"']

    def test_both_quotes_in_name(self):
        name = 'it\'s"fine"'
        attr_val = _html_escape(f"remove-group-button {name}", {'"': "&quot;"})
        html = f'<div data-testid="data-science-administrator-groups"><button data-testid="{attr_val}"></button></div>'
        assert self._eval(html, self.SECTION_XP, name) == [f"remove-group-button {name}"]
