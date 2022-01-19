from semver import VersionInfo
from robotlibcore import keyword


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
