### Local Volumes helm chart 
Creates Loval volumes and pvcs, makes directories on the nodes

Copy from template and edit values.yaml
Set 
```
cp values.yaml.tmpl values.yaml
vi  values.yaml

./create-local-pvcs.sh
```
