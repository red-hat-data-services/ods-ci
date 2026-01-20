#!/usr/bin/env python3
"""
ReportPortal CLI Tool - Manage dashboards, filters, and upload test results.

Authentication:
  Set RP_API_TOKEN environment variable, use --token-file <path>, or place token in:
  ./secrets/rp-api-token (relative to script directory)

  To get a token:
  1. Log into ReportPortal UI
  2. Open developer mode (F12), open console, and run:
     localStorage.getItem('token') || sessionStorage.getItem('token')
  3. Extract the "value" field from the JSON response

Examples:
  rp-cli.py list dashboards
  rp-cli.py list filters
  rp-cli.py export dashboard 123 -o dashboard.json
  rp-cli.py export dashboard 123 -o 3.3.json --rename "3.2" "3.3"
  rp-cli.py export dashboard 123 --title "RHOAI 3.3"        # explicit title in exported JSON
  rp-cli.py export filter 321 -o filter.json
  rp-cli.py export "https://server/ui/#project/dashboard/123" -o dashboard.json
  rp-cli.py import dashboard.json --title "New Dashboard"
  rp-cli.py import filter.json -t "New Filter"
  rp-cli.py copy dashboard 123 --rename "3.2" "3.3"              # title becomes renamed original
  rp-cli.py copy dashboard 123 --title "RHOAI 3.3"              # explicit title
  rp-cli.py copy filter 321 --title "New Filter Name"
  rp-cli.py copy "https://server/ui/#project/dashboard/123"     # uses original name
  rp-cli.py upload results.xml -n "Launch Name" -a "key1:val1,key2:val2"
  rp-cli.py upload results.xml -df description.txt -af attributes.txt

Exit Codes:
  0   Success
  1   General error
  2   Invalid arguments
  10  File not found
  11  Connection error
  12  Authentication error
  13  Resource not found
  14  Resource already exists (duplicate)
  15  API error
"""

import json
import os
import re
import sys
import tempfile
import xml.etree.ElementTree as ET  # noqa: N817
from datetime import UTC, datetime
from pathlib import Path
from urllib.parse import quote

try:
    import click
except ImportError:
    print("Error: 'click' module required. Install with: pip install click")
    sys.exit(1)

try:
    import requests
except ImportError:
    print("Error: 'requests' module required. Install with: pip install requests")
    sys.exit(1)


class Namespace:
    """Simple namespace object to replace Namespace."""

    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)


# Configuration via env vars or CLI flags (no defaults - must be provided)
# RP_SERVER, RP_PROJECT, RP_API_TOKEN

# Exit codes
EXIT_SUCCESS = 0
EXIT_ERROR = 1  # General error
EXIT_USAGE = 2  # Invalid arguments
EXIT_FILE_NOT_FOUND = 10
EXIT_CONNECTION_ERROR = 11
EXIT_AUTH_ERROR = 12
EXIT_NOT_FOUND = 13  # Resource not found
EXIT_DUPLICATE = 14  # Resource already exists
EXIT_API_ERROR = 15  # Other API errors


def usage_err(message: str, exit_code: int = EXIT_USAGE) -> None:
    """Print usage info and error message, then exit."""
    ctx = click.get_current_context(silent=True)
    if ctx:
        click.echo(ctx.get_usage(), err=True)
        click.echo(f"Try '{ctx.info_name} --help' for help.\n", err=True)
    err(message, exit_code)


# ReportPortal API error code mapping


RP_ERROR_MAP = {
    4091: EXIT_DUPLICATE,  # Resource already exists
    4042: EXIT_NOT_FOUND,  # Resource not found
    40017: EXIT_AUTH_ERROR,  # Access denied
    40010: EXIT_API_ERROR,  # Bad request
}

# ReportPortal issue types (for failed test items)
ISSUE_TO_INVESTIGATE = "TI001"  # To Investigate (default for new failures)
ISSUE_PRODUCT_BUG = "PB001"  # Product Bug
ISSUE_AUTOMATION_BUG = "AB001"  # Automation Bug
ISSUE_SYSTEM_ISSUE = "SI001"  # System Issue
ISSUE_NO_DEFECT = "ND001"  # No Defect (false failure)


def get_exit_code(resp: dict) -> int:
    """Map ReportPortal API error code to exit code"""
    api_code = resp.get("errorCode")
    if api_code:
        return RP_ERROR_MAP.get(api_code, EXIT_API_ERROR)
    return EXIT_ERROR


# Terminal output helpers (using click for colors)
def info(msg):
    click.echo(click.style(msg, fg="blue"))


