# Installing Codefresh on openshift

### Abstract
* all codefresh assets are running in separate "codefresh" openshift project
* some of the services use serviceAccount in codefresh project which gets admin role in the project only
* we need SecurityContextConstraints which allows privileged securityContext to be assigned to system:serviceaccount:codefresh:admin 
* helm tiller is running in "codefresh" project with project-admin role and doesn't have any cluster wide privileges 
* we need to create routes for our frontend services

### Creating Project with admin role and sec content
As system-admin create codefresh Project, ServiceAccount and SecurityContextConstraints  
`oc apply -f codefresh-project/`
or 
```
./create-codefresh-project.sh
```

### Create 

### Create kubeconfig file for codefresh serviceaccount
```
./create-sa-kubeconfig.sh -n codefresh admin

# see the output to get exact kubeconfig filename
export KUBECONFIG=~/.kube/<cluster-name>_8443-codefresh-admin-kubeconfig
```

### Install tiller with project-admin role
```
oc apply -f tiller/
```

### run the installer (from repo root dir)
```
./cf-onprem --tiller-namespace codefresh
```

### deploy routers
```
oc apply -f ./routes
```


