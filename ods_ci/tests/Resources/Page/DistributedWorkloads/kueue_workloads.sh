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
      annotations:
        kueue.x-k8s.io/job-min-parallelism: "1"
    spec:
      parallelism: 2
      completions: 2
      suspend: true
      template:
        spec:
          containers:
          - name: test-job
            image: quay.io/biocontainers/perl:5.32
            command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(12000)"]
            resources:
              requests:
                cpu: $cpu_requested
                memory: ${memory_requested}Mi
          restartPolicy: Never
      backoffLimit: 3
EOF
echo "kueue Job submitted successfully"