def ok(msg):
    click.echo(click.style(msg, fg="green"))


def warn(msg):
    click.echo(click.style(msg, fg="yellow"))


def err(msg, code: int = EXIT_ERROR):
    click.echo(click.style(f"Error ({code}): {msg}", fg="red"), err=True)
    sys.exit(code)


def api_err(msg: str, resp: dict):
    """Print API error with error code and exit with mapped code"""
    api_code = resp.get("errorCode", "")
    code_str = f" ({api_code})" if api_code else ""
    err(f"{msg}{code_str}: {resp.get('message', resp)}", get_exit_code(resp))


class ReportPortalClient:
    """ReportPortal API client - centralized API operations"""

    def __init__(self, url: str, project: str, token: str):
        self.url = url.rstrip("/")
        self.project = project
        self.token = token
        self.base_url = f"{self.url}/api/v1/{self.project}"
        self.headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    # Core HTTP methods
    def _handle_request(self, method: str, url: str, **kwargs) -> requests.Response:
        """Execute HTTP request with connection error handling."""
        try:
            return getattr(requests, method)(url, headers=self.headers, **kwargs)
        except requests.exceptions.ConnectionError:
            err(f"Connection error: cannot reach {self.url}", EXIT_CONNECTION_ERROR)
        except requests.exceptions.Timeout:
            err(f"Connection timeout: {self.url}", EXIT_CONNECTION_ERROR)
        except requests.exceptions.RequestException as e:
            err(f"Request error: {e}", EXIT_CONNECTION_ERROR)

    def get(self, endpoint: str) -> dict:
        url = f"{self.base_url}/{endpoint}" if not endpoint.startswith("http") else endpoint
        return self._handle_request("get", url).json()

    def post(self, endpoint: str, data: dict) -> dict:
        return self._handle_request("post", f"{self.base_url}/{endpoint}", json=data).json()

    def put(self, endpoint: str, data: dict) -> dict:
        resp = self._handle_request("put", f"{self.base_url}/{endpoint}", json=data)
        return resp.json() if resp.text else {}

    def validate_token(self) -> bool:
        try:
            result = self.get("dashboard")
            return "content" in result
        except Exception:
            return False

    # Dashboard operations
    def list_dashboards(self) -> list:
        return self.get("dashboard").get("content", [])

    def get_dashboard(self, dashboard_id: int) -> dict:
        return self.get(f"dashboard/{dashboard_id}")

    def create_dashboard(self, name: str, description: str = "") -> dict:
        return self.post("dashboard", {"name": name, "description": description})

    def find_dashboard_by_name(self, name: str) -> dict | None:
        result = self.get(f"dashboard?filter.eq.name={quote(name)}")
        content = result.get("content", [])
        return content[0] if content else None

    def add_widget_to_dashboard(self, dashboard_id: int, widget_data: dict) -> dict:
        return self.put(f"dashboard/{dashboard_id}/add", {"addWidget": widget_data})

    # Widget operations
    def get_widget(self, widget_id: int) -> dict:
        return self.get(f"widget/{widget_id}")

    def create_widget(self, data: dict) -> dict:
        return self.post("widget", data)

    # Filter operations
    def list_filters(self) -> list:
        return self.get("filter?page.size=100").get("content", [])

    def get_filter(self, filter_id: int) -> dict:
        return self.get(f"filter/{filter_id}")

    def create_filter(self, data: dict) -> dict:
        return self.post("filter", data)

    def find_filter_by_name(self, name: str) -> dict:
        result = self.get(f"filter?filter.eq.name={quote(name)}")
        content = result.get("content", [])
        return content[0] if content else None

    def create_or_find_filter(self, payload: dict) -> tuple:
        """Create filter or find existing by name. Returns (id, created_bool)"""
        resp = self.create_filter(payload)
        if resp.get("id"):
            return resp["id"], True
        existing = self.find_filter_by_name(payload["name"])
        return (existing["id"], False) if existing else (None, False)

    # Launch/Test item operations (for upload)
    def start_launch(self, name: str, description: str = "", attributes: list | None = None) -> str:
        return self.post(
            "launch",
            {
                "name": name,
                "description": description,
                "startTime": self._timestamp(),
                "mode": "DEFAULT",
                "attributes": attributes or [],
            },
        ).get("id")

    def finish_launch(self, launch_uuid: str) -> None:
        self.put(f"launch/{launch_uuid}/finish", {"endTime": self._timestamp()})

    def start_item(
        self,
        name: str,
        item_type: str,
        launch_uuid: str,
        parent_uuid: str | None = None,
        attributes: list | None = None,
        code_ref: str | None = None,
    ) -> str:
        data = {
            "name": name,
            "startTime": self._timestamp(),
            "type": item_type,
            "launchUuid": launch_uuid,
            "attributes": attributes or [],
        }
        if code_ref:
            data["codeRef"] = code_ref
        endpoint = f"item/{parent_uuid}" if parent_uuid else "item"
        return self.post(endpoint, data).get("id")

    def finish_item(self, item_uuid: str, launch_uuid: str, status: str, has_issue: bool = False) -> None:
        data = {"endTime": self._timestamp(), "status": status, "launchUuid": launch_uuid}
        if has_issue and status == "FAILED":
            data["issue"] = {"issueType": ISSUE_TO_INVESTIGATE}
        self.put(f"item/{item_uuid}", data)

    @staticmethod
    def _timestamp() -> str:
        return datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


