from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from robotlibcore import keyword
from semver import VersionInfo

from utils.scripts.ocm.ocm import OpenshiftClusterManager


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
            self.BuiltIn.fail(
                "Something got wrong while installing RHOAM. Check the logs"
            )

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
        cluster_name = ocm_client.ocm_describe(filter="--json | jq -r '.name'")
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
    def update_notification_email_address(
        self, cluster_name, email_address, addon_name="managed-odh"
    ):
        """Update notification email for add-ons using OCM"""
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        status = ocm_client.update_notification_email_address(
            addon_name, email_address, exit_on_failure=False
        )
        if not status:
            self.BuiltIn.fail(
                "Unable to update notification email,"
                " Check if operator is installed via Add-on"
            )

    @keyword
    def convert_to_hours_and_minutes(self, seconds):
        """Converts seconds in hours and minutes"""
        m, s = divmod(int(seconds), 60)
        h, m = divmod(m, 60)
        return h, m

    @keyword
    def install_isv_by_name(self, operator_name, channel, source="certified-operators"):
        ocm_client = OpenshiftClusterManager()
        ocm_client.install_openshift_isv(
            operator_name, channel, source, exit_on_failure=False
        )
        if operator_name == "ovms":
            status = ocm_client.wait_for_isv_installation_to_complete("openvino")
        else:
            status = ocm_client.wait_for_isv_installation_to_complete(operator_name)
        if not status:
            self.BuiltIn.fail(
                "Unable to install the {} isv, Check if ISV subscription is "
                "created{}".format(operator_name, status)
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
            else:
                if saving == True:
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
            self.BuiltIn.fail(
                "Something got wrong while installing Managed Starburst. Check the logs"
            )

    @keyword
    def uninstall_managed_starburst_using_addon_flow(self, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        ocm_client.uninstall_managed_starburst_addon(exit_on_failure=False)

    @keyword
    def inference_comparison(self, expected, received, threshold=0.00001):
        try:
            import ast
            import decimal
            import numbers

            # Cast from string to python type
            expected=ast.literal_eval(expected)
            received=ast.literal_eval(received)

            failures=[]
            
            def _inference_object_comparison(expected, received, threshold):
                if isinstance(expected, dict):
                    # if current element is a dict, compare the keys and then each value
                    if not expected.keys()==received.keys(): failures.append([expected.keys(),received.keys()])
                    for k in expected.keys():
                        _inference_object_comparison(expected[k], received[k], threshold)
                elif isinstance(expected, list):
                    # if current element is a list, compare each value 1 by 1
                    for id, _ in enumerate(expected): _inference_object_comparison(expected[id],received[id], threshold)				
                elif isinstance(expected, numbers.Number):
                    # if current element is a number, compare each value with a rounding threshold
                    if not expected - received <= threshold:
                        # Get number of decimal places in the threshold number
                        d=abs(decimal.Decimal(str(threshold)).as_tuple().exponent)
                        # format the difference between expected and received with the same number of decimal
                        # places as the current threshold
                        failures.append([expected,received,"{0:.{1}f}".format(expected-received,d)])
                else:
                    # else compare values are equal
                    if not expected==received: failures.append([expected,received])
                    
            _inference_object_comparison(expected, received, threshold)
            if len(failures)>0:
                return False, failures
            return True, failures
        except Exception as e:
            return False, [['exception thrown during comparison'], ['expected', expected], ['received', received], ['threshold', threshold], ['exception', e]]
