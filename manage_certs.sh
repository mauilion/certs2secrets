#!/bin/bash
CERT_PATH="${CERT_PATH:-/certs}"
CLUSTER_NAME=${CLUSTER_NAME:-"etcd-cluster"}
CLUSTER_FQDN=${CLUSTER_FQDN:-"*.etcd-cluster.default.svc"}
KUBECTL_CMD="/usr/local/bin/kubectl"
KUBECSR_CMD="/usr/local/bin/kube-csr"
NAMESPACE=${NAMESPACE:-"default"}
SLEEP_TIME=${SLEEP_TIME:-"30"}

function cert_manager () {
  for cert in client peer server ; do
    SECRET_NAME="${CLUSTER_NAME}-${cert}-tls"
    SANS=$(case "${cert}" in
    (client)
    echo ""
    ;;
    (peer)
    echo ${PEER_CERT_SAN:-"${CLUSTER_FQDN}"}
    ;;
    (server)
    echo ${SERVER_CERT_SAN:-"\"${CLUSTER_FQDN}\",\"127.0.0.1\""}
    ;;
    esac)
    ## Don't check on csr. It may be cleaned up after downloading the certificate.
    echo "checking if cert ${SECRET_NAME} exists in namespace: ${NAMESPACE}"
    ${KUBECTL_CMD} get secret --namespace ${NAMESPACE} ${SECRET_NAME}
    if [[ $? == 0 ]] ; then
      echo "cert ${SECRET_NAME} already exists. Moving on"
      continue
    else
      echo "generating the certificate for ${CLUSTER_NAME} ${cert} communication"
      ${KUBECSR_CMD} \
      issue ${SECRET_NAME} \
      --csr-name=${SECRET_NAME} \
      --generate \
      --submit \
      --approve \
      --fetch \
      --delete \
      --subject-alternative-names="${SANS}" \
      --private-key-file=${CERT_PATH}/${SECRET_NAME}.key \
      --csr-file=${CERT_PATH}/${SECRET_NAME}.csr \
      --certificate-file=${CERT_PATH}/${SECRET_NAME}.crt

      echo "creating the tls secret: ${SECRET_NAME} in namespace: ${NAMESPACE}"

      ${KUBECTL_CMD} create secret tls ${SECRET_NAME} \
      --namespace=${NAMESPACE} \
      --cert=${CERT_PATH}/${SECRET_NAME}.crt \
      --key=${CERT_PATH}/${SECRET_NAME}.key
    fi
  done
}

while true ; do
  mkdir ${CERT_PATH}
  cert_manager
  echo "cleaning up after certmanager"
  rm -rf ${CERT_PATH}
  echo "nothing left to do. Sleeping ${SLEEP_TIME} seconds"
  sleep ${SLEEP_TIME}
done