# ============================================================================
# Helper Functions
# ============================================================================
def load_json_file(file_path: str) -> dict:
    """Load and validate JSON file"""
    if not os.path.exists(file_path):
        err(f"File not found: {file_path}", EXIT_FILE_NOT_FOUND)
    with open(file_path) as f:
        return json.load(f)


def read_file_or_value(file_path: str | None, direct_value: str | None, description: str = "File") -> str | None:
    """Read content from file if path provided, otherwise return direct value."""
    if file_path:
        if not os.path.exists(file_path):
            err(f"{description} not found: {file_path}", EXIT_FILE_NOT_FOUND)
        return Path(file_path).read_text().strip()
    return direct_value


def save_json_file(file_path: str, data: dict) -> None:
    """Save data to JSON file"""
    with open(file_path, "w") as f:
        json.dump(data, f, indent=2)


def build_filter_import(filter_data: dict) -> dict:
    """Build filter data for import action"""
    return {
        "name": filter_data["name"],
        "type": filter_data["type"],
        "conditions": filter_data["conditions"],
        "orders": filter_data.get("orders", []),
    }


def build_filter_export(filter_data: dict) -> dict:
    """Build filter data for export action (includes sourceFilterId)"""
    return {"sourceFilterId": filter_data["id"], **build_filter_import(filter_data)}


def build_widget_payload(widget: dict, filter_ids: list) -> dict:
    """Build widget creation payload"""
    wname, wtype = widget["widgetName"], widget["widgetType"]

    if "contentParameters" in widget:
        return {
            "name": wname,
            "widgetType": wtype,
            "filterIds": filter_ids,
            "contentParameters": widget["contentParameters"],
        }
    return {
        "name": wname,
        "widgetType": wtype,
        "filterIds": filter_ids,
        "contentParameters": {"contentFields": [], "itemsCount": 600, "widgetOptions": widget.get("widgetOptions", {})},
    }


def build_export_metadata(export_type: str, project: str, source_id: int) -> dict:
    """Build standardized export metadata"""
    return {
        "type": export_type,
        "exportedAt": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "project": project,
        "sourceId": source_id,
    }


def apply_rename_and_title(args, data: dict) -> dict:
    """Apply --rename and --title to export data."""
    if getattr(args, "rename", None):
        pattern, replacement = args.rename
        info(f"Renaming: '{pattern}' -> '{replacement}'")
        data = apply_rename(data, pattern, replacement)

    if getattr(args, "title", None):
        data["name"] = args.title

    return data


def apply_rename(data: dict, pattern: str, replacement: str) -> dict:
    """
    Apply regex rename to dashboard/filter JSON.
    Renames: dashboard name, widget names, filter names, filter condition values.
    Also strips auto-generated suffixes like _076 from widget names and ensures uniqueness.
    """

    def gsub(text: str) -> str:
        if text is None:
            return text
        return re.sub(pattern, replacement, str(text))

    # Rename dashboard/filter name
    if "name" in data:
        data["name"] = gsub(data["name"])

    # Process widgets
    if "widgets" in data:
        # First pass: strip suffixes and apply rename
        for widget in data["widgets"]:
            name = widget.get("widgetName", "")
            # Strip auto-generated suffix like _076
            name = re.sub(r"_\d+$", "", name)
            # Apply rename pattern
            name = gsub(name)
            widget["widgetName"] = name

        # Second pass: ensure unique names by adding counter
        name_counts = {}
        for widget in data["widgets"]:
            name = widget["widgetName"]
            if name in name_counts:
                name_counts[name] += 1
                widget["widgetName"] = f"{name} ({name_counts[name]})"
            else:
                name_counts[name] = 1

    # Process filters
    if "filters" in data:
        for f in data["filters"]:
            f["name"] = gsub(f["name"])
            if "conditions" in f:
                for cond in f["conditions"]:
                    if "value" in cond:
                        cond["value"] = gsub(cond["value"])

    return data


