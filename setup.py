# -*- coding: utf-8 -*-
try:
    from setuptools import find_packages, setup
except ImportError:
    from ez_setup import use_setuptools

    use_setuptools()
    from setuptools import find_packages, setup

setup(
    name="ods-ci",
    version="0.1",
    description="Red Hat Open Data Science QE Tier Tests",
    author="ODS CI",
    author_email="ods-ci@redhat.com",
    install_requires=[
        "reportportal-client",
        "robotframework>=5,<6",
        "robotframework-debuglibrary>=2.0.0",
        "robotframework-requests",
        "robotframework-seleniumlibrary",
        "robotframework-jupyterlibrary>=0.3.1",
        "robotframework-openshift==1.0.0",
        "ipython",
        "pytest",
        "pytest-logger",
        "pyyaml",
        "pygments",
        "requests",
        "robotframework-requests",
        "escapism",
        "semver>=2,<3",
        "rpaframework>=12",
        "yq",
        "pexpect",
        "python-openstackclient",
    ],
    zip_safe=True,
    include_package_data=True,
    packages=find_packages(exclude=["ez_setup"]),
)
