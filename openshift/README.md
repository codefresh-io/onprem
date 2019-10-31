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

export KUBECONFIG
```
 



