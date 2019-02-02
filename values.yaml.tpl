global:

### Instantiate databases with seed data. Usually used in dynamic and on-prem environments.
  #seedJobs: true
  #certsJobs: true

  appProtocol: https
### Codefresh App domain name
  appUrl: your-domain.com

# Storage class for all persistent services 
#  storageClass: {}
  localStorage: true
  localStorageNodeSelector:
    kubernetes.io/hostname: node-01

### MTU Value for dockerd in builder and runner
#  mtu: 1400

### Environment variables applied to all pods
#  env:
#    HTTP_PROXY: "http://myproxy.domain.com:8080"
#    http_proxy: "http://myproxy.domain.com:8080"
#    HTTPS_PROXY: "http://myproxy.domain.com:8080"
#    https_proxy: "http://myproxy.domain.com:8080"
#    NO_PROXY: "127.0.0.1,localhost,kubernetes.default.svc,.codefresh.svc,100.64.0.1,169.254.169.254,cf-builder,cf-cfapi,cf-cfui,cf-chartmuseum,cf-charts-manager,cf-cluster-providers,cf-consul,cf-consul-ui,cf-context-manager,cf-cronus,cf-helm-repo-manager,cf-hermes,cf-ingress-controller,cf-ingress-http-backend,cf-kube-integration,cf-mongodb,cf-nats,cf-nomios,cf-pipeline-manager,cf-postgresql,cf-rabbitmq,cf-redis,cf-registry,cf-runner,cf-runtime-environment-manager,cf-store,cf-tasker-kubernetes"
#    no_proxy: "127.0.0.1,localhost,kubernetes.default.svc,.codefresh.svc,100.64.0.1,169.254.169.254,cf-builder,cf-cfapi,cf-cfui,cf-chartmuseum,cf-charts-manager,cf-cluster-providers,cf-consul,cf-consul-ui,cf-context-manager,cf-cronus,cf-helm-repo-manager,cf-hermes,cf-ingress-controller,cf-ingress-http-backend,cf-kube-integration,cf-mongodb,cf-nats,cf-nomios,cf-pipeline-manager,cf-postgresql,cf-rabbitmq,cf-redis,cf-registry,cf-runner,cf-runtime-environment-manager,cf-store,cf-tasker-kubernetes"

### Firebase secret
firebaseSecret: 

## Custom annotations for Codefresh ingress resource that override defaults
#annotations:
#  kubernetes.io/ingress.class: nginx-codefresh

## Persistent services (mongodb, consul, postgress, redit, rabbit) configuration
# you can configure storageClass for dynamic volume provisoning or precreated existingPvc name
# existingPvc should exist before launching the intallation and takes precedence over storageClass
#
# Specify node selector if 
# Example 1, mongodb with storageClass for dynamic volume provisoning:
# mongodb:
#   storageClass: ceph-pool-1
#   storageSize: 8Gi
#
# Example 2, rabbitmq on precreated pvc for local volume on cpecific volume
# 
# postgresql:
#   existingPvc: cf-postgress-lv
#   nodeSelector:
#     kubernetes.io/hostname: storage-host-01

mongodb:
  storageSize: 8Gi
  storageClass: {}
  existingPvc: {}
  nodeSelector: {}

postgresql:
  storageSize: 8Gi
  storageClass: {}
  existingPvc: {}
  nodeSelector: {}

consul:
  storageSize: 1Gi
  storageClass: {}
  existingPvc: {}
  nodeSelector: {}

redis:
  storageSize: 8Gi
  storageClass: {}
  existingPvc: {}
  nodeSelector: {}

rabbitmq:
  storageSize: 8Gi
  storageClass: {}
  existingPvc: {}
  nodeSelector: {}

registry:
  storageSize: 100Gi
  storageClass: {}
  existingPvc: {}
  nodeSelector: {}
# Insert custom registry configuration (https://docs.docker.com/registry/configuration/)
#   registryConfig:
#     version: 0.1
#     log:
#       level: debug
#       fields:
#         service: registry
#     storage:
#       cache:
#         blobdescriptor: inmemory
#       s3:
#          region: YOUR_REGION
#          bucket: YOUR_BUCKET_NAME
#          accesskey: AWS_ACCESS_KEY
#          secretkey: AWS_SECRET_KEY
#     http:
#       addr: :5000
#       headers:
#         X-Content-Type-Options: [nosniff]
#     health:
#       storagedriver:
#         enabled: true
#         interval: 10s
#         threshold: 3 

hermes:
  nodeSelector: {}
#    services: rabbitmq-registry
  redis:
## Set hermes store password. It is mandatory
    redisPassword: verysecurepassword
    storageSize: 8Gi
    storageClass: {}
    existingPvc: {}
    nodeSelector: {}

cronus:
  storageSize: 1Gi
  storageClass: {}
  existingPvc: {}
  nodeSelector: {}

builder:
  nodeSelector: {}
## Set time to run docker cleaner  
  dockerCleanerCron: 0 0 * * *
## Override builder PV initial size
  varLibDockerVolume:
    storageSize: 100Gi
    existingPvc: {}
    storageClass: {}

runner:
  nodeSelector: {}
## Set time to run docker cleaner  
  dockerCleanerCron: 0 0 * * *
## Override runner PV initial size
  varLibDockerVolume:
    storageSize: 100Gi
    existingPvc: {}
    storageClass: {}

# helm-repo-manager:
#   RepoUrlPrefix: "cm://<app_url>"

# backups:
#   #enabled: true
#   awsAccessKey: 
#   awsSecretAccessKey: 
#   s3Url: s3://<some-bucket>
    
