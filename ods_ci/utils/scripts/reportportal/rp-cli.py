#!/usr/bin/env python3
"""
ReportPortal CLI Tool - Manage dashboards, filters, and upload test results.

Run with --help for usage details.
"""

import argparse
import json
import os
import re
import sys
import tempfile
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote

try:
    import requests
except ImportError:
    print("Error: 'requests' module required. Install with: pip install requests")
    sys.exit(1)

# Configuration via env vars or CLI flags (no defaults - must be provided)
# RP_URL, RP_PROJECT, RP_API_TOKEN

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color


def info(msg):
    print(f"{Colors.BLUE}{msg}{Colors.NC}")

def ok(msg):
    print(f"{Colors.GREEN}{msg}{Colors.NC}")

def warn(msg):
    print(f"{Colors.YELLOW}{msg}{Colors.NC}")

def err(msg):
    print(f"{Colors.RED}Error: {msg}{Colors.NC}", file=sys.stderr)
    sys.exit(1)


class ReportPortalClient:
    """ReportPortal API client - centralized API operations"""

    def __init__(self, url: str, project: str, token: str):
        self.url = url.rstrip('/')
        self.project = project
        self.token = token
        self.base_url = f"{self.url}/api/v1/{self.project}"
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }

    # Core HTTP methods
    def get(self, endpoint: str) -> dict:
        url = f"{self.base_url}/{endpoint}" if not endpoint.startswith('http') else endpoint
        return requests.get(url, headers=self.headers).json()

    def post(self, endpoint: str, data: dict) -> dict:
        return requests.post(f"{self.base_url}/{endpoint}", headers=self.headers, json=data).json()

    def put(self, endpoint: str, data: dict) -> dict:
        resp = requests.put(f"{self.base_url}/{endpoint}", headers=self.headers, json=data)
        return resp.json() if resp.text else {}

    def validate_token(self) -> bool:
        try:
            return requests.get(f"{self.base_url}/dashboard", headers=self.headers).status_code == 200
        except Exception:
            return False

    # Dashboard operations
    def list_dashboards(self) -> list:
        return self.get("dashboard").get("content", [])

    def get_dashboard(self, dashboard_id: int) -> dict:
        return self.get(f"dashboard/{dashboard_id}")

    def create_dashboard(self, name: str, description: str = "") -> dict:
        return self.post("dashboard", {"name": name, "description": description})

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
        if resp.get('id'):
            return resp['id'], True
        existing = self.find_filter_by_name(payload['name'])
        return (existing['id'], False) if existing else (None, False)

    # Launch/Test item operations (for upload)
    def start_launch(self, name: str, description: str = "", attributes: list = None) -> str:
        return self.post("launch", {
            "name": name,
            "description": description,
            "startTime": self._timestamp(),
            "mode": "DEFAULT",
            "attributes": attributes or []
        }).get("id")

    def finish_launch(self, launch_uuid: str) -> None:
        self.put(f"launch/{launch_uuid}/finish", {"endTime": self._timestamp()})

    def start_item(self, name: str, item_type: str, launch_uuid: str,
                   parent_uuid: str = None, attributes: list = None,
                   code_ref: str = None) -> str:
        data = {
            "name": name,
            "startTime": self._timestamp(),
            "type": item_type,
            "launchUuid": launch_uuid,
            "attributes": attributes or []
        }
        if code_ref:
            data["codeRef"] = code_ref
        endpoint = f"item/{parent_uuid}" if parent_uuid else "item"
        return self.post(endpoint, data).get("id")

    def finish_item(self, item_uuid: str, launch_uuid: str, status: str,
                    has_issue: bool = False) -> None:
        data = {"endTime": self._timestamp(), "status": status, "launchUuid": launch_uuid}
        if has_issue and status == "FAILED":
            data["issue"] = {"issueType": "TI001"}
        self.put(f"item/{item_uuid}", data)

    @staticmethod
    def _timestamp() -> str:
        return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


# ============================================================================
# Helper Functions
# ============================================================================
def load_json_file(file_path: str) -> dict:
    """Load and validate JSON file"""
    if not os.path.exists(file_path):
        err(f"File not found: {file_path}")
    with open(file_path) as f:
        return json.load(f)


def save_json_file(file_path: str, data: dict) -> None:
    """Save data to JSON file"""
    with open(file_path, 'w') as f:
        json.dump(data, f, indent=2)


