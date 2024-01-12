import argparse
import json
import os
import sys

dir_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(dir_path + "/../")

from logger import log
from util import execute_command

"""
Class for Report portal operations
"""


class ReportPortalOperations:
    def __init__(self, args={}):
        # Initialize instance variables
        self.config_file = args.get("config_file")
        self.payload_dir = args.get("payload_dir")
        self.service_url = args.get("service_url")
        self.output_file = args.get("output_file")
        self.log_path = args.get("log_path")

    def write_output_file(self, file_content):
        """
        Write content to output file.
        Args:
            file_content (str): Content to write to output file.
        """

        output_file = os.path.abspath(os.path.expanduser(self.output_file))
        try:
            if not os.path.exists(os.path.dirname(output_file)):
                os.makedirs(os.path.dirname(output_file))
            with open(output_file, "a") as f:
                log.info("Writing content to %s", output_file)
                f.write(f"{file_content}\n")
        except Exception as e:
            log.error("Unable to write output to file due to Exception: %s", e)

    def upload_result(self):
        """Uploads test results to report portal"""

        cmd = "rp_preproc -c {} -d {} --service {} -l {}".format(
            self.config_file, self.payload_dir, self.service_url, self.log_path
        )
        log.info("CMD: {}".format(cmd))
        rp_output = execute_command(cmd)
        rp_output_json = json.dumps(rp_output)
        self.write_output_file(json.dumps(rp_output_json))


if __name__ == "__main__":
    # Instance for ReportPortalOperations Class
    rp_obj = ReportPortalOperations()

    """Parse CLI arguments"""

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Script to upload results to report portal",
    )

    subparsers = parser.add_subparsers(
        title="Available sub commands", help="sub-command help"
    )

    # Argument parsers for uploading test results to report portal
    upload_result_parser = subparsers.add_parser(
        "upload_result",
        help="Upload result to report portal",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    required_upload_result_parser = upload_result_parser.add_argument_group(
        "required arguments"
    )

    required_upload_result_parser.add_argument(
        "--config-file",
        help="Report portal config json file",
        action="store",
        dest="config_file",
        required=True,
    )
    required_upload_result_parser.add_argument(
        "--payload-dir",
        help="Report portal payload directory",
        action="store",
        dest="payload_dir",
        required=True,
    )
    required_upload_result_parser.add_argument(
        "--service-url",
        help="Report portal Service url",
        action="store",
        dest="service_url",
        required=True,
    )
    required_upload_result_parser.add_argument(
        "--output-file",
        help="Output file to dump report portal output",
        action="store",
        dest="output_file",
        required=True,
    )
    required_upload_result_parser.add_argument(
        "--log-path",
        help="Report portal Log Path",
        action="store",
        dest="log_path",
        required=True,
    )

    upload_result_parser.set_defaults(func=rp_obj.upload_result)

    args = parser.parse_args(namespace=rp_obj)
    if hasattr(args, "func"):
        args.func()
