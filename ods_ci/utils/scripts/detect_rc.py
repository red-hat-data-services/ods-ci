import argparse
from datetime import datetime
import smartsheet
import re
import semver
import sys


def parse_date(date_string, format):
    date = None
    if format == "ISO":
        try:
            date = datetime.fromisoformat(date_string).date()
        except ValueError as e:
            print(e)
            print(">> [ERROR]The given build date string {date_string} is not compatible with ISO format.")
        except Exception as e:
            print(e)
            print("Something went wrong while converting the build date string {date_string} to datetime.")
    else:
        try:
            date = datetime.strptime(date_string, format).date()
        except ValueError as e:
            print(e)
            print(">>> [ERROR] The given build date string {date_string} is not compatible with given {format} format.")
    return date

def get_code_freeze_date(sheet, build_version):
    xy_ver = ""
    for idx, item in enumerate(semver.VersionInfo.parse(build_version)):
        xy_ver += str(item)
        if idx+1 > 1:
            break
        xy_ver += "."
    print(xy_ver)
    for row in sheet.rows:
        if row.cells[3].value and row.cells[1].value and re.match(xy_ver+r'[\s]+code.?freeze', str(row.cells[1].value).lower()):
            codefreeze = datetime.strptime(row.cells[3].value, '%Y-%m-%dT%H:%M:%S').date()
            return codefreeze

def is_build_rc(sheet, build_version, build_date, build_date_format):
    cf_date = get_code_freeze_date(sheet, build_version)
    print(f"Code freeze for {build_version} is on {cf_date}")
    build_date = parse_date(build_date, build_date_format)
    if build_date > cf_date:
        print(f"The buiild {build_version} is an RC because created after code freeze date {cf_date} ")
        sys.exit(0)
    else:
        print(f"The buiild {build_version} is NOT an RC because created before code freeze date {cf_date} ")
        missing_days = cf_date - build_date
        print(missing_days.days)
        sys.exit(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--smartsheet-token',
        default='',
        required=True,
        help='Token to access Smartshee API',
        dest='sheet_token'
    )
    parser.add_argument(
        '--smartsheet-id',
        default='',
        required=True,
        help='ID of the smartsheet containing RHOAI dates',
        dest='sheet_id'
    )
    parser.add_argument(
        '--build-version',
        default='',
        required=True,
        help='RHOAI version of the target build (e.g., 2.13.0)',
        dest='build_version'
    )
    parser.add_argument(
        '--build-date',
        default='',
        required=True,
        help='Date the build was created',
        dest='build_date'
    )
    parser.add_argument(
        '--date-format',
        default='ISO',
        required=False,
        help='Date format of the build date argument. e.g., %Y-%m-%dT%H:%M:%S',
        dest='build_date_format'
    )
    args = parser.parse_args()

    smartsheet_client = smartsheet.Smartsheet(args.sheet_token)
    sheet = smartsheet_client.Sheets.get_sheet(args.sheet_id)
    is_build_rc(sheet, args.build_version, args.build_date, args.build_date_format)
