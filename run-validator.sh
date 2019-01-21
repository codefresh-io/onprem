#!/usr/bin/env bash
#

DIR=$(dirname $0)
RELEASE=cf-validator
CHART=${DIR}/validator
NAMESPACE=${NAMESPACE:-codefresh}
HELM_TIMEOUT=60

approveContext() {
	echo "Your kubectl is configured with the following context: "
	kubectl config current-context
	read -r -p "Are you sure you want to continue? [y/N] " response

	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
	then
			echo ""
	else
			echo "Exiting..."
			exit 0
	fi
}

approveContext

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

echo "Waiting ${HELM_TIMEOUT}s for validator release to complete ...
You can view a progress by running the command below in separate shell

kubectl --namespace $NAMESPACE get pods,pvc,pv,svc -l app=${RELEASE} \"

"
wait $HELM_PID
HELM_EXIT_STATUS=$?

if [[ "${HELM_EXIT_STATUS}" == 0 ]]; then
  echo "Cleaning validator release"
  helm delete $RELEASE --purge
  echo "Validation Complete Successfully"
else
  kubectl --namespace $NAMESPACE get pods,pvc,pv,svc -l app=${RELEASE}
  echo "Validation FAILED. There are failed or pending resources

Use kubectl desribe <pending pod|pvc|pv> $RELEASE to see the cause
  "
  exit 1
fi


