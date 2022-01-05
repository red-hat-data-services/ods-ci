FROM centos:centos8

# Use this build arg to set any default test script arguments
ARG RUN_SCRIPT_ARGS=
ENV RUN_SCRIPT_ARGS=${RUN_SCRIPT_ARGS}

ENV HOME /tmp

RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&\
    dnf install -y git python3 unzip chromium chromedriver redhat-lsb-core &&\
    dnf clean all

## Install yq in the image
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.16.2/yq_linux_amd64 -o /usr/bin/yq &&\
    chmod +x /usr/bin/yq

## Install oc in the container
COPY oc /usr/local/bin/oc
RUN chmod 755 /usr/local/bin/oc &&\
         oc version --client &&\
         oc config set-context loadtest

RUN mkdir $HOME/ods-ci
# Change the WORKDIR so the run script references any files/folders from the root of the repo
WORKDIR $HOME/ods-ci

COPY tests tests/
COPY libs libs/

COPY requirements.txt run_robot_test.sh setup.py .
RUN python3 -m venv venv && source venv/bin/activate && venv/bin/pip3 install -r requirements.txt

# Set the group ownership so non-root users can write to /tmp
RUN chgrp -R 0 /tmp && chmod -R g=u /tmp
RUN chown -R 1001 /tmp

USER 1001

CMD ./run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS}