def build_filter_export(filter_data: dict) -> dict:
    """Build standardized filter export structure"""
    return {
        'sourceFilterId': filter_data['id'],
        'name': filter_data['name'],
        'type': filter_data['type'],
        'conditions': filter_data['conditions'],
        'orders': filter_data.get('orders', [])
    }


def build_filter_payload(filter_data: dict) -> dict:
    """Build filter creation payload"""
    return {
        "name": filter_data['name'],
        "type": filter_data['type'],
        "conditions": filter_data['conditions'],
        "orders": filter_data.get('orders', [])
    }


def build_widget_payload(widget: dict, filter_ids: list) -> dict:
    """Build widget creation payload"""
    wname, wtype = widget['widgetName'], widget['widgetType']

    if 'contentParameters' in widget:
        return {
            "name": wname,
            "widgetType": wtype,
            "filterIds": filter_ids,
            "contentParameters": widget['contentParameters']
        }
    return {
        "name": wname,
        "widgetType": wtype,
        "filterIds": filter_ids,
        "contentParameters": {
            "contentFields": [],
            "itemsCount": 600,
            "widgetOptions": widget.get('widgetOptions', {})
        }
    }


def build_export_metadata(export_type: str, project: str, source_id: int) -> dict:
    """Build standardized export metadata"""
    return {
        "type": export_type,
        "exportedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "project": project,
        "sourceId": source_id
    }


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
    if 'name' in data:
        data['name'] = gsub(data['name'])

    # Process widgets
    if 'widgets' in data:
        # First pass: strip suffixes and apply rename
        for widget in data['widgets']:
            name = widget.get('widgetName', '')
            # Strip auto-generated suffix like _076
            name = re.sub(r'_\d+$', '', name)
            # Apply rename pattern
            name = gsub(name)
            widget['widgetName'] = name

        # Second pass: ensure unique names by adding counter
        name_counts = {}
        for widget in data['widgets']:
            name = widget['widgetName']
            if name in name_counts:
                name_counts[name] += 1
                widget['widgetName'] = f"{name} ({name_counts[name]})"
            else:
                name_counts[name] = 1

    # Process filters
    if 'filters' in data:
        for f in data['filters']:
            f['name'] = gsub(f['name'])
            if 'conditions' in f:
                for cond in f['conditions']:
                    if 'value' in cond:
                        cond['value'] = gsub(cond['value'])

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
            widgets = len(item.get('widgets', []))
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
def cmd_export(args, client: ReportPortalClient):
    if args.type == "dashboard":
        cmd_export_dashboard(args, client)
    elif args.type == "filter":
        cmd_export_filter(args, client)
    else:
        err("Usage: export [dashboard|filter] <id> [file]")


def cmd_export_filter(args, client: ReportPortalClient):
    filter_id = args.id
    output_file = args.file or f"filter-{filter_id}.json"

    info(f"Exporting filter {filter_id}...")

    data = client.get_filter(filter_id)
    if 'id' not in data:
        err("Filter not found")

    export_data = {
        "_metadata": build_export_metadata("filter", client.project, data['id']),
        **build_filter_export(data)
    }
    # Remove sourceFilterId from top level (it's in metadata)
    export_data.pop('sourceFilterId', None)

    save_json_file(output_file, export_data)

    ok(f"✓ Exported: {output_file}")
    print(f"  Name: {data['name']}")
    print(f"  Type: {data['type']}")
    print(f"  Conditions: {len(data['conditions'])}")


