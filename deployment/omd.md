# OMD on OpenShift

{% embed url="https://labs.consol.de/omd/" %}

Based on:

{% embed url="https://github.com/ConSol/omd-labs-docker.git" %}



#### Prepare project

```text
oc new-project monitoring
oc adm policy add-scc-to-user anyuid -z default
```

#### Deploy template

```javascript
{
    "kind": "Template",
    "apiVersion": "v1",
    "metadata": {
        "name": "omd",
        "creationTimestamp": null,
        "annotations": {
            "description": "omd",
            "iconClass": "icon-tomcat",
            "tags": "tomcat,tomcat7,java,jboss,xpaas,autoscaling,omd",
            "version": "0.0.1"
        }
    },
    "objects": [
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
                      "dockerStrategy": {},
                      "type": "Docker"
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
            "kind": "Service",
            "apiVersion": "v1",
            "spec": {
                "ports": [
                    {
                        "name": "http",
                        "port": 80,
                        "targetPort": 80
                    },
                    {
                        "name": "https",
                        "port": 443,
                        "targetPort": 443
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
                    "description": "The web server's https port."
                }
            }
        },
        {
            "kind": "Route",
            "apiVersion": "v1",
            "id": "${APPLICATION_NAME}-https",
            "metadata": {
                "name": "${APPLICATION_NAME}",
                "labels": {
                    "application": "${APPLICATION_NAME}"
                },
                "annotations": {
                    "description": "Route for application's https service."
                }
            },
            "spec": {
                "host": "${HOSTNAME_HTTPS}",
                "to": {
                    "kind": "Service",
                    "name": "${APPLICATION_NAME}"
                },
                "port": {
                    "targetPort": "https"
                },
                "tls": {
                    "termination": "passthrough"
                },
                "wildcardPolicy": "None"
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
                                "securityContext": { "anyuid": true },
                                "imagePullPolicy": "Always",
                                "ports": [
                                    {
                                        "name": "https",
                                        "containerPort": 443,
                                        "protocol": "TCP"
                                    },
                                    {
                                        "name": "http",
                                        "containerPort": 80,
                                        "protocol": "TCP"
                                    },
                                    {
                                        "name": "ssh",
                                        "containerPort": 22,
                                        "protocol": "TCP"
                                    },
                                    {
                                        "name": "gearmand",
                                        "containerPort": 4730,
                                        "protocol": "TCP"
                                    },
                                    {
                                        "name": "nrpe",
                                        "containerPort": 5666,
                                        "protocol": "TCP"
                                    }
                                ]
                            }
                        ]
                    }
                }
            }
        }
    ],
    "parameters": [
        {
            "name": "APPLICATION_NAME",
            "description": "The name for the application.",
            "value": "omd",
            "required": true
        },
        {
            "name": "HOSTNAME_HTTPS",
            "description": "Custom hostname for https service route.  Leave blank for default hostname, e.g.: \u003capplication-name\u003e-\u003cproject\u003e.\u003cdefault-domain-suffix\u003e"
        },
        {
            "name": "SOURCE_REPOSITORY_URL",
            "description": "Git source URI for application",
            "value": "https://github.com/ConSol/omd-labs-docker.git",
            "required": true
        },
        {
            "name": "SOURCE_REPOSITORY_REF",
            "description": "Git branch/tag reference",
            "value": "usermod-github-204-docker-cloud"
        },
        {
            "name": "CONTEXT_DIR",
            "description": "Path within Git project to build; empty for root project directory.",
            "value": "omd-labs-centos"
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
        "template": "omd"
    }
}
```

#### Deploy OMD

```text
oc process omd | oc create -f -
```

