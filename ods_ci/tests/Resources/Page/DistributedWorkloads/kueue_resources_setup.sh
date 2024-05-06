#!/bin/bash

name=$1
flavor=$2
local_queue_name=$3
namespace=$4
cpu_shared_quota=$5
memory_shared_quota=$6

echo "Applying Cluster Queue"

cat <<EOF | kubectl apply --server-side -f -
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: ClusterQueue
    metadata:
        name: $name
    spec:
      namespaceSelector: {}
      resourceGroups:
      - coveredResources: ["cpu", "memory", "nvidia.com/gpu"]
        flavors:
        - name: $flavor
          resources:
          - name: "cpu"
            nominalQuota: $cpu_shared_quota
          - name: "memory"
            nominalQuota: ${memory_shared_quota}Gi
          - name: "nvidia.com/gpu"
            nominalQuota: 0
EOF
echo "Cluster Queue $name applied!"

echo "Applying Resource flavor"
cat <<EOF | kubectl apply --server-side -f -
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: ResourceFlavor
    metadata:
        name: $flavor
EOF
echo "Resource flavor $flavor applied!"

echo "Applying local queue"

cat <<EOF | kubectl apply --server-side -f -
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: LocalQueue
    metadata:
        namespace: $namespace
        name: $local_queue_name
        annotations:
          "kueue.x-k8s.io/default-queue": "true"
    spec:
      clusterQueue: $name
EOF
echo "Local Queue $local_queue_name applied!"