def cmd_export_dashboard(args, client: ReportPortalClient):
    dashboard_id = args.id
    output_file = args.file or f"dashboard-{dashboard_id}.json"
    filter_ids = args.filters.split(',') if args.filters else []

    info(f"Exporting dashboard {dashboard_id}...")

    data = client.get_dashboard(dashboard_id)
    if 'id' not in data:
        err("Dashboard not found")

    # Build base export
    export_data = {
        "_metadata": build_export_metadata("dashboard", client.project, data['id']),
        "name": data['name'],
        "description": data.get('description', ''),
        "widgets": []
    }

    # Process widgets and auto-detect filters
    info("Fetching widget details and filters...")
    detected_filter_ids = set()
    unsupported_widgets = []

    for widget in data.get('widgets', []):
        wid = widget['widgetId']
        wname = widget['widgetName']
        wtype = widget['widgetType']

        widget_export = {
            'widgetId': wid,
            'widgetName': wname,
            'widgetType': wtype,
            'widgetSize': widget.get('widgetSize', {}),
            'widgetPosition': widget.get('widgetPosition', {}),
            'widgetOptions': widget.get('widgetOptions', {})
        }

        # Try to get full widget data
        widget_data = client.get_widget(wid)

        if 'errorCode' in widget_data:
            # Plugin widget - try to find filter by name
            filter_match = client.find_filter_by_name(wname)
            if filter_match:
                fid = filter_match['id']
                if fid not in detected_filter_ids:
                    detected_filter_ids.add(fid)
                    print(f"  Widget '{wname}' -> filter {fid} (by name)")
            else:
                unsupported_widgets.append(wname)
        else:
            # Standard widget - get real name and contentParameters
            real_name = widget_data.get('name')
            if real_name:
                widget_export['widgetName'] = real_name
                wname = real_name

            content_params = widget_data.get('contentParameters')
            if content_params:
                widget_export['contentParameters'] = content_params

            # Extract filter IDs from appliedFilters
            for af in widget_data.get('appliedFilters', []):
                fid = af.get('id')
                if fid and fid not in detected_filter_ids:
                    detected_filter_ids.add(fid)
                    print(f"  Widget '{wname}' -> filter {fid}")

        export_data['widgets'].append(widget_export)

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
        export_data['filters'] = []
        for fid in filter_ids:
            fid = str(fid).strip()
            if not fid.isdigit():
                continue
            print(f"  Fetching filter {fid}... ", end='')
            filter_data = client.get_filter(int(fid))
            if 'id' in filter_data:
                export_data['filters'].append(build_filter_export(filter_data))
                ok(filter_data['name'])
            else:
                print("not found, skipping")

    # Apply rename if specified
    if args.rename:
        pattern, replacement = args.rename
        info(f"Renaming: '{pattern}' -> '{replacement}'")
        export_data = apply_rename(export_data, pattern, replacement)

    save_json_file(output_file, export_data)

    ok(f"✓ Exported: {output_file}")
    print(f"  Name: {export_data['name']}")
    print(f"  Widgets: {len(data.get('widgets', []))}")
    if 'filters' in export_data:
        print(f"  Filters: {len(export_data['filters'])}")


# ============================================================================
# IMPORT Commands
# ============================================================================
def cmd_import(args, client: ReportPortalClient):
    data = load_json_file(args.file)

    # Auto-detect type
    if 'widgets' in data:
        cmd_import_dashboard(args, client, data)
    elif 'conditions' in data:
        cmd_import_filter(args, client, data)
    else:
        err("Invalid JSON: must be dashboard (.widgets) or filter (.conditions)")


def cmd_import_filter(args, client: ReportPortalClient, data: dict = None):
    if data is None:
        data = load_json_file(args.file)

    name = args.name or data.get('name')
    info(f"Importing filter: {name}")

    payload = build_filter_payload({**data, 'name': name})
    resp = client.create_filter(payload)

    if resp.get('id'):
        ok(f"✓ Created filter (ID: {resp['id']})")
    else:
        err(f"Failed to create filter: {resp.get('message', resp)}")


