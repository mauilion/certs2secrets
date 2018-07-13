# certs2secrets
## Shoutout to Julian Balestra for [kube-csr](https://github.com/JulienBalestra/kube-csr)

## Basic design:

The goal is to generate a set kubernetes tls secrets that will be used to secure an etcd cluster as provided by the etcd-operator.

The vars that this container makes use of are:

```
CLUSTER_NAME=${CLUSTER_NAME:-"etcd-cluster"}
CLUSTER_FQDN=${CLUSTER_FQDN:-"*.etcd-cluster.default.svc"}
NAMESPACE=${MY_POD_NAMESPACE:-"default"}
SLEEP_TIME=${SLEEP_TIME:-"30"}
```

You need to specify these with the `deployment.spec.containers.env` mechanism. There is an example in [examples](/examples)

On an RBAC enables cluster you will also need to create the roles in the [examples](/examples) dir to allow the service account (certs2secrets) associated with the pod permissions to create the certificates and upload the secrets into the namespace you have chosen.
