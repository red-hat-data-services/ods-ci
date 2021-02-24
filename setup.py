# -*- coding: utf-8 -*-
try:
    from setuptools import setup, find_packages
except ImportError:
    from ez_setup import use_setuptools

    use_setuptools()
    from setuptools import setup, find_packages

setup(
    name="ods-ci",
    version="0.1",
    description="Red Hat Open Data Science QE Tier Tests",
    author="ODS CI",
    author_email="ods-ci@redhat.com",
    install_requires=[
        "reportportal-client",
        "robotframework",
        "robotframework-debuglibrary",
        "robotframework-seleniumlibrary",
        "pytest",
        "pytest-logger",
        "pyyaml",
        "requests",
    ],
    zip_safe=True,
    include_package_data=True,
    packages=find_packages(exclude=["ez_setup"]),
)