# ============================================================================
# LIST Command
# ============================================================================
def cmd_list(args, client: ReportPortalClient):
    what = args.type or "dashboards"

    if what in ["dashboards", "d"]:
        info(f"Dashboards in {client.project}:\n")
        items = client.list_dashboards()
        for item in items:
            widgets = len(item.get("widgets", []))
            print(f"  {item['id']}\t{item['name']}\t({widgets} widgets)")

    elif what in ["filters", "f"]:
        info(f"Filters in {client.project}:\n")
        items = client.list_filters()
        for item in items:
            print(f"  {item['id']}\t{item['name']}\t{item.get('type', '')}")
    else:
        err(f"Unknown type: {what}. Use 'dashboards' or 'filters'")


# ============================================================================
# EXPORT Commands
# ============================================================================
def check_resource_not_exists(client: ReportPortalClient, resource_type: str, name: str) -> None:
    """Check if a resource with the given name already exists. Raises error if it does."""
    if resource_type == "dashboard":
        existing = client.find_dashboard_by_name(name)
    else:
        existing = client.find_filter_by_name(name)

    if existing:
        err(f"{resource_type.capitalize()} '{name}' already exists (ID: {existing['id']})", EXIT_DUPLICATE)


def cmd_export_filter(args, client: ReportPortalClient):
    filter_id = args.id
    output_file = args.output or f"filter-{filter_id}.json"

    info(f"Exporting filter {filter_id}...")

    data = client.get_filter(filter_id)
    if "id" not in data:
        err("Filter not found", EXIT_NOT_FOUND)

    export_data = {
        "_metadata": build_export_metadata("filter", client.project, data["id"]),
        **build_filter_export(data),
    }
    # Remove sourceFilterId from top level (it's in metadata)
    export_data.pop("sourceFilterId", None)

    export_data = apply_rename_and_title(args, export_data)

    save_json_file(output_file, export_data)

    ok(f"✓ Exported: {output_file}")
    print(f"  Name: {export_data['name']}")
    print(f"  Type: {data['type']}")
    print(f"  Conditions: {len(data['conditions'])}")


def cmd_export_dashboard(args, client: ReportPortalClient):  # noqa: PLR0914
    dashboard_id = args.id
    output_file = args.output or f"dashboard-{dashboard_id}.json"
    filter_ids = args.filters.split(",") if args.filters else []

    info(f"Exporting dashboard {dashboard_id}...")

    data = client.get_dashboard(dashboard_id)
    if "id" not in data:
        err("Dashboard not found", EXIT_NOT_FOUND)

    # Build base export
    export_data = {
        "_metadata": build_export_metadata("dashboard", client.project, data["id"]),
        "name": data["name"],
        "description": data.get("description", ""),
        "widgets": [],
    }

    # Process widgets and auto-detect filters
    info("Fetching widget details and filters...")
    detected_filter_ids = set()
    unsupported_widgets = []

    for widget in data.get("widgets", []):
        wid = widget["widgetId"]
        wname = widget["widgetName"]
        wtype = widget["widgetType"]

        widget_export = {
            "widgetId": wid,
            "widgetName": wname,
            "widgetType": wtype,
            "widgetSize": widget.get("widgetSize", {}),
            "widgetPosition": widget.get("widgetPosition", {}),
            "widgetOptions": widget.get("widgetOptions", {}),
        }

        # Try to get full widget data
        widget_data = client.get_widget(wid)

        if "errorCode" in widget_data:
            # Plugin widget - try to find filter by name
            filter_match = client.find_filter_by_name(wname)
            if filter_match:
                fid = filter_match["id"]
                if fid not in detected_filter_ids:
                    detected_filter_ids.add(fid)
                    print(f"  Widget '{wname}' -> filter {fid} (by name)")
            else:
                unsupported_widgets.append(wname)
        else:
            # Standard widget - get real name and contentParameters
            real_name = widget_data.get("name")
            if real_name:
                widget_export["widgetName"] = real_name
                wname = real_name

            content_params = widget_data.get("contentParameters")
            if content_params:
                widget_export["contentParameters"] = content_params

            # Extract filter IDs from appliedFilters
            for af in widget_data.get("appliedFilters", []):
                fid = af.get("id")
                if fid and fid not in detected_filter_ids:
                    detected_filter_ids.add(fid)
                    print(f"  Widget '{wname}' -> filter {fid}")

        export_data["widgets"].append(widget_export)

    # Use detected filters if none specified
    if not filter_ids and detected_filter_ids:
        filter_ids = list(detected_filter_ids)

    if not detected_filter_ids:
        print("  No filters detected")
        if unsupported_widgets:
            warn(f"  Widgets without matching filter: {', '.join(unsupported_widgets)}")
            warn("  Use --filters=ID1,ID2 to specify manually")
    elif unsupported_widgets:
        info(f"  Note: '{', '.join(unsupported_widgets)}' may share detected filter(s)")

    # Fetch and include filters
    if filter_ids:
        export_data["filters"] = []
        for fid in filter_ids:
            fid = str(fid).strip()
            if not fid.isdigit():
                continue
            print(f"  Fetching filter {fid}... ", end="")
            filter_data = client.get_filter(int(fid))
            if "id" in filter_data:
                export_data["filters"].append(build_filter_export(filter_data))
                ok(filter_data["name"])
            else:
                print("not found, skipping")

    export_data = apply_rename_and_title(args, export_data)

    save_json_file(output_file, export_data)

    ok(f"✓ Exported: {output_file}")
    print(f"  Name: {export_data['name']}")
    print(f"  Widgets: {len(data.get('widgets', []))}")
    if "filters" in export_data:
        print(f"  Filters: {len(export_data['filters'])}")


