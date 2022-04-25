from semver import VersionInfo
from robotlibcore import keyword
from utils.scripts.ocm.ocm import OpenshiftClusterManager
from robot.api import logger

class Helpers:
    """Custom keywords written in Python"""
    @keyword
    def text_to_list(self, text):
        rows = text.split('\n')
        print(rows)
        return rows

    @keyword
    def gte(self, version, target):
        """ Returns True if the SemVer version >= target
            and otherwise False including if an exception is thrown """
        try:
            version=VersionInfo.parse(version)
            target=VersionInfo.parse(target)
            #version=tuple(version.translate(str.maketrans('', '', string.punctuation)))
            #target=tuple(target.translate(str.maketrans('', '', string.punctuation)))
            return version>=target
        except ValueError:
            # Returning False on exception as a workaround for when an null (or invalid) semver version is passed
            return False

    @keyword
    def install_rhoam_addon(self, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        ocm_client.install_rhoam_addon(exit_on_failure=False)

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
        install_flag= ocm_client.is_addon_installed(addon_name="managed-odh")
        return install_flag

    @keyword
    def uninstall_rhods_using_addon(self, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        ocm_client.uninstall_rhods()

    @keyword
    def update_notification_email_address(self, cluster_name, email_address, addon_name='managed-odh'):
        """Update notification email for add-ons using OCM"""
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        ocm_client.update_notification_email_address(addon_name, email_address)
