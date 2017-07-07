#!/usr/bin/env bash
cd $(dirname `which $0`)
FOLDER=$(pwd)

echo "ARGS: $1"
if [[ $1 = delete-all ]]; then
    OS_DELETE_ALL=true
fi
if [[ $1 =~ delete ]]; then
    OS_DELETE_DEPLOYMENT=true
fi
if [[ $1 =~ build ]]; then
    OS_BUILD_ONLY=true
fi

TEMPLATE_BUILD=$FOLDER/openshift.bakery.generic.build.yaml
TEMPLATE_DEPLOY=$FOLDER/openshift.web.deploy.yaml

BUILD_DOCKERFILE='Dockerfile.web'
PROBE_PATH='/bakery'
SER_NAME='bakery-web-server'

count=0


function deployOpenshiftObject(){
    app_name=$1
    echo "CREATE DEPLOYMENT for $app_name"
    oc process -f "$TEMPLATE_DEPLOY" \
        -v APP_NAME=$app_name \
        -v IMAGE_STREAM=$app_name \
        -v PROBE_PATH=$PROBE_PATH \
        | oc apply -f -
    echo ".... " && sleep 2
    oc get all -l application=$app_name
    echo "-------------------------------------------------------------------"

}

function deleteOpenshiftObject(){
    app_name=$1
    echo "DELETE Config for $app_name"
    oc delete all -l "application=$app_name"  --grace-period=5
    echo "-------------------------------------------------------------------"

}

function buildOpenshiftObject(){
    app_name=$1
    echo "Trigger Build for $app_name"
    oc process -f "$TEMPLATE_BUILD" \
        -v APP_NAME=$app_name \
        -v SOURCE_DOCKERFILE=$BUILD_DOCKERFILE \
        | oc apply -f -
    oc start-build "$app_name" --follow --wait
    exit $?
}
function buildDeleteOpenshiftObject(){
    app_name=$1
    echo "Trigger DELETE Build for $app_name"
    oc process -f "$TEMPLATE_BUILD" \
        -v APP_NAME=$app_name \
        -v SOURCE_DOCKERFILE=$BUILD_DOCKERFILE \
        | oc delete -f -
    echo "-------------------------------------------------------------------"
}


function triggerOpenshift() {
    echo "--------------------- APP $count ---------------------------------------"
    if [[ $OS_BUILD_ONLY == "true" ]]; then
        buildOpenshiftObject  $SER_NAME
    elif [[ $OS_DELETE_DEPLOYMENT == "true" ]]; then
        deleteOpenshiftObject $SER_NAME
        if [[ $OS_DELETE_ALL == "true" ]]; then
            buildDeleteOpenshiftObject $SER_NAME
        fi
    else
        deployOpenshiftObject $SER_NAME
    fi
    echo "-------------------------------------------------------------------"
    ((count++))

}

triggerOpenshift

wait
exit $?