def cmd_import_dashboard(args, client: ReportPortalClient, data: dict = None):
    if data is None:
        data = load_json_file(args.file)

    # Apply rename if specified
    if args.rename:
        pattern, replacement = args.rename
        info(f"Renaming: '{pattern}' -> '{replacement}'")
        data = apply_rename(data, pattern, replacement)

    name = args.name or data.get('name')
    description = data.get('description', '')

    # Track filter ID mapping (sourceId -> newId)
    filter_map = {}

    # Import embedded filters using helper
    if 'filters' in data and data['filters']:
        info(f"Creating {len(data['filters'])} embedded filter(s)...")
        for f in data['filters']:
            filter_name = f['name']
            source_id = f.get('sourceFilterId')
            print(f"  {filter_name}... ", end='')

            new_id, created = client.create_or_find_filter(build_filter_payload(f))

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
    dashboard_id = resp.get('id')
    if not dashboard_id:
        err(f"Failed to create dashboard: {resp.get('message', resp)}")

    ok(f"✓ Created dashboard (ID: {dashboard_id})")

    # Get filter IDs for new widgets
    new_filter_ids = list(filter_map.values()) if filter_map else []

    # Create widgets and add to dashboard
    total, added = 0, 0

    for widget in data.get('widgets', []):
        total += 1
        wname, wtype = widget['widgetName'], widget['widgetType']
        print(f"  Creating: {wname}... ", end='')

        # Use helper to build payload
        widget_payload = build_widget_payload(widget, new_filter_ids)
        widget_resp = client.create_widget(widget_payload)
        new_wid = widget_resp.get('id')

        if new_wid:
            print(f"ID {new_wid}, adding... ", end='')

            add_payload = {
                "widgetId": new_wid,
                "widgetName": wname,
                "widgetType": wtype,
                "widgetPosition": widget.get('widgetPosition', {}),
                "widgetSize": widget.get('widgetSize', {})
            }

            resp = client.add_widget_to_dashboard(dashboard_id, add_payload)
            if 'successfully' in str(resp).lower() or resp.get('id'):
                ok("✓")
                added += 1
            else:
                print(f"{Colors.RED}✗{Colors.NC} {resp.get('message', resp)}")
        else:
            print(f"{Colors.RED}✗{Colors.NC} {widget_resp.get('message', widget_resp)}")

    print()
    ok(f"Done! {added}/{total} widgets created")
    print(f"URL: {client.url}/ui/#{client.project}/dashboard/{dashboard_id}")


# ============================================================================
# COPY Command
# ============================================================================
def cmd_copy(args, client: ReportPortalClient):
    dashboard_id = args.id
    name = args.name or f"Copy of Dashboard {dashboard_id}"

    # Create temp file for export
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        temp_file = f.name

    try:
        # Export dashboard
        export_args = argparse.Namespace(
            id=dashboard_id,
            file=temp_file,
            filters=args.filters,
            rename=args.rename
        )
        cmd_export_dashboard(export_args, client)
        print()

        # Import dashboard
        import_args = argparse.Namespace(
            file=temp_file,
            name=name,
            rename=None  # Already applied during export
        )
        cmd_import(import_args, client)
    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)


# ============================================================================
# UPLOAD Command (xUnit)
# ============================================================================
def cmd_upload(args, client: ReportPortalClient):
    file_path = args.file

    if not os.path.exists(file_path):
        err(f"File not found: {file_path}")

    _upload_xunit(client, file_path, args.name, args.description, args.attributes)


def _upload_xunit(client: ReportPortalClient, file_path: str,
                  name: str = None, description: str = None, attributes: str = None):
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

    testsuites = root.findall('.//testsuite')
    if not testsuites and root.tag == 'testsuite':
        testsuites = [root]

    if not testsuites:
        err("No testsuites found in xUnit file")

    # Start launch
    launch_uuid = client.start_launch(launch_name, launch_desc, launch_attrs)
    print(f"  Started launch: {launch_uuid}")

    stats = {"total": 0, "passed": 0, "failed": 0, "skipped": 0}

    try:
        for suite in testsuites:
            suite_name = suite.get('name', 'Unknown Suite')

            suite_uuid = client.start_item(
                name=suite_name,
                item_type="SUITE",
                launch_uuid=launch_uuid
            )

            for testcase in suite.findall('testcase'):
                test_name = testcase.get('name', 'Unknown Test')
                classname = testcase.get('classname', '')
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
                    code_ref=classname if classname else None
                )

                has_issue = (testcase.find('failure') is not None or
                            testcase.find('error') is not None)

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

        print(f"  Tests: {stats['total']} (passed: {stats['passed']}, "
              f"failed: {stats['failed']}, skipped: {stats['skipped']})")
        ok("✓ Upload complete")
        print(f"  URL: {client.url}/ui/#{client.project}/launches/all/{launch_uuid}")

    except Exception as e:
        print(f"Error during upload: {e}")
        try:
            client.finish_launch(launch_uuid)
        except:
            pass
        sys.exit(1)


def get_test_status(testcase):
    if testcase.find('failure') is not None:
        return "FAILED"
    if testcase.find('error') is not None:
        return "FAILED"
    if testcase.find('skipped') is not None:
        return "SKIPPED"
    return "PASSED"


def get_component(testcase):
    props = testcase.find('properties')
    if props is not None:
        for prop in props.findall('property'):
            if prop.get('name', '').lower() == 'component':
                return prop.get('value', '')
    return None


