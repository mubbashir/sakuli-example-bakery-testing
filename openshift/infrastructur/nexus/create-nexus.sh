#!/usr/bin/env bash

cd $(dirname `which $0`)
FOLDER=$(pwd)
echo "ARGS: $1"

echo "============= USE PROJECT NEXUS =================="
oc project nexus
if [[ $1 =~ delete ]]; then
    echo "============= DELETE NEXUS =================="
    oc process -f $FOLDER/nexus2-persistent-template.yaml | oc delete -f -
    exit $?
fi

echo "============= CREATE NEXUS =================="
oc process -f $FOLDER/nexus2-persistent-template.yaml | oc apply -f -
#    && oc process -f $FOLDER/nexus.yml | oc apply -f -
