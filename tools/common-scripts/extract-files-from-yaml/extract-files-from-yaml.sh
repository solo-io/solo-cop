#!/bin/bash
FILE_NAME=$1
yq '.items[]? | select(. != null)' "${FILE_NAME}" | \
  awk 'NR==1{print $0; next} /^apiVersion:/{print "---"} {print $0}' | \
  yq 'del(.metadata.annotations["kubectl.kubernetes.io/last-applied-configuration"],.metadata.creationTimestamp,.metadata.generation,.metadata.managedFields,.metadata.resourceVersion,.metadata.selfLink,.metadata.uid,.status)' | \
  yq -s '.kind + "_" + (.metadata.name|sub("\.","_"))' --no-doc

FILE_NAME_WITHOUT_EXTENSION=$(ls "${FILE_NAME}" | cut -f1 -d.)

for TYPE in $(ls *_*.yml | cut -f1 -d "_" | uniq | grep -v "${FILE_NAME}" | grep -v "\.sh" | grep -v "\.yaml")
do
    mkdir -p "extracted-files-from-${FILE_NAME_WITHOUT_EXTENSION}"/"${TYPE}"
    mv ./"${TYPE}"*.yml ./extracted-files-from-"${FILE_NAME_WITHOUT_EXTENSION}"/"${TYPE}"
done
