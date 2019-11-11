# Installing Codefresh on openshift

### Abstract
* we are creating codefresh openshift project 
* we use "admin" serviceAccount in codefresh project which gets admin role in the project only
* we create SecurityContextConstraints assigned to system:serviceaccount:codefresh:admin

### Creating Project with admin role and sec content
As system-admin create codefresh Project, ServiceAccount and SecurityContextConstraints  
`oc apply -f codefresh-project/`
or 
```
./create-codefresh-project
```

### Create kubeconfig file for codefresh serviceaccount
```
./create-sa-kubeconfig.sh -n codefresh admin

# see the output to get exact kubeconfig filename
export KUBECONFIG=~/.kube/<cluster-name>_8443-codefresh-admin-kubeconfig
```

### Install tiller with admin role
###
 ./cf-onprem --tiller-namespace codefresh

### deploy routers
oc apply -f ./routes

### deployments and statefulsets for the services 
oc patch sts/cf-builder --patch '{"spec":{"template":{"spec":{"serviceAccountName": "admin"}}}}'
oc patch sts/cf-runner --patch '{"spec":{"template":{"spec":{"serviceAccountName": "admin"}}}}'
oc patch sts/cf-consul --patch '{"spec":{"template":{"spec":{"serviceAccountName": "admin"}}}}'

oc patch deploy/cf-redis --patch '{"spec":{"template":{"spec":{"serviceAccountName": "admin"}}}}'
oc patch deploy/cf-mongodb --patch '{"spec":{"template":{"spec":{"serviceAccountName": "admin"}}}}'
oc patch deploy/cf-postgresql  --patch '{"spec":{"template":{"spec":{"serviceAccountName": "admin"}}}}'
oc patch deploy/cf-rabbitmq --patch '{"spec":{"template":{"spec":{"serviceAccountName": "admin"}}}}'

