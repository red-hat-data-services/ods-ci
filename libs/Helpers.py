import string
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
        version=tuple(version.translate(str.maketrans('', '', string.punctuation)))
        target=tuple(target.translate(str.maketrans('', '', string.punctuation)))
        return version>=target