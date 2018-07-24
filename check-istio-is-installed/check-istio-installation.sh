#!/bin/bash

NAMESPACE="istio-system"
CLI_COMMAND="kubectl"
ATTEMPTS="10"
INTERVAL="10"
QUIET=""

function usage() {
  [[ -n "${1}" ]] && echo "${1}"

  cat <<EOF
Usage: ${BASH_SOURCE[0]} [options ...]"
  options:
    -n <NAMESPACE>   Namespace where to check for Istio installation. Default is "istio-system".
    -c <CLI_COMMAND> CLI command to use. Default is "kubectl".
    -a <ATTEMPTS>    Number of times to check for Istio installation. Default is "${ATTEMPTS}".
    -i <INTERVAL>    Interval, in seconds, between checks. Default is "${INTERVAL}"
    -q               Be quiet. Default is false.

EOF
  exit 2
}

function msg() {
  if [ -z "${QUIET}" ]; then
    echo $*
  fi
}

function check_istio_installation() {
  local i=1
  local ret=0

  while [ ${i} -le ${ATTEMPTS} ]; do
    msg "Checking Istio installation, attempt ${i} of ${ATTEMPTS}"

    local deployments=$(${CLI_COMMAND} -n ${NAMESPACE} get deployments -o=jsonpath='{range .items[*]}{.metadata.name}{"|"}{.status.replicas}{"|"}{.status.availableReplicas}{"\n"}{end}')
    if [ -z "${deployments}" ]; then
      msg "Wrong output for 'get deployments'. Make sure the command (${CLI_COMMAND}) and namespace (${NAMESPACE}) are correct."
      return 1
    fi

    for line in ${deployments}; do
      IFS='|' read -ra deploy <<< "${line}"
      # $deploy array items: 0: name; 1: desired replicas; 2: actual replicas
      if [ -z "${deploy[2]}" ]; then
        deploy[2]="0"
      fi
      if [ "${deploy[1]}" != "${deploy[2]}" ]; then
        msg "${deploy[0]} is not ready yet (${deploy[2]}/${deploy[1]})"
        ret=1
      fi
    done

    if [ ${ret} -eq 0 ]; then
      break
    elif [ ${i} -lt ${ATTEMPTS} ]; then
      msg "Waiting ${INTERVAL} seconds to try again..."
      sleep ${INTERVAL}
    fi

    let i=i+1
  done

  msg ""
  if [ ${ret} -ne 0 ]; then
    msg "Istio installation is NOT OK"
  else
    msg "Istio installation is OK"
  fi

  return ${ret}
}

while getopts ":n:c:a:i:q" opt; do
  case ${opt} in
    n) NAMESPACE="${OPTARG}";;
    c) CLI_COMMAND="${OPTARG}";;
    a) ATTEMPTS="${OPTARG}";;
    i) INTERVAL="${OPTARG}";;
    q) QUIET=true;;
    *) usage;;
  esac
done

check_istio_installation