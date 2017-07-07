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
BUILD_DOCKERFILE='Dockerfile.worker'
TEMPLATE_DEPLOY=$FOLDER/openshift.worker.deploy.yaml
count=0


function deployOpenshiftObject(){
    app_name=$1
    app_type=$2
    echo "CREATE DEPLOYMENT for $app_name [type=$app_type]"
    oc process -f "$TEMPLATE_DEPLOY" \
        -v APP_NAME=$app_name \
        -v APP_TYPE=$app_type \
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
        buildOpenshiftObject  'bakery-worker'
    elif [[ $OS_DELETE_DEPLOYMENT == "true" ]]; then
        deleteOpenshiftObject 'bakery-worker-blueberry'
        deleteOpenshiftObject 'bakery-worker-caramel'
        deleteOpenshiftObject 'bakery-worker-chocolate'
        if [[ $OS_DELETE_ALL == "true" ]]; then
            buildDeleteOpenshiftObject 'bakery-worker'
        fi
    else
        deployOpenshiftObject 'bakery-worker-blueberry' 'blueberry'
        deployOpenshiftObject 'bakery-worker-caramel' 'caramel'
        deployOpenshiftObject 'bakery-worker-chocolate' 'chocolate'
    fi
    echo "-------------------------------------------------------------------"
    ((count++))

}

triggerOpenshift

wait
exit $?
