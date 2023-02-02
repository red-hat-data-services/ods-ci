#!/bin/bash
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf install -y python3-devel git redhat-lsb jq podman dnf-plugins-core java-1.8.0-openjdk unzip chromium chromedriver httpd-tools gcc
sudo pip3 install --ignore-installed pyyaml
git config --global http.sslVerify "false"