def parse_attributes(attrs_str: str) -> list:
    if not attrs_str:
        return []
    result = []
    for pair in attrs_str.split(','):
        pair = pair.strip()
        if ':' in pair:
            key, val = pair.split(':', 1)
            result.append({"key": key.strip(), "value": val.strip()})
        elif pair:
            result.append({"value": pair})
    return result


# ============================================================================
# MAIN
# ============================================================================
def main():
    parser = argparse.ArgumentParser(
        description="ReportPortal CLI Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    # Global options (all require env var or CLI flag)
    parser.add_argument("--url", default=os.environ.get("RP_URL"),
                        help="ReportPortal URL (or set RP_URL env var)")
    parser.add_argument("--project", default=os.environ.get("RP_PROJECT"),
                        help="ReportPortal project name (or set RP_PROJECT env var)")
    parser.add_argument("--token", default=os.environ.get("RP_API_TOKEN"),
                        help="API token (or set RP_API_TOKEN env var)")
    parser.add_argument("--token-file", help="Path to file containing API token")

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # List command
    list_parser = subparsers.add_parser("list", help="List dashboards or filters")
    list_parser.add_argument("type", nargs="?", default="dashboards",
                             help="What to list: dashboards or filters")

    # Export command
    export_parser = subparsers.add_parser("export", help="Export dashboard or filter")
    export_parser.add_argument("type", choices=["dashboard", "filter"],
                               help="Type to export")
    export_parser.add_argument("id", type=int, help="Dashboard or filter ID")
    export_parser.add_argument("file", nargs="?", help="Output file (default: auto)")
    export_parser.add_argument("--filters", help="Filter IDs to include (comma-separated)")
    export_parser.add_argument("--rename", nargs=2, metavar=("OLD", "NEW"),
                               help="Rename pattern (regex supported)")

    # Import command
    import_parser = subparsers.add_parser("import", help="Import dashboard or filter")
    import_parser.add_argument("file", help="JSON file to import")
    import_parser.add_argument("name", nargs="?", help="Override name")
    import_parser.add_argument("--rename", nargs=2, metavar=("OLD", "NEW"),
                               help="Rename pattern (regex supported)")

    # Copy command
    copy_parser = subparsers.add_parser("copy", help="Copy/duplicate dashboard")
    copy_parser.add_argument("id", type=int, help="Dashboard ID to copy")
    copy_parser.add_argument("name", nargs="?", help="New dashboard name")
    copy_parser.add_argument("--filters", help="Filter IDs to include (comma-separated)")
    copy_parser.add_argument("--rename", nargs=2, metavar=("OLD", "NEW"),
                             help="Rename pattern (regex supported)")

    # Upload command
    upload_parser = subparsers.add_parser("upload", help="Upload xUnit test results")
    upload_parser.add_argument("file", help="Path to xUnit XML file")
    upload_parser.add_argument("--name", "-n", help="Launch name (default: filename)")
    upload_parser.add_argument("--description", "--desc", "-d", help="Launch description")
    upload_parser.add_argument("--attributes", "--attrs", "-a",
                               help="Launch attributes (key1:val1,key2:val2)")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(0)

    # Get token
    token = args.token
    if not token and args.token_file:
        token = Path(args.token_file).read_text().strip()
    if not token:
        # Try default token file
        script_dir = Path(__file__).parent
        token_file = script_dir / "secrets" / "rp-api-token"
        if token_file.exists():
            token = token_file.read_text().strip()

    if not token:
        err("API token required. Set RP_API_TOKEN, use --token, or --token-file")

    if not args.url:
        err("ReportPortal URL required. Set RP_URL or use --url")

    if not args.project:
        err("Project name required. Set RP_PROJECT or use --project")

    # Create client
    client = ReportPortalClient(args.url, args.project, token)

    # Validate token
    if not client.validate_token():
        err("Invalid token or cannot connect to ReportPortal. Run --help for auth instructions.")

    # Execute command
    if args.command == "list":
        cmd_list(args, client)
    elif args.command == "export":
        cmd_export(args, client)
    elif args.command == "import":
        cmd_import(args, client)
    elif args.command == "copy":
        cmd_copy(args, client)
    elif args.command == "upload":
        cmd_upload(args, client)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
