#!/usr/bin/env bash
#

DIR=$(dirname $0)
RELEASE=cf-validator
CHART=${DIR}/validator
NAMESPACE=${NAMESPACE:-codefresh}
HELM_TIMEOUT=60

VALUES_FILE=${DIR}/values.yaml
if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "Error: values file ${VALUES_FILE} does not exist"
  exit 1
fi

source ${DIR}/scripts/helpers.sh

approveContext

## Get default storage class
SC_DEFAULT_QUERY='{{ range .items }}'
SC_DEFAULT_QUERY+='{{if .metadata.annotations }}{{if (index .metadata.annotations "storageclass.beta.kubernetes.io/is-default-class") }}'
SC_DEFAULT_QUERY+='{{ .metadata.name }}{{"\n"}}'
SC_DEFAULT_QUERY+='{{end}}{{end}}{{end}}'
DEFAULT_STORAGE_CLASS=$(kubectl -ogo-template="$SC_DEFAULT_QUERY" get sc)
if [[ -n "${DEFAULT_STORAGE_CLASS}" ]]; then
   DEFAULT_STORAGE_CLASS_PARAM="--set defaultStorageClass=${DEFAULT_STORAGE_CLASS}"
fi

RELEASE_STATUS=$(helm status $RELEASE 2>/dev/null | awk -F': ' '$1 == "STATUS" {print $2}')
if [[ -n "${RELEASE_STATUS}" ]]; then
   echo "There is a previous run of $RELEASE with status $RELEASE_STATUS , deleting it"
   helm delete $RELEASE --purge
fi

HELM=${HELM:-helm}

HELM_COMMAND="$HELM --namespace $NAMESPACE install -n $RELEASE $CHART -f ${VALUES_FILE} ${DEFAULT_STORAGE_CLASS_PARAM} --timeout $HELM_TIMEOUT --wait $@"

echo "Running ${RELEASE} helm release 
$HELM_COMMAND
"

eval $HELM_COMMAND &
HELM_PID=$!

echo "Waiting ${HELM_TIMEOUT}s for validator release to complete ...
You can view a progress by running the command below in separate shell

kubectl --namespace $NAMESPACE get pods,pvc,pv,svc -l app=${RELEASE} 

"
wait $HELM_PID
HELM_EXIT_STATUS=$?

if [[ "${HELM_EXIT_STATUS}" == 0 ]]; then
  echo "Cleaning validator release"
  helm delete $RELEASE --purge
  echo "Validation Complete Successfully"
else
  # kubectl --namespace $NAMESPACE get pods,pvc,pv,svc -l app=${RELEASE}
  echo "
Validation FAILED. See the messages above
Check failed or pending resources by: 
kubectl desribe <pending pod|pvc|pv> ${RELEASE}-* to see the cause
  "
  exit 1
fi


