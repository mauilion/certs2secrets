#!/bin/bash
CERT_PATH="/certs"
APP_NAME="${APP_NAME:-certs2secrets}"
CLUSTER_FQDN=${CLUSTER_FQDN:-"*.etcd-cluster.default.svc"}
KUBECTL_CMD="/usr/local/bin/kubectl"
KUBECSR_CMD="/usr/local/bin/kube-csr"
NAMESPACE=${NAMESPACE:-"default"}
SLEEP_TIME=${SLEEP_TIME:-"30"}
CLIENT_CERT=${CLIENT_CERT:-false}
PEER_CERT=${PEER_CERT:-false}
SERVER_CERT=${SERVER_CERT:-false}

function cert_manager () {
  cert=$1
  SECRET_NAME="${CLUSTER_NAME}-${cert}-tls"
  SANS=$(case "${cert}" in
  (client)
  echo ""
  ;;
  (peer)
  echo ${PEER_CERT_SAN:-"${CLUSTER_FQDN}"}
  ;;
  (server)
  echo ${SERVER_CERT_SAN:-"\"${CLUSTER_FQDN}\",\"localhost\",\"127.0.0.1\""}
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
    ${KUBECTL_CMD} delete csr -n ${NAMESPACE} ${SECRET_NAME}
    ${KUBECSR_CMD} \
    issue ${SECRET_NAME} \
    --csr-name=${SECRET_NAME} \
    --generate \
    --submit \
    --approve \
    --fetch \
    --subject-alternative-names="${SANS}" \
    --private-key-file=${CERT_PATH}/${cert}.key \
    --csr-file=${CERT_PATH}/${cert}.csr \
    --certificate-file=${CERT_PATH}/${cert}.crt

    ln -sfn /var/run/secrets/kubernetes.io/serviceaccount/ca.crt ${CERT_PATH}/${cert}-ca.crt

    echo "creating the tls secret: ${SECRET_NAME} in namespace: ${NAMESPACE}"

    ${KUBECTL_CMD} create secret generic ${SECRET_NAME} \
    --namespace=${NAMESPACE} \
    --from-file=${cert}.crt=${CERT_PATH}/${cert}.crt \
    --from-file=${cert}.key=${CERT_PATH}/${cert}.key \
    --from-file=${cert}-ca.crt=${CERT_PATH}/${cert}-ca.crt \
    --from-file=${cert}.csr=${CERT_PATH}/${cert}.csr

    fi
}


while true ; do
  mkdir ${CERT_PATH}
  case true in
  ($CLIENT_CERT)
  cert_manager client
  ;;
  ($PEER_CERT)
  cert_manager peer
  ;;
  ($SERVER_CERT)
  cert_manager server
  ;;
  esac
  echo "cleaning up after certmanager"
  rm -rf ${CERT_PATH}
  echo "nothing left to do. Sleeping ${SLEEP_TIME} seconds"
  sleep ${SLEEP_TIME}
done
