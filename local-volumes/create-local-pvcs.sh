#!/usr/bin/env bash
#

DIR=$(dirname $0)
RELEASE=cf-local-volumes
CHART=$(realpath ${DIR}/../local-volumes)
NAMESPACE=${NAMESPACE:-codefresh}
HELM_TIMEOUT=60

source ${DIR}/../scripts/helpers.sh

approveContext

RELEASE_STATUS=$(helm status $RELEASE 2>/dev/null | awk -F': ' '$1 == "STATUS" {print $2}')
if [[ -n "${RELEASE_STATUS}" ]]; then
   echo "There is a previous run of $RELEASE with status $RELEASE_STATUS
Run: helm status cf-local-volumes; to check the status of the release
Or run: helm del --purge cf-local-volumes; to delete it   

   "
   exit 1
fi

VALUES_FILE=${DIR}/values.yaml

HELM=${HELM:-helm}

HELM_COMMAND="$HELM --namespace $NAMESPACE install -n $RELEASE $CHART $@"

echo "Running ${RELEASE} helm release 
$HELM_COMMAND
"

eval $HELM_COMMAND &
HELM_PID=$!

wait $HELM_PID
HELM_EXIT_STATUS=$?

if [[ "${HELM_EXIT_STATUS}" == 0 ]]; then
  echo "Local Volumes chart has been submitted. Run the command below to insect the status
   kubectl --namespace $NAMESPACE get pods,pvc,pv,svc -l app=${RELEASE}
  "
else
  echo "
  Local Volumes chart submission FAILED."
fi

exit $HELM_EXIT_STATUS