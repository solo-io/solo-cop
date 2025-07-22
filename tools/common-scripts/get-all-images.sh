#!/usr/bin/env bash
# usage: ./get-all-images.sh 2.2.1
# From https://github.com/solo-io/solo-cop/tree/main/tools/airgap-install
VERSION=${1}

JSON_FLAG="-o=json"

echo; echo "For mgt server---"
wget -q "https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-enterprise/gloo-mesh-enterprise-${VERSION}.tgz"
tar zxf gloo-mesh-enterprise-${VERSION}.tgz
find gloo-mesh-enterprise -name "values.yaml" | while read file; do
    cat $file | yq eval $JSON_FLAG | jq -r '.. | .image? | select(. != null) | (if .registry then (if .registry == "docker.io" then "docker.io/library" else .registry end) + "/" else "" end) + .repository + ":" + (.tag | tostring)'
done | sort -u | tee -a .images.out

echo; echo "For agent---"
wget -q https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-agent/gloo-mesh-agent-${VERSION}.tgz
tar zxf gloo-mesh-agent-${VERSION}.tgz
find gloo-mesh-agent -name "values.yaml" | while read file; do
    cat $file | yq eval $JSON_FLAG | jq -r '.. | .image? | select(. != null) | (if .registry then (if .registry == "docker.io" then "docker.io/library" else .registry end) + "/" else "" end) + .repository + ":" + (.tag | tostring)'
done | sort -u | tee .images.out

rm *.tgz
rm -rf gloo-mesh-agent
rm -rf gloo-mesh-enterprise
rm .images.out
