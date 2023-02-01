FROM quay.io/centos/centos:stream8

ARG CHROMEDRIVER_VER=90.0.4430.24
ARG ODS_CI_REPO=https://github.com/red-hat-data-services/ods-ci
ARG ODS_CI_REPO_BRANCH=master

ENV HOME /root
WORKDIR /root

RUN dnf install -y bc git python3-pip unzip

RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&\
    echo -e "[google-chrome]\nname=google-chrome\nbaseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.google.com/linux/linux_signing_key.pub" > /etc/yum.repos.d/google-chrome.repo &&\
    dnf -y install "google-chrome-stable" &&\
    dnf clean all

#TODO: Get the google-chrome version so we can download the appropriate chromedriver binary version
RUN curl -o /tmp/chromedriver_linux64.zip -L https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VER}/chromedriver_linux64.zip &&\
    unzip /tmp/chromedriver_linux64.zip &&\
    cp chromedriver /usr/local/bin/chromedriver

RUN git clone --depth=1 --branch ${ODS_CI_REPO_BRANCH} ${ODS_CI_REPO} ods-ci
COPY test-variables.yml ods-ci/

#Change the WORKDIR so the run script references any files/folders from the root of the repo
WORKDIR /root/ods-ci

#TODO: Allow the user to pass cli arguments at run time
CMD ./run_robot_test.sh
