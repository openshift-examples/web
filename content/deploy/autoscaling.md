---
title: POD Autoscaling
linktitle: POD Autoscaling
weight: 6300
description: TBD
---
# POD Autoscaling

## Setup cpu based autoscaling

```text
oc process -f pod_autoscaling_template.json  | oc create -f -
```

[pod_autoscaling_template.json](pod_autoscaling_template.json)
```json
{
    "kind": "Template",
    "apiVersion": "v1",
    "metadata": {
        "name": "pod-autoscaling-example",
        "creationTimestamp": null,
        "annotations": {
            "description": "Pod Autoscaling exmaple with Chaos Professor",
            "iconClass": "icon-tomcat",
            "tags": "tomcat,tomcat7,java,jboss,xpaas,autoscaling,chaos-professor",
            "version": "0.0.1"
        }
    },
    "objects": [
        {
            "kind": "ImageStream",
            "apiVersion": "v1",
            "metadata": {
                "name": "redhat-openjdk18-openshift"
            },
            "spec": {
                "dockerImageRepository": "registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift",
                "tags": [
                    {
                        "name": "1.0",
                        "annotations": {
                            "description": "OpenJDK S2I images.",
                            "iconClass": "icon-jboss",
                            "tags": "builder,java,xpaas",
                            "supports":"java:8,xpaas:1.0",
                            "sampleRepo": "https://github.com/jboss-openshift/openshift-quickstarts",
                            "sampleContextDir": "undertow-servlet",
                            "version": "1.0"
                        }
                    }
                ]
            }
        },
        {
            "kind": "Service",
            "apiVersion": "v1",
            "spec": {
                "ports": [
                    {
                        "port": 8080,
                        "targetPort": 8080
                    }
                ],
                "selector": {
                    "deploymentConfig": "${APPLICATION_NAME}"
                }
            },
            "metadata": {
                "name": "${APPLICATION_NAME}",
                "labels": {
                    "application": "${APPLICATION_NAME}"
                },
                "annotations": {
                    "description": "The web server's http port."
                }
            }
        },
        {
            "kind": "Route",
            "apiVersion": "v1",
            "id": "${APPLICATION_NAME}-http",
            "metadata": {
                "name": "${APPLICATION_NAME}",
                "labels": {
                    "application": "${APPLICATION_NAME}"
                },
                "annotations": {
                    "description": "Route for application's http service."
                }
            },
            "spec": {
                "host": "${HOSTNAME_HTTP}",
                "to": {
                    "name": "${APPLICATION_NAME}"
                }
            }
        },
        {
            "kind": "ImageStream",
            "apiVersion": "v1",
            "metadata": {
                "name": "${APPLICATION_NAME}",
                "labels": {
                    "application": "${APPLICATION_NAME}"
                }
            }
        },
        {
            "kind": "BuildConfig",
            "apiVersion": "v1",
            "metadata": {
                "name": "${APPLICATION_NAME}",
                "labels": {
                    "application": "${APPLICATION_NAME}"
                }
            },
            "spec": {
                "source": {
                    "type": "Git",
                    "git": {
                        "uri": "${SOURCE_REPOSITORY_URL}",
                        "ref": "${SOURCE_REPOSITORY_REF}"
                    },
                    "contextDir": "${CONTEXT_DIR}"
                },
                "strategy": {
                    "type": "Source",
                    "sourceStrategy": {
                        "forcePull": true,
                        "from": {
                            "kind": "ImageStreamTag",
                            "name": "redhat-openjdk18-openshift:latest"
                        }
                    }
                },
                "output": {
                    "to": {
                        "kind": "ImageStreamTag",
                        "name": "${APPLICATION_NAME}:latest"
                    }
                },
                "triggers": [
                    {
                        "type": "GitHub",
                        "github": {
                            "secret": "${GITHUB_WEBHOOK_SECRET}"
                        }
                    },
                    {
                        "type": "Generic",
                        "generic": {
                            "secret": "${GENERIC_WEBHOOK_SECRET}"
                        }
                    },
                    {
                        "type": "ImageChange",
                        "imageChange": {}
                    },
                    {
                        "type": "ConfigChange"
                    }
                ]
            }
        },
        {
            "kind": "DeploymentConfig",
            "apiVersion": "v1",
            "metadata": {
                "name": "${APPLICATION_NAME}",
                "labels": {
                    "application": "${APPLICATION_NAME}"
                }
            },
            "spec": {
                "strategy": {
                    "type": "Recreate"
                },
                "triggers": [
                    {
                        "type": "ImageChange",
                        "imageChangeParams": {
                            "automatic": true,
                            "containerNames": [
                                "${APPLICATION_NAME}"
                            ],
                            "from": {
                                "kind": "ImageStream",
                                "name": "${APPLICATION_NAME}"
                            }
                        }
                    },
                    {
                        "type": "ConfigChange"
                    }
                ],
                "replicas": 1,
                "selector": {
                    "deploymentConfig": "${APPLICATION_NAME}"
                },
                "template": {
                    "metadata": {
                        "name": "${APPLICATION_NAME}",
                        "labels": {
                            "deploymentConfig": "${APPLICATION_NAME}",
                            "application": "${APPLICATION_NAME}"
                        }
                    },
                    "spec": {
                        "terminationGracePeriodSeconds": 60,
                        "containers": [
                            {
                                "name": "${APPLICATION_NAME}",
                                "image": "${APPLICATION_NAME}",
                                "imagePullPolicy": "Always",
                                "readinessProbe": {
                                    "failureThreshold": 3,
                                    "httpGet": {
                                        "path": "/",
                                        "port": 8080,
                                        "scheme": "HTTP"
                                    },
                                    "initialDelaySeconds": 25,
                                    "periodSeconds": 10,
                                    "successThreshold": 1,
                                    "timeoutSeconds": 1
                                },
                                "ports": [
                                    {
                                        "name": "jolokia",
                                        "containerPort": 8778,
                                        "protocol": "TCP"
                                    },
                                    {
                                        "name": "http",
                                        "containerPort": 8080,
                                        "protocol": "TCP"
                                    }
                                ],
                                "env": [
                                    {
                                        "name": "JWS_ADMIN_USERNAME",
                                        "value": "${JWS_ADMIN_USERNAME}"
                                    },
                                    {
                                        "name": "JWS_ADMIN_PASSWORD",
                                        "value": "${JWS_ADMIN_PASSWORD}"
                                    }
                                ]
                            }
                        ]
                    }
                }
            }
        },
        {
          "kind": "HorizontalPodAutoscaler",
          "apiVersion": "autoscaling/v1",
          "metadata": {
              "name": "${APPLICATION_NAME}",
              "labels": {
                  "application": "${APPLICATION_NAME}"
              }
          },
          "spec": {
              "scaleTargetRef": {
                  "kind": "DeploymentConfig",
                  "name": "${APPLICATION_NAME}",
                  "apiVersion": "v1",
                  "subresource": "scale"
              },
              "minReplicas": "${HorizontalPodAutoscaler_MIN_REPLICAS}",
              "maxReplicas": "${HorizontalPodAutoscaler_MAX_REPLICAS}",
              "cpuUtilization": {
                  "targetCPUUtilizationPercentage": "${HorizontalPodAutoscaler_CPU_TARGET_PERCENTAGE}"
              }
          }
      }
    ],
    "parameters": [
        {
            "name": "APPLICATION_NAME",
            "description": "The name for the application.",
            "value": "choas-professor",
            "required": true
        },
        {
          "name": "HorizontalPodAutoscaler_MIN_REPLICAS",
          "description": "HorizontalPodAutoscaler: min replicas",
          "value": "1",
          "required": true
        },
        {
          "name": "HorizontalPodAutoscaler_MAX_REPLICAS",
          "description": "HorizontalPodAutoscaler: max replicas",
          "value": "4",
          "required": true
        },
        {
          "name": "HorizontalPodAutoscaler_CPU_TARGET_PERCENTAGE",
          "description": "HorizontalPodAutoscaler: targetPercentage of cpuUtilization",
          "value": "60",
          "required": true
        },
        {
            "name": "HOSTNAME_HTTP",
            "description": "Custom hostname for http service route.  Leave blank for default hostname, e.g.: \u003capplication-name\u003e-\u003cproject\u003e.\u003cdefault-domain-suffix\u003e"
        },
        {
            "name": "SOURCE_REPOSITORY_URL",
            "description": "Git source URI for application",
            "value": "https://github.com/ConSol/chaos-professor.git",
            "required": true
        },
        {
            "name": "SOURCE_REPOSITORY_REF",
            "description": "Git branch/tag reference",
            "value": "master"
        },
        {
            "name": "CONTEXT_DIR",
            "description": "Path within Git project to build; empty for root project directory.",
            "value": ""
        },
        {
            "name": "GITHUB_WEBHOOK_SECRET",
            "description": "GitHub trigger secret",
            "generate": "expression",
            "from": "[a-zA-Z0-9]{8}",
            "required": true
        },
        {
            "name": "GENERIC_WEBHOOK_SECRET",
            "description": "Generic build trigger secret",
            "generate": "expression",
            "from": "[a-zA-Z0-9]{8}",
            "required": true
        }
    ],
    "labels": {
        "template": "jws30-tomcat7-basic-s2i",
        "xpaas": "1.2.0"
    }
}

```

## Test autoscaling

```text
# Only 4fun
ab 'http://choas-professor-omd.paas.osp.consol.de/chaos-professor-0.0.1/chaos/heapheap?size=500&time=10000'
ab 'http://choas-professor-omd.paas.osp.consol.de/chaos-professor-0.0.1/chaos/cpu?threads=100&keepAlive=20000'
ab -c 10 -n 100 'http://choas-professor-omd.paas.osp.consol.de/chaos-professor-0.0.1/chaos/cpu?threads=100&keepAlive=200'
```

## Delete all

```text
oc get all -o name | xargs -n1  oc delete
oc delete hpa/choas-professor
```

