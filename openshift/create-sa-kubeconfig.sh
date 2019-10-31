#!/usr/bin/env bash
#
# create kubeconfig file for codefresh:admin service account file 
#
# usage: 
# ./create-sa-kubeconfig [kubectl params] saname
#

usage() {
  echo "
Create kubeconfig file from service account. Outputs to ./<namespace>-<service-account-name>-kubeconfig (if no --output specified)
Usage:
  ./create-sa-kubeconfig [options] service-account-name

Options:  [-n|--namespace <namespace>] [--kubeconfig <kubeconfig-file> ] [--context <context-name>] [-o|output <file-name>]
"
  
}

DIR=$(dirname $BASH_SOURCE)

GETOPT=$(getopt -o hn:o: --long help,namespace:,project:,kubeconfig:,context:,output: -- "$@") 
if [[ $? != 0 ]]; then
  usage
  exit 1
fi
eval set -- "$GETOPT"

#echo GETOPS=$GETOPT
#echo $@

while true ; do
    case "$1" in
        -h|--help)
           usage
           exit
           ;;
        -n|--namespace|--project)
           KUBECTL_OPTS+=" --namespace=$2"
           shift 2
           ;;
        --context)
           KUBECTL_OPTS+=" --context=$2"
           shift 2
           ;;
        --kubeconfig)
           KUBECTL_OPTS+=" --kubeconfig=$2"
           shift 2
           ;;
        -o|--output)
           OUTPUT="$2"
           shift 2
           ;;
        --) shift ; break ;;
        *) usage ; exit 1 ;;
    esac
done
SERVICE_ACCOUNT="$1"
if [[ -z "${SERVICE_ACCOUNT}" ]]; then
  usage
  exit 1
fi

KUBECTL="kubectl $KUBECTL_OPTS"


NAMESPACE=$($KUBECTL  get sa ${SERVICE_ACCOUNT} -ojsonpath='{.metadata.namespace}') || exit 1
SA_SECRET=$($KUBECTL get sa ${SERVICE_ACCOUNT} -ojson | jq -r  ".secrets[].name | select( startswith(\"${SERVICE_ACCOUNT}-token\")) ")

CLUSTER_NAME=$($KUBECTL config view --minify -ojsonpath='{.clusters[0].name}')
KUBE_API_SERVER=$($KUBECTL config view --minify -ojsonpath='{.clusters[0].cluster.server}')
SA_CA_DATA=$($KUBECTL get secret $SA_SECRET -ojsonpath='{.data.ca\.crt}')
SA_TOKEN=$($KUBECTL get secret $SA_SECRET -ojsonpath='{.data.token}' | base64 -d)

CONTEXT_NAME=${NAMESPACE}/${CLUSTER_NAME}/serviceaccount:${SERVICE_ACCOUNT}
USER_NAME=${NAMESPACE}/${CLUSTER_NAME}/serviceaccount:${SERVICE_ACCOUNT}

if [[ -z "${OUTPUT}" ]]; then
  OUTPUT=~/.kube/"${CLUSTER_NAME/":"/_}-${NAMESPACE}"-"${SERVICE_ACCOUNT}"-kubeconfig
  mkdir -p $(dirname "${OUTPUT}" )
fi

echo "Creating kubeconfig file in $OUTPUT for: 
KUBECTL_OPTS=$KUBECTL_OPTS
NAMESPACE=$NAMESPACE
SERVICE_ACCOUNT=$SERVICE_ACCOUNT
SA_SECRET=$SA_SECRET
CLUSTER_NAME=$CLUSTER_NAME
KUBE_API_SERVER=$KUBE_API_SERVER
CONTEXT_NAME=$CONTEXT_NAME
USER_NAME=$USER_NAME
"

cat > $OUTPUT <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${SA_CA_DATA}
    server: ${KUBE_API_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: ${NAMESPACE}
    user: ${USER_NAME}
  name: ${CONTEXT_NAME}
current-context: ${CONTEXT_NAME}
preferences: {}
users:
- name: ${USER_NAME}
  user:
    token: $SA_TOKEN
EOF
[[ $? == 0 ]] && echo "kubeconfig file has been created in $OUTPUT
You can export KUBECONFIG:

export KUBECONFIG=\"$OUTPUT\"
"

