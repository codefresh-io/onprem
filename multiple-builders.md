## How to add extra builders to on-prem installation running on local volumes

### To add extra builders to on-prem installation running on local volumes you need:

* check that you have created the directory structure on every node you want to run a builder pod on.
the node names should be set in`local-volumes/values.yaml` file
in `mkdirPods.nodes` list

after the installation finishes and everything works fine, you need to:

* point kubectl to the cluster where your codefresh onprem is installed:
```
kubectl config use-context your_cluster
```
create and apply additional pv,pvc,svc and statefulset `per node` that will be used by additional builders:

* get your current builder pv and pvc yamls:
```
kubectl get pv cf-builder-0 -oyaml > cf-builder-1-pv.yaml
kubectl get pvc -ncodefresh cf-builder-0 -oyaml > cf-builder-1-pvc.yaml
```
in pv yaml change:
```
`name:` to cf-builder-1
nodeselector `value`   according to the node name
```
in pvc yaml change:
```
`name:` to cf-builder-1
`volumeName:` cf-builder-1
```
apply the yamls with `kubectl apply -f filename.yaml`

check pv and pvc:
```
kubectl get pv
kubectl get pvc -ncodefresh
```
* get a copy of cf-builder service configuration:
```
kubectl get svc cf-builder -ncodefresh  -oyaml > cf-builder-1-svc.yaml
```
in svc yaml change:
```
`metadata.labels.app: cf-builder-1`
`metadata.name: cf-builder-1`
`spec.selector.app: cf-builder-1`
```

* copy cf-builder statefulset configuration:
```
kubectl get statefulset -ncodefresh cf-builder -oyaml > cf-builder-1-statefulset.yaml
```
in statefulset yaml change:
```
`metadata.labels.app: cf-builder-1`
`metadata.name: cf-builder-1`
`spec.serviceName: cf-builder-1`
`spec.selector.matchLabels.app: cf-builder-1`
`spec.template.metadata.labels.app: cf-builder-1` 
`spec.template.spec.containers.name: cf-builder-1`
`spec.template.spec.initContainers.command:
        - /bin/sh
        - -c
        - cp -L /opt/dind/register /usr/local/bin/ && chmod +x /usr/local/bin/register
          && /usr/local/bin/register ${POD_NAME} cf-builder-1.codefresh.svc`

`spec.template.spec.volumes:
      - name: varlibdocker
        persistentVolumeClaim:
          claimName: cf-builder-1`
```
increment cf-builder-{n}  for every new builder instance (can be as much as nodes in the cluster), 
then apply yamls with `kubectl apply -f filename.yaml`

check that all new builders are registered by visiting `AdminManagement-->Nodes`

example yamls of an additional builder can be found in examples dir.


