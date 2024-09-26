#!/bin/bash

local_queue_name=$1
namespace=$2
cpu_requested=$3
memory_requested=$4
job_name=$5

echo "Submitting kueue batch workloads"

cat <<EOF | kubectl apply --server-side -f -
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: $job_name
      namespace: $namespace
      labels:
        kueue.x-k8s.io/queue-name: $local_queue_name
    spec:
      suspend: true
      template:
        spec:
          containers:
          - name: test-job
            image: quay.io/biocontainers/perl@sha256:1889c73a71acbe17b2857a0ff437fd919a5bc69f1d8299be85d40316b91a4e01
            command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(12000)"]
            resources:
              requests:
                cpu: $cpu_requested
                memory: ${memory_requested}Mi
          restartPolicy: Never
      backoffLimit: 3
EOF
echo "kueue Job submitted successfully"