# ============================================================================
# IMPORT Commands
# ============================================================================
def cmd_import(args, client: ReportPortalClient):
    data = load_json_file(args.file)

    # Auto-detect type
    if "widgets" in data:
        cmd_import_dashboard(args, client, data)
    elif "conditions" in data:
        cmd_import_filter(args, client, data)
    else:
        err("Invalid JSON: must be dashboard (.widgets) or filter (.conditions)", EXIT_USAGE)


def cmd_import_filter(args, client: ReportPortalClient, data: dict | None = None):
    if data is None:
        data = load_json_file(args.file)

    name = getattr(args, "title", None) or data.get("name")

    # Check if filter already exists (skip if already checked by caller)
    if not getattr(args, "_skip_exists_check", False):
        check_resource_not_exists(client, "filter", name)

    info(f"Importing filter: {name}")

    payload = build_filter_import({**data, "name": name})
    resp = client.create_filter(payload)

    if resp.get("id"):
        ok(f"✓ Created filter (ID: {resp['id']})")
    else:
        api_err("Failed to create filter", resp)


def cmd_import_dashboard(args, client: ReportPortalClient, data: dict | None = None):  # noqa: PLR0914
    if data is None:
        data = load_json_file(args.file)

    data = apply_rename_and_title(args, data)

    name = data.get("name")
    description = data.get("description", "")

    # Check if dashboard already exists (skip if already checked by caller)
    if not getattr(args, "_skip_exists_check", False):
        check_resource_not_exists(client, "dashboard", name)

    # Track filter ID mapping (sourceId -> newId)
    filter_map = {}

    # Import embedded filters using helper
    if "filters" in data:
        info(f"Creating {len(data['filters'])} embedded filter(s)...")
        for f in data["filters"]:
            filter_name = f["name"]
            source_id = f.get("sourceFilterId")
            print(f"  {filter_name}... ", end="")

            new_id, created = client.create_or_find_filter(build_filter_import(f))

            if new_id:
                ok(f"{'created' if created else 'found'} (ID: {new_id})")
                if source_id:
                    filter_map[source_id] = new_id
            else:
                print("not found")
        print()

    info(f"Importing dashboard: {name}")

    # Create dashboard
    resp = client.create_dashboard(name, description)
    dashboard_id = resp.get("id")
    if not dashboard_id:
        api_err("Failed to create dashboard", resp)

    ok(f"✓ Created dashboard (ID: {dashboard_id})")

    # Get filter IDs for new widgets
    new_filter_ids = list(filter_map.values()) if filter_map else []

    # Create widgets and add to dashboard
    total, added = 0, 0

    for widget in data.get("widgets", []):
        total += 1
        wname, wtype = widget["widgetName"], widget["widgetType"]
        print(f"  Creating: {wname}... ", end="")

        # Use helper to build payload
        widget_payload = build_widget_payload(widget, new_filter_ids)
        widget_resp = client.create_widget(widget_payload)
        new_wid = widget_resp.get("id")

        if new_wid:
            print(f"ID {new_wid}, adding... ", end="")

            add_payload = {
                "widgetId": new_wid,
                "widgetName": wname,
                "widgetType": wtype,
                "widgetPosition": widget.get("widgetPosition", {}),
                "widgetSize": widget.get("widgetSize", {}),
            }

            resp = client.add_widget_to_dashboard(dashboard_id, add_payload)
            if "successfully" in str(resp).lower() or resp.get("id"):
                ok("✓")
                added += 1
            else:
                click.echo(click.style("✗", fg="red") + f" {resp.get('message', resp)}")
        else:
            click.echo(click.style("✗", fg="red") + f" {widget_resp.get('message', widget_resp)}")

    print()
    ok(f"Done! {added}/{total} widgets created")
    print(f"URL: {client.url}/ui/#{client.project}/dashboard/{dashboard_id}")


