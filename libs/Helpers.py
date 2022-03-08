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
        ocm_client.install_rhoam_addon()

    @keyword
    def uninstall_rhoam_addon(self, cluster_name):
        ocm_client = OpenshiftClusterManager()
        ocm_client.cluster_name = cluster_name
        ocm_client.uninstall_rhoam_addon()

    @keyword
    def get_cluster_name(self, cluster_identifier):
        ocm_client = OpenshiftClusterManager()
        # to manipulate ocm_describe on line 45
        ocm_client.cluster_name = cluster_identifier
        cluster_name = ocm_client.ocm_describe(filter="--json | jq -r '.name'")
        cluster_name = cluster_name.strip("\n")
        if cluster_name is None:
            logger.error("Unable to retrieve cluster name for "
                         "cluster ID {}. EXITING".format(cluster_identifier))
        return cluster_name

