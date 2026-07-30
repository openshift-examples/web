terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }
}

provider "kubectl" {
  config_path = "kubeconfig-terraform"
  insecure    = true
}

variable "namespace" {
  default = "rbohne-kubevirt-terraform"
}

resource "kubectl_manifest" "rhel9_vm" {
  timeouts {
    create = "20m"
  }

  wait_for {
    field {
      key   = "status.printableStatus"
      value = "Running"
    }
  }

  yaml_body = yamlencode({
    apiVersion = "kubevirt.io/v1"
    kind       = "VirtualMachine"
    metadata = {
      name      = "rhel9"
      namespace = var.namespace
    }
    spec = {
      runStrategy = "Always"
      dataVolumeTemplates = [
        {
          metadata = {
            name = "rhel9-root"
          }
          spec = {
            storage = {
              accessModes = ["ReadWriteMany"]
              resources = {
                requests = {
                  storage = "30Gi"
                }
              }
            }
            sourceRef = {
              kind      = "DataSource"
              name      = "rhel9"
              namespace = "openshift-virtualization-os-images"
            }
          }
        }
      ]
      template = {
        metadata = {
          labels = {
            "kubevirt.io/vm" = "rhel9"
          }
        }
        spec = {
          domain = {
            cpu = {
              cores = 2
            }
            memory = {
              guest = "4Gi"
            }
            resources = {
              requests = {
                memory = "4Gi"
              }
            }
            devices = {
              disks = [
                {
                  name      = "root"
                  bootOrder = 1
                  disk = {
                    bus = "virtio"
                  }
                }
              ]
              interfaces = [
                {
                  name   = "coe"
                  model  = "virtio"
                  bridge = {}
                }
              ]
            }
          }
          networks = [
            {
              name = "coe"
              multus = {
                networkName = "coe-bridge"
              }
            }
          ]
          volumes = [
            {
              name = "root"
              dataVolume = {
                name = "rhel9-root"
              }
            }
          ]
        }
      }
    }
  })
}