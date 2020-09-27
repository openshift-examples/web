# vSphere IPI & Proxy

!!! info
    **vCenter must be reachable directly**
    the connection does not go through the proxy.

## Install vCenter root ca

```
curl -k -L -O  https://vcenter/certs/download.zip
unzip download.zip
cp -v certs/lin/*  /etc/pki/ca-trust/source/anchors/
update-ca-trust
```

## **Optional** Reverse proxy for vCenter in a different Network

 * Install nginx
 * [Create certificates](/certificate/#general-own-root-ca-and-certificate)

Nginx configuration:
```
http {
  proxy_set_header            Host            $http_host;
  proxy_set_header            X-Real-IP       $remote_addr;
  proxy_set_header            X-Forwared-For  $proxy_add_x_forwarded_for;

  upstream vcsa-443 {
    server vcenter.mycomp.com:443;
  }

  server {
    listen        80;
    server_name   vcenter.openshift.pub;

    location / {
      allow all;
      return 302 https://$server_name$request_uri;
    }
  }
  server {
    listen        443 ssl;
    server_name   vcenter.openshift.pub;

    ssl_certificate  /etc/nginx/cert-crt.pem;
    ssl_certificate_key  /etc/nginx/cert-key.pem;
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers    HIGH:!aNULL:!MD5;
    keepalive_timeout 60;

    location / {
      allow all;
      proxy_set_header Host $http_host;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_pass https://vcsa-443;
    }
  }
}
```

## Prepare install config

Via `openshift-install create install-config --dir=config`

Please don't forget to add the proxy!

### Example install-config.yaml

```yaml
apiVersion: v1
baseDomain: openshift.pub
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 3
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 3
metadata:
  creationTimestamp: null
  name: vde
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  vsphere:
    apiVIP: 172.16.0.15
    cluster: vmware-cluster
    datacenter: DC
    defaultDatastore: datastore
    ingressVIP: 172.16.0.16
    network: VM Network
    password: xxxxx
    username: ocp-account
    vCenter: vcenter.example.de
    folder: /DC/vm/rbohne/                        <===== Added
publish: External
proxy:                                            <===== Added
  httpProxy: http://172.16.0.1:3128/              <===== Added
  httpsProxy: http://172.16.0.1:3128/             <===== Added
sshKey: "....."                                   <===== Added
pullSecret: '{"auths":{"cloud.openshift.com":....'
```

Here all details about install-config.yaml

```
openshift-install explain installconfig.platform.vsphere
KIND:     InstallConfig
VERSION:  v1

RESOURCE: <object>
  VSphere is the configuration used when installing on vSphere.

FIELDS:
    apiVIP <string>
      APIVIP is the virtual IP address for the api endpoint

    cluster <string>
      Cluster is the name of the cluster virtual machines will be cloned into.

    clusterOSImage <string>
      ClusterOSImage overrides the url provided in rhcos.json to download the RHCOS OVA

    datacenter <string> -required-
      Datacenter is the name of the datacenter to use in the vCenter.

    defaultDatastore <string> -required-
      DefaultDatastore is the default datastore to use for provisioning volumes.

    defaultMachinePlatform <object>
      DefaultMachinePlatform is the default configuration used when installing on VSphere for machine pools which do not define their own platform configuration.

    folder <string>
      Folder is the absolute path of the folder that will be used and/or created for virtual machines. The absolute path is of the form /<datacenter>/vm/<folder>/<subfolder>.

    ingressVIP <string>
      IngressVIP is the virtual IP address for ingress

    network <string>
      Network specifies the name of the network to be used by the cluster.

    password <string> -required-
      Password is the password for the user to use to connect to the vCenter.

    username <string> -required-
      Username is the name of the user to use to connect to the vCenter.

    vCenter <string> -required-
      VCenter is the domain name or IP address of the vCenter.

```
