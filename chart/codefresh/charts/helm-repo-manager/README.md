# helm-repo-manager Helm chart

## TL;DR

```sh
helm install codefresh/helm-repo-manager
```

## Introduction

This chart bootstraps a [helm-repo-manager](https://github.com/codefresh-io/helm-repo-manager) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.8+ with Beta APIs enabled
- Codefresh Helm Release

## Installing the Chart

To install the chart with the release name `my-release`:

```sh
helm install --name my-release --namespace codefresh codefresh/helm-repo-manager
```

The command deploys helm-repo-manager on the Kubernetes cluster in the `codefresh` namespace with default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```sh
helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the helm-repo-manager chart and their default values.

| Parameter              | Description                                                      | Default                                               |
| ---------------------- | ---------------------------------------------------------------- | ------------------------------------------------------|
| `image.repository`     | helm-repo-manager image                                          | `r.cfcr.io/codefresh-inc/codefresh/helm-repo-manager` |
| `image.tag`            | helm-repo-manager image tag                                      | `master`                                              |
| `image.PullPolicy`     | Image pull policy                                                | `Always`                                              |
| `service.name`         | Kubernetes Service name                                          | `helm-repo-manager`                                   |
| `service.type`         | Kubernetes Service type                                          | `ClusterIP`                                           |
| `service.externalPort` | Service external port                                            | `80`                                                  |
| `service.externalPort` | Service internal port                                            | `8080`                                                |
| `logLevel`             | Log level: `debug`, `info`, `warning`, `error`, `fatal`, `panic` | `debug`                                               |

## Dependency

helm-repo-manager requires [ChartMuseum chart](https://hub.kubeapps.com/charts/stable/chartmuseum) (`1.3.1` version).
