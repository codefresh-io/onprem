{{- define "runtime-environment-config" -}}
[
  {
    "metadata": {
      "name": "system/default"
    },
    "description": "System default template for plan",
    "environmentCertPath": "/etc/ssl/cf/",
    "dockerDaemonScheduler": {
      "type": "ConsulNodes",
      "cluster": {
        "name": "codefresh",
        "type": "builder",
        "returnRunnerIfNoBuilder": true
      },
      "notCheckServerCa": true,
      "clientCertPath": "/etc/ssl/cf/"
    },
    "runtimeScheduler": {
      "type": "KubernetesPod",
      "cluster": {
        "inCluster": true,
        "namespace": "codefresh"
      },
      "image": "{{ .Values.engineImage }}",
      "envVars": {
        {{- if .Values.global.env }}
        {{- range $key, $value := .Values.global.env }}
        {{ $key | quote }}: {{ $value | quote }},
        {{- end}}
        {{- end}}
        "RESOURCE_LIMITATIONS_JSON": "/etc/admin/resource-limitations.json",
        "RUNTIME_INTERNAL_REGISTRY_JSON": "/etc/admin/internal-registry.json",
        "RUNTIME_ADDITIONAL_INTERNAL_REGISTRIES_JSON": "/etc/admin/additional-internal-registries.json",
        "LOGGER_LEVEL": "debug",
        "NODE_ENV": "kubernetes",
        "DOCKER_PUSHER_IMAGE": "{{ .Values.DOCKER_PUSHER_IMAGE }}",
        "DOCKER_PULLER_IMAGE": "{{ .Values.DOCKER_PULLER_IMAGE }}",
        "DOCKER_BUILDER_IMAGE": "{{ .Values.DOCKER_BUILDER_IMAGE }}",
        "CONTAINER_LOGGER_IMAGE": "{{ .Values.CONTAINER_LOGGER_IMAGE }}",
        "GIT_CLONE_IMAGE": "{{ .Values.GIT_CLONE_IMAGE }}",
        "DOCKER_TAG_PUSHER_IMAGE": "{{ .Values.DOCKER_TAG_PUSHER_IMAGE }}",
        "NODE_TLS_REJECT_UNAUTHORIZED": "0"
      },
      "volumeMounts": {
        "internal-registry": {
          "name": "internal-registry",
          "mountPath": "/etc/admin/internal-registry.json",
          "subPath": "internal-registry.json",
          "readOnly": true
        },
        "additional-internal-registries": {
          "name": "additional-internal-registries",
          "mountPath": "/etc/admin/additional-internal-registries.json",
          "subPath": "additional-internal-registries.json",
          "readOnly": true
        },
        "resource-limitations": {
          "name": "resource-limitations",
          "mountPath": "/etc/admin/resource-limitations.json",
          "subPath": "resource-limitations.json",
          "readOnly": true
        },
        "cf-certs": {
          "name": "cf-certs",
          "mountPath": "/etc/ssl/cf",
          "readOnly": true
        }
      },
      "volumes": {
        "internal-registry": {
          "name": "internal-registry",
          "configMap": {
            "name": "cf-codefresh-registry"
          }
        },
        "additional-internal-registries": {
          "name": "additional-internal-registries",
          "configMap": {
            "name": "cf-codefresh-registry"
          }
        },
        "resource-limitations": {
          "name": "resource-limitations",
          "configMap": {
            "name": "cf-codefresh-resource-limitations"
          }
        },
        "cf-certs": {
          "name": "cf-certs",
          "secret": {
            "secretName": "cf-codefresh-certs-client"
          }
        }
      }
    },
    "isPublic": true
  },
  {
    "metadata": {
      "name": "system/default/hybrid/k8"
    },
    "description": "Default hybrid system runtime environment for kubernetes",
    "dockerDaemonScheduler": {
      "type": "KubernetesPod",
      "cluster": {
        "namespace": "default"
      },
      "image": "{{ .Values.engineImage }}",
      "resources": {
        "requests": {
          "cpu": "100m",
          "memory": "100Mi"
        },
        "limits": {
          "cpu": "1000m",
          "memory": "2048Mi"
        }
      },
      "envVars": {
        "LOGGER_LEVEL": "debug",
        "NODE_ENV": "kubernetes",
        "DOCKER_PUSHER_IMAGE": "{{ .Values.DOCKER_PUSHER_IMAGE }}",
        "DOCKER_PULLER_IMAGE": "{{ .Values.DOCKER_PULLER_IMAGE }}",
        "DOCKER_BUILDER_IMAGE": "{{ .Values.DOCKER_BUILDER_IMAGE }}",
        "CONTAINER_LOGGER_IMAGE": "{{ .Values.CONTAINER_LOGGER_IMAGE }}",
        "GIT_CLONE_IMAGE": "{{ .Values.GIT_CLONE_IMAGE }}",
        "DOCKER_TAG_PUSHER_IMAGE": "{{ .Values.DOCKER_TAG_PUSHER_IMAGE }}",
        "NODE_TLS_REJECT_UNAUTHORIZED": "0"
      },
      "volumeMounts": {},
      "volumes": {}
    },
    "runtimeScheduler": {
      "type": "DindKubernetesPod",
      "cluster": {
        "namespace": "default"
      },
      "dindImage": "codefresh/dind:18.06-v16",
      "connectByPodIp": true,
      "defaultDindResources": {
        "requests": {
          "cpu": "390m",
          "memory": "256Mi"
        },
        "limits": {
          "cpu": "2500m",
          "memory": "4096Mi"
        }
      },
      "envVars": {},
      "volumeMounts": {
        "cf-certs-dind": {
          "name": "cf-certs-dind",
          "mountPath": "/etc/ssl/cf",
          "readOnly": true
        },
        "dind-config": {
          "name": "dind-config",
          "mountPath": "/etc/docker/daemon.json",
          "subPath": "daemon.json",
          "readOnly": true
        }
      },
      "volumes": {
        "cf-certs-dind": {
          "name": "cf-certs-dind",
          "secret": {
            "secretName": "codefresh-certs-server"
          }
        },
        "dind-config": {
          "name": "dind-config",
          "configMap": {
            "name": "codefresh-dind-config"
          }
        }
      },
      "tolerations": {
        "dind": {
          "key": "codefresh/dind",
          "operator": "Exists",
          "effect": "NoSchedule"
        }
      }
    },
    "isPublic": true,
    "nonComplete": true
  }
]
{{- end -}}