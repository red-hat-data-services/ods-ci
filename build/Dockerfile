FROM quay.io/centos/centos:stream8

# Use this build arg to set any default test script arguments
ENV RUN_SCRIPT_ARGS=${RUN_SCRIPT_ARGS}
ENV ROBOT_EXTRA_ARGS=''
ENV SET_ENVIRONMENT=0
ENV OC_HOST=${OC_HOST}
ENV HOME=/tmp
ENV OCM_TOKEN=${OCM_TOKEN}
ENV OCM_ENV=${OCM_ENV}
ARG OC_VERSION=4.10
ARG OC_CHANNEL=stable


RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&\
    dnf install -y python38 jq git unzip chromium chromedriver redhat-lsb-core &&\
    dnf clean all

## Install yq in the image
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_amd64 -o /usr/bin/yq &&\
    chmod +x /usr/bin/yq

## Install oc and ocm in the container
RUN curl -L https://mirror.openshift.com/pub/openshift-v$(echo $OC_VERSION | cut -d'.' -f 1)/x86_64/clients/ocp/$OC_CHANNEL-$OC_VERSION/openshift-client-linux.tar.gz -o $HOME/oc_client.tar.gz && \
    tar xvf $HOME/oc_client.tar.gz -C /usr/local/bin/ && \
    rm -rf $HOME/oc_client.tar.gz && rm /usr/local/bin/README.md && chmod 755 /usr/local/bin/oc && oc version --client && \
    curl -L https://github.com/openshift-online/ocm-cli/releases/download/v0.1.62/ocm-linux-amd64 -o $HOME/ocm && \
    mv $HOME/ocm /usr/local/bin/ && chmod 755 /usr/local/bin/ocm && ocm version


RUN mkdir $HOME/ods-ci
# Change the WORKDIR so the run script references any files/folders from the root of the repo
WORKDIR $HOME/ods-ci

# create non-root user
RUN groupadd --gid 1001 ods-ci-users
RUN useradd -r -u 1001 -g ods-ci-users ods-ci-runner

COPY tests tests/
COPY tasks tasks/
COPY libs libs/
COPY run_robot_test.sh  .
COPY build/run.sh  .
COPY build/install_idp.sh  .
COPY utils/scripts/Sender  utils/scripts/Sender/
COPY utils/scripts/ocm/ocm.py  utils/scripts/ocm/ocm.py
COPY utils/scripts/logger.py  utils/scripts/logger.py
COPY utils/scripts/util.py  utils/scripts/util.py
COPY utils/scripts/SplitSuite.py  utils/scripts/SplitSuite.py
COPY utils/scripts/testconfig/test-variables.yml test-variables.yml.model
COPY test-variables.yml.example test-variables.yml
COPY configs/templates/ldap/ldap.yaml configs/templates/ldap/ldap.yaml
COPY utils/scripts/ocm/templates/create_ldap_idp.jinja utils/scripts/ocm/templates/create_ldap_idp.jinja
RUN  chmod +x run.sh
COPY requirements.txt setup.py .
RUN  python3 --version
RUN  python3 -m venv venv && source venv/bin/activate &&  pip3 install --upgrade pip && venv/bin/pip3 install -r requirements.txt

# set the non-root user
RUN chgrp -R 1001 $HOME/ods-ci && chown -R 1001 $HOME/ods-ci && chmod -R 744 $HOME/ods-ci
USER 1001

ENTRYPOINT ["./run.sh"]
