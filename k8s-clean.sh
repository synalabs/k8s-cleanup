#!/bin/bash

# DAYS defaults to 7
max=$DAYS

# Get rs, filter by days, filter by empty rs and select rs older than $max days
emptyReplicaSets=$(kubectl get rs --all-namespaces | \
  grep -oE '^[a-zA-Z0-9-]+\s+[a-zA-Z0-9-]+(\s+[0-9]+){4}d' | sed 's/d$//g' | \
  grep -E '(0\s+){3}' | \
  awk -v max=$max '$6 > max {print $1 "|" $2}')

# Loop through empty replica sets and delete them
for rs in $emptyReplicaSets; do
  IFS='|' read namespace replicaSet <<< "$rs";
  kubectl -n $namespace delete rs $replicaSet;
  sleep 0.25
done

# Get finished jobs older than 1h
finishedJobs=$(kubectl get jobs --all-namespaces | awk 'IF $3 == "1/1" && $5 ~ /h|d/ {print $1 "|" $2}')

# Loop through jobs and delete them
for job in $finishedJobs; do
  IFS='|' read namespace oldJob <<< "$job";
  kubectl -n $namespace delete job $oldJob;
  sleep 0.25
done

# Get unrecycled unused pods older than 1h
unusedPods=$(kubectl get pods --all-namespaces | grep -E 'Completed|Evicted' | \
  awk 'IF $6 ~ /h|d/ {print $1 "|" $2}')

# Loop through unused pods and delete them
for pod in $unusedPods; do
  IFS='|' read namespace unusedPod <<< "$pod";
  kubectl -n $namespace delete pod $unusedPod;
  sleep 0.25
done
