#!/usr/bin/env bash
#
# Creates codefresh project - should run as cluster-admin
#
DIR=$(dirname ${BASH_SOURCE})

YAMLS_DIR="${DIR}"/codefresh-project

echo "Creating Codefresh project"
oc apply -f "${YAMLS_DIR}"/
