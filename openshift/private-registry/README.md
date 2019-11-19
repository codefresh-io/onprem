## Private Registry for images in Openshift

*Usage Case*: all the runtime related images (engine, dind, logger, puller, pusher ) should be in private registry

https://docs.openshift.com/enterprise/3.0/dev_guide/image_pull_secrets.html#allowing-pods-to-reference-images-from-other-secured-registries

#### Create dockercfg secret:  
```
oc secrets new-dockercfg <pull_secret_name> \
    --docker-server=<registry_server> --docker-username=<user_name> \
    --docker-password=<password> --docker-email=<email>
```
Example:  
```
oc create secret docker-registry runtime-registry --docker-server=os-registry.cf-cd.com:5000 --docker-username=codefresh  --docker-password=***** --docker-email=openshift@codefresh.io
```

#### Adding dockercfg secret to serviceAccount
```
oc secrets add serviceaccount/default secrets/<pull_secret_name> [ --for=pull ]
```

Example:  
```
oc secrets add serviceaccount/default secrets/runtime-registry --for=pull
oc secrets add serviceaccount/admin secrets/runtime-registry
```

*How it works in Openshift:*  
it adds imagePullSecret fields to service account:
```
oc get sa default -oyaml
apiVersion: v1
imagePullSecrets:
- name: runtime-registry
- name: default-dockercfg-cg9jt
kind: ServiceAccount
metadata:
  name: default
  namespace: codefresh
secrets:
- name: default-token-8qzqn
- name: default-dockercfg-cg9jt
- name: runtime-registry
```

And there is an admission controller which adds imagePullSecrets to each pod by the data in serviceAccount

there is some issue in Openshift (bug) when it adds only first imagePullSecret of ServiceAccount to the pod 
In this case just do `oc edit sa default` and set runtime-registry as a first in the list 

#### Configure runtime environment to use private images:
```
runtimeScheduler:
  type: KubernetesPod
  workflowLimits:
    MAXIMUM_ALLOWED_WORKFLOW_AGE_BEFORE_TERMINATION: '86400'
  internalInfra: true
  cluster:
    inCluster: true
    namespace: codefresh
  image: 'os-registry.cf-cd.com:5000/codefresh/engine:cf-onprem-v1.0.87'
  envVars:
    RESOURCE_LIMITATIONS_JSON: /etc/admin/resource-limitations.json
    RUNTIME_INTERNAL_REGISTRY_JSON: /etc/admin/internal-registry.json
    RUNTIME_ADDITIONAL_INTERNAL_REGISTRIES_JSON: /etc/admin/additional-internal-registries.json
    LOGGER_LEVEL: debug
    NODE_ENV: kubernetes
    DOCKER_PUSHER_IMAGE: 'os-registry.cf-cd.com:5000/codefresh/cf-docker-pusher:cf-onprem-v1.0.87'
    DOCKER_PULLER_IMAGE: 'os-registry.cf-cd.com:5000/codefresh/cf-docker-puller:cf-onprem-v1.0.87'
    DOCKER_BUILDER_IMAGE: 'os-registry.cf-cd.com:5000/codefresh/cf-docker-builder:cf-onprem-v1.0.87'
    CONTAINER_LOGGER_IMAGE: 'os-registry.cf-cd.com:5000/codefresh/cf-container-logger:cf-onprem-v1.0.87'
    GIT_CLONE_IMAGE: 'codefresh/cf-git-cloner:cf-onprem-v1.0.87'
    DOCKER_TAG_PUSHER_IMAGE: 'os-registry.cf-cd.com:5000/codefresh/cf-docker-tag-pusher:v2'
```
