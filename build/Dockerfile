FROM registry.access.redhat.com/ubi8/ubi:8.1

# Use this build arg to set any default test script arguments
ENV RUN_SCRIPT_ARGS=${RUN_SCRIPT_ARGS}
ENV ROBOT_EXTRA_ARGS=${ROBOT_EXTRA_ARGS}

ENV HOME /tmp

RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&\
    dnf install -y git python3 unzip chromium chromedriver &&\
    dnf clean all

RUN mkdir $HOME/ods-ci
# Change the WORKDIR so the run script references any files/folders from the root of the repo
WORKDIR $HOME/ods-ci

COPY tests tests/
COPY requirements.txt run_robot_test.sh setup.py .
RUN python3 -m venv venv && source venv/bin/activate && venv/bin/pip3 install -r requirements.txt

# Set the group ownership so non-root users can write to /tmp
RUN chgrp -R 0 /tmp && chmod -R g=u /tmp

USER 1001

CMD if [ -n "${RUN_SCRIPT_ARGS}" ]; then \
	        ./run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS} --extra-robot-args "'${ROBOT_EXTRA_ARGS}'" ;\
     else \
            ./run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS};\
     fi

