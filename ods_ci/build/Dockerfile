FROM quay.io/centos/centos:stream9

# Use this build arg to set any default test script arguments
ENV RUN_SCRIPT_ARGS=${RUN_SCRIPT_ARGS}
ENV ROBOT_EXTRA_ARGS=''
ENV SET_ENVIRONMENT=0
ENV RETURN_PW=0
ENV OC_HOST=${OC_HOST}
ENV HOME=/tmp
ENV USE_OCM_IDP=1
ENV RUN_FROM_CONTAINER=1
ENV OCM_TOKEN=${OCM_TOKEN}
ENV OCM_ENV=${OCM_ENV}
ENV SE_BROWSER_PATH=/usr/bin/chromium-browser
ARG OC_VERSION=4.13
ARG OC_CHANNEL=stable


RUN dnf -y update &&\
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm &&\
    dnf install -y jq git unzip chromium chromedriver python3-distro httpd-tools &&\
    dnf clean all &&\
    curl --proto "=https" -L https://github.com/mikefarah/yq/releases/download/v4.34.1/yq_linux_amd64 -o /usr/bin/yq &&\
    chmod +x /usr/bin/yq &&\
    curl --proto "=https" -L https://mirror.openshift.com/pub/openshift-v$(echo $OC_VERSION | cut -d'.' -f 1)/x86_64/clients/ocp/$OC_CHANNEL-$OC_VERSION/openshift-client-linux.tar.gz -o $HOME/oc_client.tar.gz && \
    tar xvf $HOME/oc_client.tar.gz -C /usr/local/bin/ && \
    rm -rf $HOME/oc_client.tar.gz && rm /usr/local/bin/README.md && chmod 755 /usr/local/bin/oc && oc version --client && \
    curl --proto "=https" -L https://github.com/openshift-online/ocm-cli/releases/download/v0.1.62/ocm-linux-amd64 -o $HOME/ocm && \
    mv $HOME/ocm /usr/local/bin/ && chmod 755 /usr/local/bin/ocm && ocm version

RUN mkdir $HOME/ods-ci
# Change the WORKDIR so the run script references any files/folders from the root of the repo
WORKDIR $HOME/ods-ci


COPY ods_ci/tests ods_ci/tests/
COPY ods_ci/tasks ods_ci/tasks/
COPY ods_ci/libs ods_ci/libs/
COPY ods_ci/run_robot_test.sh ods_ci/run_robot_test.sh
COPY ods_ci/build/run.sh  ods_ci/build/run.sh
COPY ods_ci/build/install_idp.sh  ods_ci/build/install_idp.sh
COPY ods_ci/build/clean_idp.sh ods_ci/build/clean_idp.sh
COPY ods_ci/utils/scripts/Sender  ods_ci/utils/scripts/Sender/
COPY ods_ci/utils/scripts/ocm/ocm.py  ods_ci/utils/scripts/ocm/ocm.py
COPY ods_ci/utils/scripts/logger.py  ods_ci/utils/scripts/logger.py
COPY ods_ci/utils/scripts/util.py  ods_ci/utils/scripts/util.py
COPY ods_ci/utils/scripts/SplitSuite.py  ods_ci/utils/scripts/SplitSuite.py
COPY ods_ci/utils/scripts/testconfig/test-variables.yml ods_ci/test-variables.yml.model
COPY ods_ci/test-variables.yml.example ods_ci/test-variables.yml
COPY ods_ci/configs/templates/ldap/ldap.yaml ods_ci/configs/templates/ldap/ldap.yaml
COPY ods_ci/configs/templates/user_config.json ods_ci/configs/templates/user_config.json
COPY ods_ci/configs/resources/oauth_htp_idp.json ods_ci/configs/resources/oauth_htp_idp.json
COPY ods_ci/configs/resources/oauth_ldap_idp.json ods_ci/configs/resources/oauth_ldap_idp.json
COPY ods_ci/configs/templates/ca-rolebinding.yaml ods_ci/configs/templates/ca-rolebinding.yaml
COPY ods_ci/utils/scripts/ocm/templates/create_ldap_idp.jinja ods_ci/utils/scripts/ocm/templates/create_ldap_idp.jinja
RUN  chmod +x ods_ci/build/run.sh &&\
     chmod +x ods_ci/build/clean_idp.sh

COPY pyproject.toml .
COPY poetry.lock .
COPY README.md .
RUN python3 --version
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="${PATH}:$HOME/.local/bin"
RUN poetry install

RUN chgrp -R 0 . && \
    chmod -R g=u .

ENTRYPOINT ["./ods_ci/build/run.sh"]
