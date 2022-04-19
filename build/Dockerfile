FROM quay.io/centos/centos:stream8
# FROM registry.access.redhat.com/ubi8/ubi:8.1
# Use this build arg to set any default test script arguments
ENV RUN_SCRIPT_ARGS=${RUN_SCRIPT_ARGS}
ENV ROBOT_EXTRA_ARGS=${ROBOT_EXTRA_ARGS}
ENV HOME /tmp
ARG OC_VERSION=4.10
ARG OC_CHANNEL=stable


RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&\
    dnf install -y jq git python3 unzip chromium chromedriver redhat-lsb-core &&\
    dnf clean all

## Install yq in the image
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.16.2/yq_linux_amd64 -o /usr/bin/yq &&\
    chmod +x /usr/bin/yq

## Install oc in the container
RUN curl -L https://mirror.openshift.com/pub/openshift-v$(echo $OC_VERSION | cut -d'.' -f 1)/x86_64/clients/ocp/$OC_CHANNEL-$OC_VERSION/openshift-client-linux.tar.gz -o $HOME/oc_client.tar.gz && \
    tar xvf $HOME/oc_client.tar.gz -C /usr/local/bin/ && \
    rm -rf $HOME/oc_client.tar.gz && rm /usr/local/bin/README.md

RUN chmod 755 /usr/local/bin/oc &&\
         oc version --client

RUN mkdir $HOME/ods-ci
# Change the WORKDIR so the run script references any files/folders from the root of the repo
WORKDIR $HOME/ods-ci

COPY tests tests/
COPY libs libs/
COPY run_robot_test.sh  .
COPY build/run.sh  .
RUN  chmod +x run.sh
COPY requirements.txt setup.py .
RUN  python3 -m venv venv && source venv/bin/activate &&  pip3 install --upgrade pip && venv/bin/pip3 install -r requirements.txt

ENTRYPOINT ["./run.sh"]