# ============================================================================
# UPLOAD Command (xUnit)
# ============================================================================
def cmd_upload(args, client: ReportPortalClient):
    file_path = args.file

    if not os.path.exists(file_path):
        err(f"File not found: {file_path}", EXIT_FILE_NOT_FOUND)

    description = read_file_or_value(args.description_file, args.description, "Description file")
    attributes = read_file_or_value(args.attribute_file, args.attributes, "Attribute file")

    _upload_xunit(client, file_path, args.name, description, attributes)


def _upload_xunit(  # noqa: PLR0914
    client: ReportPortalClient,
    file_path: str,
    name: str | None = None,
    description: str | None = None,
    attributes: str | None = None,
):
    """Internal xUnit upload logic - reusable"""
    launch_name = name or Path(file_path).stem
    launch_desc = description or "Imported via rp-cli.py"
    launch_attrs = parse_attributes(attributes)

    info("Uploading xUnit results to ReportPortal...")
    print(f"  File: {file_path}")
    print(f"  Launch: {launch_name}")
    if launch_attrs:
        print(f"  Attributes: {attributes}")

    # Parse xUnit
    tree = ET.parse(file_path)
    root = tree.getroot()

    testsuites = root.findall(".//testsuite")
    if not testsuites and root.tag == "testsuite":
        testsuites = [root]

    if not testsuites:
        err("No testsuites found in xUnit file")

    # Start launch
    launch_uuid = client.start_launch(launch_name, launch_desc, launch_attrs)
    print(f"  Started launch: {launch_uuid}")

    stats = {"total": 0, "passed": 0, "failed": 0, "skipped": 0}

    try:
        for suite in testsuites:
            suite_name = suite.get("name", "Unknown Suite")

            suite_uuid = client.start_item(name=suite_name, item_type="SUITE", launch_uuid=launch_uuid)

            for testcase in suite.findall("testcase"):
                test_name = testcase.get("name", "Unknown Test")
                classname = testcase.get("classname", "")
                status = get_test_status(testcase)
                component = get_component(testcase)

                test_attrs = []
                if component:
                    test_attrs.append({"key": "Component", "value": component})

                test_uuid = client.start_item(
                    name=test_name,
                    item_type="TEST",
                    launch_uuid=launch_uuid,
                    parent_uuid=suite_uuid,
                    attributes=test_attrs,
                    code_ref=classname if classname else None,
                )

                has_issue = testcase.find("failure") is not None or testcase.find("error") is not None

                client.finish_item(test_uuid, launch_uuid, status, has_issue)

                stats["total"] += 1
                if status == "PASSED":
                    stats["passed"] += 1
                elif status == "FAILED":
                    stats["failed"] += 1
                else:
                    stats["skipped"] += 1

            client.finish_item(suite_uuid, launch_uuid, "PASSED")

        client.finish_launch(launch_uuid)

        print(
            f"  Tests: {stats['total']} (passed: {stats['passed']}, "
            f"failed: {stats['failed']}, skipped: {stats['skipped']})"
        )
        ok("✓ Upload complete")
        print(f"  URL: {client.url}/ui/#{client.project}/launches/all/{launch_uuid}")

    except Exception as e:
        print(f"Error during upload: {e}")
        try:
            client.finish_launch(launch_uuid)
        except Exception:
            pass
        sys.exit(1)


def get_test_status(testcase) -> str:
    """Get test status from xUnit testcase element."""
    if testcase.find("failure") is not None or testcase.find("error") is not None:
        return "FAILED"
    if testcase.find("skipped") is not None:
        return "SKIPPED"
    return "PASSED"


