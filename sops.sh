#!/bin/bash

# read input parameters
while [ $# -gt 0 ]
do
  case "$1" in
    -d) ACTION=DECRYPT; shift;;
    -e) ACTION=ENCRYPT; shift;;
    -h)
        echo >&2 "usage: $0 -(e|d) [encrypt|decrypt '*-enc.*' values files]"
        exit 1;;
     *) break;; # terminate while loop
  esac
done

DIR=${1:-$(dirname $0)}

DATE_SUFFIX=$(date +%y-%m-%d_%H%M%S)

# encrypt files
if [[ $ACTION == "ENCRYPT" ]]; then
  echo "Executing sops $ACTION on all *-dec.* files in directory $DIR "
  for f in $(find ${DIR} -name "*-dec.*"); do

    BACKUP_DIR=$(dirname ${f})/bak
    mkdir -p ${BACKUP_DIR}
    if [ ${f} == "./values-dec.yaml" ]; then
      ENCRYPTED_FILE=${f/-dec.yaml/-enc.yaml}
      TYPES="--input-type yaml --output-type yaml"
    fi
    if [ ${f} == "./sa-dec.json" ]; then
      ENCRYPTED_FILE=${f/-dec.json/-enc.json}
      TYPES="--input-type json --output-type json"  
    fi
    BAK_FILE=${BACKUP_DIR}/$(basename ${ENCRYPTED_FILE})-${DATE_SUFFIX}
    if [[ -f ${ENCRYPTED_FILE} ]]; then
      echo "Backing up ${ENCRYPTED_FILE} to ${BAK_FILE} "
      cp -v ${ENCRYPTED_FILE} ${BAK_FILE}
    fi
    echo "Encrypting $f ..."
    sops ${TYPES} -e $f > ${ENCRYPTED_FILE}
  done
fi

# descrypt files
if [[ $ACTION == "DECRYPT" ]]; then
  echo "Executing sops $ACTION on all *-enc.* files in directory $DIR "
  for f in $(find ${DIR} -name "*-enc.*"); do

    BACKUP_DIR=$(dirname ${f})/bak
    mkdir -p ${BACKUP_DIR}
    if [ ${f} == "./values-enc.yaml" ]; then
      DECRYPTED_FILE=${f/-enc.yaml/-dec.yaml}
      TYPES="--input-type yaml --output-type yaml"
    fi
    if [ ${f} == "./sa-enc.json" ]; then
      DECRYPTED_FILE=${f/-enc.json/-dec.json}
      TYPES="--input-type json --output-type json"  
    fi
    BAK_FILE=${BACKUP_DIR}/$(basename ${DECRYPTED_FILE})-${DATE_SUFFIX}
    if [[ -f ${DECRYPTED_FILE} ]]; then
      echo "Backing up ${DECRYPTED_FILE} to ${BAK_FILE} "
      cp -v ${DECRYPTED_FILE} ${BAK_FILE}
    fi

    echo "Decrypting $f file"
    sops ${TYPES} -d $f > ${DECRYPTED_FILE}
  done
fi
