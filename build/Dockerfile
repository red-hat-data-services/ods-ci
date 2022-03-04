FROM quay.io/centos/centos:stream8
# FROM registry.access.redhat.com/ubi8/ubi:8.1
# Use this build arg to set any default test script arguments
ENV RUN_SCRIPT_ARGS=${RUN_SCRIPT_ARGS}
ENV ROBOT_EXTRA_ARGS=${ROBOT_EXTRA_ARGS}
ENV HOME /tmp

ARG oc_local_path=build/oc

RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&\
    dnf install -y git python3 unzip chromium chromedriver redhat-lsb-core &&\
    dnf clean all

## Install yq in the image
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.16.2/yq_linux_amd64 -o /usr/bin/yq &&\
    chmod +x /usr/bin/yq

## Install oc in the container
COPY ${oc_local_path} /usr/local/bin/oc
# COPY build/oc /usr/local/bin/oc
# COPY oc /usr/local/bin/oc
RUN chmod 755 /usr/local/bin/oc &&\
         oc version --client

RUN mkdir $HOME/ods-ci
# Change the WORKDIR so the run script references any files/folders from the root of the repo
WORKDIR $HOME/ods-ci

COPY tests tests/
COPY libs libs/
COPY run_robot_test.sh  .
COPY requirements.txt setup.py .
RUN python3 -m venv venv && source venv/bin/activate &&  pip3 install --upgrade pip && venv/bin/pip3 install -r requirements.txt

# Set the group ownership so non-root users can write to /tmp
RUN chgrp -R 0 /tmp && chmod -R g=u /tmp
RUN chown -R 1001 /tmp

USER 1001

CMD if [ -n "${ROBOT_EXTRA_ARGS}" ]; then \
            echo --extra-robot-args "${ROBOT_EXTRA_ARGS}" &&\
	        ./run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS} --extra-robot-args "${ROBOT_EXTRA_ARGS}" ;\
     else \
            echo execute all &&\
            ./run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS};\
     fi
