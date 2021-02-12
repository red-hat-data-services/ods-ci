# ODS-CI

ODH CI is a framework to test Red Hat Open Data Science features and functionality
using QE tiered testing.

# Requirements
  Fedora or CentOS that supports chrome drivers
  `lsb_release` binary
    - Provided by redhat-lsb-core in RPM based


# Quick Start
  export the URL, KUBEADMIN and KUBEPWD like below and run the basic robot tests

  Example:
  export CONSOLE_URL=https://console-openshift-console.apps.modh-qe.dev.datahub.redhat.com/
  export KUBEADMIN=kubeadmin
  export KUBEPWD=KUBEPWD

  run the script
  sh run_robot_test.sh



## License

This project is open sourced under MIT License.