def get_component(testcase):
    props = testcase.find("properties")
    if props is not None:
        for prop in props.findall("property"):
            if prop.get("name", "").lower() == "component":
                return prop.get("value", "")
    return None


def parse_attributes(attrs_str: str) -> list:
    if not attrs_str:
        return []
    result = []
    for pair in attrs_str.split(","):
        pair = pair.strip()
        if ":" in pair:
            key, val = pair.split(":", 1)
            result.append({"key": key.strip(), "value": val.strip()})
        elif pair:
            result.append({"value": pair})
    return result


# ============================================================================
# URL Command (parse full RP URL)
# ============================================================================
def parse_rp_url(url: str) -> dict:
    """
    Parse a full ReportPortal resource URL and extract components.

    Example URL:
    https://reportportal.example.com/ui/#opendatascience/dashboard/123

    Returns:
        {"server": "https://...", "project": "...", "resource_type": "dashboard", "resource_id": 123}
    """
    # Pattern: server/ui/#project/resource_type/resource_id
    match = re.match(r"^(https?://[^/]+)/ui/#([^/]+)/([^/]+)/(\d+)(?:\?.*)?$", url)
    if not match:
        return None

    return {
        "server": match.group(1),
        "project": match.group(2),
        "resource_type": match.group(3),
        "resource_id": int(match.group(4)),
    }


# ============================================================================
# CLI with Click
# ============================================================================
class Config:
    """Shared configuration passed between commands."""

    def __init__(self):
        self.server = None
        self.project = None
        self.token = None
        self.client = None


pass_config = click.make_pass_decorator(Config, ensure=True)


def get_token(token: str | None, token_file: str | None) -> str | None:
    """Resolve token from arg, file, or default location."""
    if token:
        return token
    if token_file:
        return Path(token_file).read_text().strip()
    # Try default token file
    script_dir = Path(__file__).parent
    default_file = script_dir / "secrets" / "rp-api-token"
    if default_file.exists():
        return default_file.read_text().strip()
    return None


def require_client(config: Config) -> ReportPortalClient:
    """Ensure client is initialized, or error."""
    if config.client:
        return config.client
    if not config.server:
        err("ReportPortal server URL required. Set RP_SERVER or use --server")
    if not config.project:
        err("Project name required. Set RP_PROJECT or use --project")
    if not config.token:
        err("API token required. Set RP_API_TOKEN, use --token, or --token-file", EXIT_AUTH_ERROR)
    client = ReportPortalClient(config.server, config.project, config.token)
    if not client.validate_token():
        err("Invalid token or cannot connect to ReportPortal. Run --help for auth instructions.", EXIT_AUTH_ERROR)
    config.client = client
    return client


def require_client_for_source(
    config: Config, source: str, resource_id: int | None
) -> tuple[ReportPortalClient, str, int]:
    """
    Get client and resolve source to resource_type and resource_id.
    If source is a URL, extracts server/project from it and creates client.
    Otherwise uses config's server/project.
    Returns (client, resource_type, resource_id).
    """
    if not config.token:
        err("API token required. Set RP_API_TOKEN, use --token, or --token-file", EXIT_AUTH_ERROR)

    if source.startswith("http"):
        parsed = parse_rp_url(source)
        if not parsed:
            usage_err("Invalid ReportPortal URL format. Expected: https://server/ui/#project/resource_type/id")

        info("Parsed URL:")
        print(f"  Server: {parsed['server']}")
        print(f"  Project: {parsed['project']}")
        print(f"  Type: {parsed['resource_type']}")
        print(f"  ID: {parsed['resource_id']}")
        print()

        client = ReportPortalClient(parsed["server"], parsed["project"], config.token)
        if not client.validate_token():
            err("Invalid token or cannot connect to ReportPortal.", EXIT_AUTH_ERROR)

        return client, parsed["resource_type"], parsed["resource_id"]

    # Source is a type (dashboard/filter)
    if source not in ["dashboard", "filter"]:
        usage_err(f"Invalid source '{source}'. Use 'dashboard', 'filter', or a full URL")
    if not resource_id:
        usage_err("Resource ID required when source is type (not URL)")

    client = require_client(config)
    return client, source, resource_id


@click.group(epilog=__doc__)
@click.option("--server", envvar="RP_SERVER", help="ReportPortal server URL (or set RP_SERVER)")
@click.option("--project", envvar="RP_PROJECT", help="ReportPortal project name (or set RP_PROJECT)")
@click.option("--token", envvar="RP_API_TOKEN", help="API token (or set RP_API_TOKEN)")
@click.option("--token-file", help="Path to file containing API token")
@pass_config
def cli(config: Config, server: str, project: str, token: str, token_file: str):
    """ReportPortal CLI Tool - Manage dashboards, filters, and upload test results."""
    config.server = server
    config.project = project
    config.token = get_token(token, token_file)


