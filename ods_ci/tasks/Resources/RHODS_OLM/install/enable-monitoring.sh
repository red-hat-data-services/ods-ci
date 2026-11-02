#!/usr/bin/env bash

set -euo pipefail

command -v oc >/dev/null 2>&1 || {
  echo "oc is required" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || {
  echo "jq is required" >&2
  exit 1
}

patch="$({
  oc get clusterversion version -o json |
    jq -c '
      [
        (.spec.overrides // [])
        | to_entries[]
        | select(
            (
              .value.group == "apps" and
              .value.kind == "Deployment" and
              .value.name == "cluster-monitoring-operator" and
              (.value.namespace // "") == "openshift-monitoring"
            ) or
            (
              .value.group == "config.openshift.io" and
              .value.kind == "ClusterOperator" and
              .value.name == "monitoring" and
              (.value.namespace // "") == ""
            )
          )
        | .key
      ]
      | sort
      | reverse
      | map({op: "remove", path: ("/spec/overrides/" + tostring)})
    '
})"

if [[ "$patch" == "[]" ]]; then
  echo "Monitoring overrides not found; no patch applied."
  exit 0
fi

echo "Applying patch: $patch"
oc patch clusterversion version --type=json -p="$patch"
