### Local Hostpath helm chart 
Creates hostpath volumes and pvcs

Copy from template and edit values.yaml
Set 
```
cp values.yaml.tmpl values.yaml
vi  values.yaml

./create-hostpath-pvcs.sh
```
It outputs the yamls to `out/hostpath-volumes/templates `

Create PV and PVCs:  
```
kubectl apply -f out/hostpath-volumes/templates/*
```

##### selinux note
the hostPath folders should be of container_file_t selinux type to be accessed from pods