@cli.command("list")
@click.argument("resource_type", default="dashboards", required=False)
@pass_config
def cli_list(config: Config, resource_type: str):
    """List dashboards or filters."""
    client = require_client(config)
    args = Namespace(type=resource_type)
    cmd_list(args, client)


@cli.command("export")
@click.argument("source")
@click.argument("id", required=False, type=int)
@click.option("-o", "--output", help="Output file (default: auto-generated)")
@click.option("-t", "--title", help="Override resource name/title in exported JSON")
@click.option("--filters", help="Filter IDs to include (comma-separated)")
@click.option("--rename", nargs=2, help="Rename pattern: OLD NEW (regex supported)")
@pass_config
def cli_export(config: Config, source: str, id: int, output: str, title: str, filters: str, rename: tuple):
    """Export dashboard or filter (by type+id or URL)."""
    client, resource_type, resource_id = require_client_for_source(config, source, id)
    args = Namespace(id=resource_id, output=output, title=title, filters=filters, rename=rename)

    if resource_type == "dashboard":
        cmd_export_dashboard(args, client)
    else:
        cmd_export_filter(args, client)


@cli.command("import")
@click.argument("file")
@click.option("-t", "--title", help="Override resource name/title")
@click.option("--rename", nargs=2, help="Rename pattern: OLD NEW (regex supported)")
@pass_config
def cli_import(config: Config, file: str, title: str, rename: tuple):
    """Import dashboard or filter from JSON file."""
    if file.startswith("http"):
        usage_err("import expects a JSON file, not a URL. Use 'copy' to duplicate from a URL.")

    client = require_client(config)
    args = Namespace(file=file, title=title, rename=rename)
    cmd_import(args, client)


@cli.command("copy")
@click.argument("source")
@click.argument("id", required=False, type=int)
@click.option("-t", "--title", help="New title for the copy")
@click.option("--filters", help="Filter IDs to include (comma-separated, dashboards only)")
@click.option("--rename", nargs=2, help="Rename pattern: OLD NEW (regex supported)")
@pass_config
def cli_copy(config: Config, source: str, id: int, title: str, filters: str, rename: tuple):
    """Copy/duplicate dashboard or filter (by type+id or URL)."""
    client, resource_type, resource_id = require_client_for_source(config, source, id)

    # Determine target title (explicit --title or apply --rename to original name)
    if title:
        target_title = title
    else:
        if resource_type == "dashboard":
            original = client.get_dashboard(resource_id)
        else:
            original = client.get_filter(resource_id)

        if "id" not in original:
            err(f"{resource_type.capitalize()} not found", EXIT_NOT_FOUND)

        target_title = original.get("name", f"{resource_type.capitalize()} {resource_id}")
        if rename:
            target_title = re.sub(rename[0], rename[1], target_title)

    # Check if target already exists
    check_resource_not_exists(client, resource_type, target_title)

    # Export to temp file
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        temp_file = f.name

    try:
        export_args = Namespace(id=resource_id, output=temp_file, filters=filters, rename=rename, title=None)

        if resource_type == "dashboard":
            cmd_export_dashboard(export_args, client)
        else:
            cmd_export_filter(export_args, client)

        print()

        # Import with title (skip existence check - already done)
        import_args = Namespace(file=temp_file, title=target_title, rename=None, _skip_exists_check=True)
        cmd_import(import_args, client)
    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)


@cli.command("upload")
@click.argument("file")
@click.option("-n", "--name", help="Launch name (default: filename)")
@click.option("-d", "--description", help="Launch description")
@click.option("-df", "--description-file", help="Path to file containing launch description")
@click.option("-a", "--attributes", help="Launch attributes (key1:val1,key2:val2)")
@click.option("-af", "--attribute-file", help="Path to file containing launch attributes")
@pass_config
def cli_upload(
    config: Config, file: str, name: str, description: str, description_file: str, attributes: str, attribute_file: str
):
    """Upload xUnit test results."""
    client = require_client(config)
    args = Namespace(
        file=file,
        name=name,
        description=description,
        description_file=description_file,
        attributes=attributes,
        attribute_file=attribute_file,
    )
    cmd_upload(args, client)


if __name__ == "__main__":
    cli()
