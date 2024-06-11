import ast
import decimal
import numbers
import random
import re
from pathlib import Path

import requests
from fuzzywuzzy import fuzz
from robot.libraries.BuiltIn import BuiltIn
from robotlibcore import keyword
from semver import VersionInfo

from ods_ci.utils.scripts.ocm.ocm import OpenshiftClusterManager


class Helpers:
    """Custom keywords written in Python"""

    def __init__(self):
        self.BuiltIn = BuiltIn()

    @keyword
    def text_to_list(self, text):
        rows = text.split("\n")
        print(rows)
        return rows

    @keyword
    def gt(self, version, target):
        """Returns True if the version > target
        and otherwise False including if an exception is thrown"""
        try:
            version = VersionInfo.parse(version)
            target = VersionInfo.parse(target)
            return version > target
        except ValueError:
            # Returning False on exception as a workaround for when an
            # null (or invalid) semver version is passed
            return False

    @keyword
    def gte(self, version, target):
        """Returns True if the SemVer version >= target
        and otherwise False including if an exception is thrown"""
        try:
            version = VersionInfo.parse(version)
            target = VersionInfo.parse(target)
            return version >= target
        except ValueError:
            # Returning False on exception as a workaround for when an
            #   null (or invalid) semver version is passed
            return False

    @keyword
    def install_rhoam_addon(self, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        result = ocm_client.install_rhoam_addon(exit_on_failure=False)
        if not result:
            self.BuiltIn.fail("Something got wrong while installing RHOAM. Check the logs")

    @keyword
    def uninstall_rhoam_using_addon_flow(self, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        ocm_client.uninstall_rhoam_addon(exit_on_failure=False)

    @keyword
    def get_cluster_name(self, cluster_identifier):
        ocm_client = OpenshiftClusterManager()
        # to manipulate ocm_describe on line 45
        ocm_client.cluster_name = cluster_identifier
        cluster_name = ocm_client.ocm_describe(jq_filter="--json | jq -r '.name'")
        cluster_name = cluster_name.strip("\n")
        return cluster_name

    @keyword
    def is_rhods_addon_installed(self, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        install_flag = ocm_client.is_addon_installed(addon_name="managed-odh")
        return install_flag

    @keyword
    def uninstall_rhods_using_addon(self, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        ocm_client.uninstall_rhods()

    @keyword
    def update_notification_email_address(self, cluster_name, email_address, addon_name="managed-odh"):
        """Update notification email for add-ons using OCM"""
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        status = ocm_client.update_notification_email_address(addon_name, email_address, exit_on_failure=False)
        if not status:
            self.BuiltIn.fail("Unable to update notification email, Check if operator is installed via Add-on")

    @keyword
    def convert_to_hours_and_minutes(self, seconds):
        """Converts seconds in hours and minutes"""
        m, _ = divmod(int(seconds), 60)
        h, m = divmod(m, 60)
        return h, m

    @keyword
    def install_isv_by_name(self, operator_name, channel, source="certified-operators"):
        ocm_client = OpenshiftClusterManager()
        ocm_client.install_openshift_isv(operator_name, channel, source, exit_on_failure=False)
        if operator_name == "ovms":
            status = ocm_client.wait_for_isv_installation_to_complete("openvino")
        else:
            status = ocm_client.wait_for_isv_installation_to_complete(operator_name)
        if not status:
            self.BuiltIn.fail(
                "Unable to install the {} isv, Check if ISV subscription is created{}".format(operator_name, status)
            )

    @keyword
    def parse_file_for_tolerations(self, filename):
        tolerations = []
        with open(filename, "r") as f:
            content = f.readlines()
        saving = False
        for line in content:
            if line.startswith("Tolerations:"):
                saving = True
                tolerations.append(line.split(": ")[1].strip())
                print(line)
                print(tolerations)
            elif line.startswith("Events:"):
                break
            elif saving is True:
                tolerations.append(line.strip())
                print(line)
                print(tolerations)
            else:
                continue
        return tolerations

    @keyword
    def install_managed_starburst_addon(self, email_address, license, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        ocm_client.notification_email = email_address
        license_escaped = license.replace('"', '\\"')
        result = ocm_client.install_managed_starburst_addon(license=license_escaped, exit_on_failure=False)
        if not result:
            self.BuiltIn.fail("Something got wrong while installing Managed Starburst. Check the logs")

    @keyword
    def uninstall_managed_starburst_using_addon_flow(self, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        ocm_client.uninstall_managed_starburst_addon(exit_on_failure=False)

    @keyword
    def inference_comparison(self, expected, received, threshold=0.00001):
        try:
            model_name = re.compile(r"^[\S]+(__isvc-)?[\w\d]+$")

            # Cast from string to python type
            expected = ast.literal_eval(expected)
            received = ast.literal_eval(received)

            failures = []

            def _inference_object_comparison(expected, received, threshold):
                if isinstance(expected, dict):
                    # if current element is a dict, compare the keys and then each value
                    if not expected.keys() == received.keys():
                        failures.append([expected.keys(), received.keys()])
                    for k in expected.keys():
                        _inference_object_comparison(expected[k], received[k], threshold)
                elif isinstance(expected, list):
                    # if current element is a list, compare each value 1 by 1
                    for id, _ in enumerate(expected):
                        _inference_object_comparison(expected[id], received[id], threshold)
                elif isinstance(expected, numbers.Number):
                    # if current element is a number, compare each value with a rounding threshold
                    if not expected - received <= threshold:
                        # Get number of decimal places in the threshold number
                        d = abs(decimal.Decimal(str(threshold)).as_tuple().exponent)
                        # format the difference between expected and received with the same number of decimal
                        # places as the current threshold
                        failures.append(
                            [
                                expected,
                                received,
                                "{0:.{1}f}".format(expected - received, d),
                            ]
                        )
                else:
                    # if element is model name, don't care about ID
                    result_ex = model_name.match(expected)
                    result_rec = model_name.match(received)
                    if result_ex is not None and result_rec is not None:
                        if expected.split("__")[0] != received.split("__")[0]:
                            failures.append([expected, received])
                    # else compare values are equal
                    elif not expected == received:
                        failures.append([expected, received])

            _inference_object_comparison(expected, received, threshold)
            if len(failures) > 0:
                return False, failures
            return True, failures
        except Exception as e:
            return False, [
                ["exception thrown during comparison"],
                ["expected", expected],
                ["received", received],
                ["threshold", threshold],
                ["exception", e],
            ]

    @keyword
    def send_random_inference_request(
        self,
        endpoint,
        name="image",
        value_range=[0, 255],
        shape={"B": 1, "C": 3, "H": 512, "W": 512},
        no_requests=100,
    ):
        for _ in range(no_requests):
            data_img = [
                random.randrange(value_range[0], value_range[1]) for _ in range(shape["C"] * shape["H"] * shape["W"])
            ]

            headers = {
                "Content-Type": "application/x-www-form-urlencoded",
            }

            data = (
                '{ "model_name": "vehicle-detection-0202", "inputs": [{ "name": "'
                + str(name)
                + '", "shape": '
                + str(list(shape.values()))
                + ', "datatype": "FP32", "data": '
                + str(data_img)
                + " }]}"
            )

            # This file only exists when running on self-managed clusters
            ca_bundle = Path("openshift_ca.crt")
            knative_ca_bundle = Path("openshift_ca_istio_knative.crt")
            if ca_bundle.is_file():
                response = requests.post(
                    endpoint,
                    headers=headers,
                    data=data,
                    verify="openshift_ca.crt",
                )
            elif knative_ca_bundle.is_file():
                response = requests.post(
                    endpoint,
                    headers=headers,
                    data=data,
                    verify="openshift_ca_istio_knative.crt",
                )
            else:
                response = requests.post(endpoint, headers=headers, data=data)
        return response.status_code, response.text  # pyright: ignore [reportPossiblyUnboundVariable]

    @keyword
    def process_resource_list(self, filename_in, filename_out=None):
        r"""
        Tries to remove pseudorandom substring from openshift resource names using a regex.
        This portion of the regex: -\b(?:[a-z]+\d|\d+[a-z])[a-z0-9]*\b tries to find an
        alphanumeric string of any length preceded by a `-`, while the second part of the regex
        i.e. -\b[a-z]{5}$\b, tries to find substrings of length 5 with only alphabetic characters
        at the end of the string, or with only numbers, preceded by a `-`.
        This has the possibility of removing valid substrings of length 5 from a resource name
        (i.e. token) if they appear at the end of the string, however assuming the reference
        resource list as well as the runtime list are both processed this way, this should
        not cause an issue.
        """
        regex = re.compile(r"-\b(?:[a-z]+\d|\d+[a-z])[a-z0-9]*\b|-\b[a-z0-9]{5}$\b")
        out = []
        with open(filename_in, "r") as f:
            for line in f:
                spaces = line.count(" ")
                resource_name = line.split()[1]
                resource_name = regex.sub(repl="", string=resource_name)
                out.append(line.split()[0] + " " * spaces + resource_name + "\n")
        if filename_out is None:
            filename_out = filename_in.split(".")[0] + "_processed.txt"
        with open(filename_out, "w") as outfile:
            outfile.write("".join(str(l) for l in out))

    @keyword
    def escape_forward_slashes(self, string_to_escape):
        return string_to_escape.replace("/", r"\/")

    @keyword
    def is_string_empty(self, string):
        """
        Check if a given string (including multi-line string) is empty.
        Robot Framework doesn't properly handle multi-line strings and throws
            Evaluating expression '"..." == ""' failed:
            SyntaxError: EOL while scanning string literal (<string>, line 1)
        """
        return string is None or string == ""

    @keyword
    def multiline_to_oneline_string(self, multiline_string, delimeter=" "):
        """
        Converts a mutliline string into a oneline string with a provided delimeter.
        Robot Framework doesn't properly handle multi-line strings and throws
            Evaluating expression '"...".replace('', '\n')' failed:
            SyntaxError: unterminated string literal (detected at line 1) (<string>, line 1)
        """
        return multiline_string.replace("\n", delimeter)

    @keyword
    def get_strings_matching_ratio(self, string1, string2):
        """
        Calculate simple string matching ratio based on Levenshtein distance
        """
        return fuzz.ratio(string1, string2)

    @keyword
    def get_vllm_metrics_and_values(self, endpoint):
        """
        Fetch exposed metrics and their current values from a deployed vllm endpoint
        """
        r = requests.get(endpoint, verify=False)
        regex = re.compile(r"^vllm:")
        out = []
        for line in r.text.split("\n"):
            if regex.match(line):
                if 'le="+Inf"' in line:
                    # TODO: this parameter breaks the query via API although it works fine in the openshift metrics UI
                    # need to figure out a way to fix it.
                    # le="+Inf" is converted to le=%22+Inf%22, which makes it return an empty response
                    # manually sending the request using le%3D\"%2BInf%22 instead works fine
                    # doing the replace here doesn't work because of \", which breaks the URL entirely somehow
                    # line = line.replace('le="+Inf"', 'le%3D\"%2BInf')
                    continue
                out.append(line.split(" "))
        return out
