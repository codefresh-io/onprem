#!/usr/bin/env bash
#

DIR=$(dirname $0)
RELEASE=cf-validator
CHART=${DIR}/validator
NAMESPACE=${NAMESPACE:-codefresh}
HELM_TIMEOUT=60

RELEASE_STATUS=$(helm status $RELEASE 2>/dev/null | awk -F': ' '$1 == "STATUS" {print $2}')
if [[ -n "${RELEASE_STATUS}" ]]; then
   echo "There is a previous run of $RELEASE with status $RELEASE_STATUS , deleting it"
   helm delete $RELEASE --purge
fi

VALUES_FILE=${DIR}/values.yaml

HELM=${HELM:-helm}

HELM_COMMAND="$HELM --namespace $NAMESPACE install -n $RELEASE $CHART -f ${VALUES_FILE} --timeout $HELM_TIMEOUT --wait $@"

echo "Running ${RELEASE} helm release 
$HELM_COMMAND
"

eval $HELM_COMMAND &
HELM_PID=$!

echo "Waiting ${HELM_TIMEOUT}s for validator release to complete ..."
wait $HELM_PID
HELM_EXIT_STATUS=$?

if [[ "${HELM_EXIT_STATUS}" == 0 ]]; then
  echo "Validation Complete Successfully. Cleaning validator release"
  helm delete $RELEASE --purge
else
  kubectl --namespace $NAMESPACE get pods,pvc,pv,svc -l app=${RELEASE}
  echo "Validation Failed. Use kubectl desribe pod|pvc|pv $RELEASE to see the cause"
  exit 1
fi


