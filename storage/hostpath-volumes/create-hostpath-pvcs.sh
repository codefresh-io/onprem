#!/usr/bin/env bash
#

DIR=$(dirname $0)
RELEASE=cf-hostpath-volumes
CHART=$(realpath ${DIR}/../hostpath-volumes)
NAMESPACE=${NAMESPACE:-codefresh}
#TILLER_NAMESPACE=${TILLER_NAMESPACE:-"kube-system"}

HELM_TIMEOUT=60

source ${DIR}/../../scripts/helpers.sh

if [[ -z "${IN_INSTALLER}" ]]; then
  approveContext

  # msg "Checking helm binary on your system"
  # checkHelmInstalled "helm"

  # msg "Checking if tiller is installed on kubernetes cluster"
  # checkTillerInstalled

  # msg "Checking tiller status..."
  # checkTillerStatus
fi

#HELM_OPTS="--tiller-namespace $TILLER_NAMESPACE"
HELM="${HELM_COMMAND:-helm} $HELM_OPTS "

RELEASE_STATUS=$($HELM status $RELEASE 2>/dev/null | awk -F': ' '$1 == "STATUS" {print $2}')
if [[ -n "${RELEASE_STATUS}" ]]; then
   echo "There is a previous run of $RELEASE with status $RELEASE_STATUS
Run: helm status cf-local-volumes; to check the status of the release
Or run: helm del --purge cf-local-volumes; to delete it   

   "
   exit 1
fi

VALUES_FILE=${DIR}/values.yaml
OUTPUT_DIR=${DIR}/out
mkdir -p ${OUTPUT_DIR}/

HELM_COMMAND="$HELM --namespace $NAMESPACE template  -n $RELEASE --output-dir ${OUTPUT_DIR} $CHART $@"

echo "Running ${RELEASE} helm release 
$HELM_COMMAND
"

eval $HELM_COMMAND &
HELM_PID=$!

wait $HELM_PID
HELM_EXIT_STATUS=$?

if [[ "${HELM_EXIT_STATUS}" == 0 ]]; then
  echo "Hostpath Volumes yamls created in ${OUTPUT_DIR}
  "
else
  echo "
  Hostpath Volumes chart submission FAILED."
fi

exit $HELM_EXIT_STATUS