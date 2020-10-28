# Quay & Clair

## Running Quay & Clair via podman

Here my lab setup, based on the official [documentation](https://access.redhat.com/documentation/en-us/red_hat_quay/3.2/).


### Prepare host machine

```bash
# Install necessary packages
yum install -y telnet podman tmux git make go dnsmasql

# Setup internal dns resolution via cni plugin dnsname
git clone https://github.com/containers/dnsname.git
cd dnsname
make binaries install PREFIX=/usr

# Load kernel module br_netfilter because of:
# https://bugzilla.redhat.com/show_bug.cgi?id=1703261
modprobe br_netfilter
```

!!! warning
    ToDo: `modprobe br_netfilter` is not persistant!!

#### Configure dnsname cni plugin for default podman network

Add dnsname plugin to cni plugin list `/etc/cni/net.d/87-podman-bridge.conflist`:

```bash
,{
         "type": "dnsname",
         "domainName": "dns.podman"
}
```

### Setup mysql

```bash
mkdir -p /var/lib/mysql
chmod 777 /var/lib/mysql
export MYSQL_CONTAINER_NAME=mysql
export MYSQL_DATABASE=enterpriseregistrydb
export MYSQL_PASSWORD=JzxCTamgFBmHRhcGFtoPHFkrx1BH2vwQ
export MYSQL_USER=quayuser
export MYSQL_ROOT_PASSWORD=L36PrivxRB02bqOB9jtZtWiCcMsApOGn

cat - > /etc/systemd/system/mysql.service <<EOF
[Unit]
Description=MySQL Pod
After=network.target

[Service]
Type=simple
TimeoutStartSec=5m

ExecStartPre=-/usr/bin/podman rm ${MYSQL_CONTAINER_NAME}
ExecStartPre=/usr/bin/podman pull registry.access.redhat.com/rhscl/mysql-57-rhel7
ExecStart=/usr/bin/podman run --name ${MYSQL_CONTAINER_NAME} --net host \
  --env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
  --env MYSQL_USER=${MYSQL_USER} \
  --env MYSQL_PASSWORD=${MYSQL_PASSWORD} \
  --env MYSQL_DATABASE=${MYSQL_DATABASE} \
  -v /var/lib/mysql:/var/lib/mysql/data:Z \
  --privileged=true \
  registry.access.redhat.com/rhscl/mysql-57-rhel7

ExecReload=-/usr/bin/podman stop ${MYSQL_CONTAINER_NAME}
ExecReload=-/usr/bin/podman rm ${MYSQL_CONTAINER_NAME}
ExecStop=-/usr/bin/podman stop ${MYSQL_CONTAINER_NAME}
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF


```

### Setup redis

```bash
mkdir -p /var/lib/redis
chmod 777 /var/lib/redis

cat - > /etc/systemd/system/redis.service <<EOF
[Unit]
Description=MySQL Pod
After=network.target

[Service]
Type=simple
TimeoutStartSec=5m

ExecStartPre=-/usr/bin/podman rm redis
ExecStartPre=/usr/bin/podman pull registry.access.redhat.com/rhscl/redis-32-rhel7
ExecStart=/usr/bin/podman run --name redis --net host \
  -v /var/lib/redis:/var/lib/redis/data:Z \
  --privileged=true \
  registry.access.redhat.com/rhscl/redis-32-rhel7

ExecReload=-/usr/bin/podman stop redis
ExecReload=-/usr/bin/podman rm redis
ExecStop=-/usr/bin/podman stop redis
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF


systemctl enable --now redis
systemctl status redis
```


### Create auth.json

https://access.redhat.com/solutions/3533201

Create `auth.json` with credentials to pull quay & clair images

### Run quay configurator

```bash
podman pull  --authfile=auth.json quay.io/redhat/quay:v3.3.1
podman run --privileged=true -p 8443:8443 -d quay.io/redhat/quay:v3.3.1 config eemiTh0see3Iegoh
```

Configure quay ;-\)

!!! info
    ToDo: Add a screenshot

### Run quay

```bash
mkdir /var/lib/libvirt/images/quay/{config,storage}
chmod 777 /var/lib/libvirt/images/quay/{config,storage}


# Put the quay configuration bundle into /var/lib/quay-config
echo "TODO - Put the quay configuration bundle into /var/lib/quay-config"

tar xzvf quay-config.tar.gz -C /var/lib/libvirt/images/quay/config/

cat - > /etc/systemd/system/quay.service <<EOF
[Unit]
Description=Quay
After=network.target

[Service]
Type=simple
TimeoutStartSec=5m

ExecStartPre=-/usr/bin/podman rm quay
ExecStartPre=/usr/bin/podman pull --authfile=/var/lib/libvirt/images/quay/config/auth.json quay.io/redhat/quay:v3.3.1
ExecStart=/usr/bin/podman run --name quay -p 443:8443 -p 80:8080 \
  -v /var/lib/libvirt/images/quay/config:/conf/stack:Z \
  -v /var/lib/libvirt/images/quay/storage:/datastorage:Z \
  --privileged=true \
  quay.io/redhat/quay:v3.3.1

ExecReload=-/usr/bin/podman stop quay
ExecReload=-/usr/bin/podman rm quay
ExecStop=-/usr/bin/podman stop quay
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now quay

```

### Setup postgres for Clair

```bash
mkdir -p /var/lib/postgres
chmod 777 /var/lib/postgres
podman run -d --restart=always \
    --name postgres \
    -v /var/lib/postgres:/var/lib/postgresql/data:z \
    -e POSTGRES_PASSWORD="L36PrivxRB02bqOB9jtZtWiCcMsApOGn" \
    postgres

podman run --rm -e PGPASSWORD="L36PrivxRB02bqOB9jtZtWiCcMsApOGn" postgres \
   sh -c 'echo "create database clairtest" | psql -h postgres -U postgres'
```

### Setup Clair

```bash
mkdir -p /var/lib/clair-config
chmod 777 /var/lib/clair-config
```

#### Create config.yaml

##### config.yaml
```yaml
clair:
  database:
    type: pgsql
    options:
      # A PostgreSQL Connection string pointing to the Clair Postgres database.
      # Documentation on the format can be found at: http://www.postgresql.org/docs/9.4/static/libpq-connect.html
      #source: postgresql://postgres:L36PrivxRB02bqOB9jtZtWiCcMsApOGn@postgres:5432/clairtest?sslmode=disable
      source: postgresql://postgres:L36PrivxRB02bqOB9jtZtWiCcMsApOGn@postgres:5432/clairtest?sslmode=disable
      cachesize: 16384
  api:
    # The port at which Clair will report its health status. For example, if Clair is running at
    # https://clair.mycompany.com, the health will be reported at
    # http://clair.mycompany.com:6061/health.
    healthport: 6061

    port: 6062
    timeout: 900s

    # paginationkey can be any random set of characters. *Must be the same across all Clair instances*.
    paginationkey:

  updater:
    # interval defines how often Clair will check for updates from its upstream vulnerability databases.
    interval: 6h
    notifier:
      attempts: 3
      renotifyinterval: 1h
      http:
        # QUAY_ENDPOINT defines the endpoint at which Quay is running.
        # For example: https://myregistry.mycompany.com
        endpoint: https://quay.openshift.pub/secscan/notify
        proxy: http://localhost:6063

jwtproxy:
  signer_proxy:
    enabled: true
    listen_addr: :6063
    ca_key_file: /certificates/mitm.key # Generated internally, do not change.
    ca_crt_file: /certificates/mitm.crt # Generated internally, do not change.
    signer:
      issuer: security_scanner
      expiration_time: 5m
      max_skew: 1m
      nonce_length: 32
      private_key:
        type: autogenerated
        options:
          rotate_every: 12h
          key_folder: /clair/config/
          key_server:
            type: keyregistry
            options:
              # QUAY_ENDPOINT defines the endpoint at which Quay is running.
              # For example: https://myregistry.mycompany.com
              registry: https://quay.openshift.pub/keys/

  verifier_proxies:
  - enabled: true
    # The port at which Clair will listen.
    listen_addr: :6060

    # If Clair is to be served via TLS, uncomment these lines. See the "Running Clair under TLS"
    # section below for more information.
    # key_file: /clair/config/clair.key
    # crt_file: /clair/config/clair.crt

    verifier:
      # CLAIR_ENDPOINT is the endpoint at which this Clair will be accessible. Note that the port
      # specified here must match the listen_addr port a few lines above this.
      # Example: https://myclair.mycompany.com:6060
      audience: http://clair:6060

      upstream: http://localhost:6062
      key_server:
        type: keyregistry
        options:
          # QUAY_ENDPOINT defines the endpoint at which Quay is running.
          # Example: https://myregistry.mycompany.com
          registry: https://quay.openshift.pub/keys/
```

##### jwtproxy with preshared key

```yaml
jwtproxy:
  signer_proxy:
    enabled: true
    listen_addr: :6063
    ca_key_file: /certificates/mitm.key # Generated internally, do not change.
    ca_crt_file: /certificates/mitm.crt # Generated internally, do not change.
    signer:
      issuer: security_scanner
      expiration_time: 5m
      max_skew: 1m
      nonce_length: 32
      private_key:
        type: preshared
        options:
          # The ID of the service key generated for Clair. The ID is returned when setting up
          # the key in [Quay Setup](security-scanning.md)
          key_id: 9c663f02c9fa83cd0f6499b...............55a7f08593d21b776d58
          private_key_path: /clair/config/security_scanner.pem
```

#### Start Clair

```bash
podman pull  --authfile=auth.json quay.io/redhat/clair-jwt:v3.2.1
podman run -d --restart=always \
    --name clair \
    -v /var/lib/clair-config:/clair/config:z \
    -v /var/lib/quay-config/extra_ca_certs/ca.crt:/etc/pki/ca-trust/source/anchors/ca.crt:z  \
   quay.io/redhat/clair-jwt:v3.2.1
```

## How to force rescan all images at Quay

[https://access.redhat.com/solutions/3516081](https://access.redhat.com/solutions/3516081)

```bash
podman exec -ti mysql sh -c "echo 'UPDATE image SET security_indexed = false, security_indexed_engine = -1' | /opt/rh/rh-mysql57/root/usr/bin/mysql enterpriseregistrydb"
```

## Upstream Clair / play with cli

### Run postgre sql \(database for Clair\)

Optional, add volume for database: `--volume clair-postgres:/var/lib/postgresql/data`

```bash
docker run -ti --name clairdb -e POSTGRES_PASSWORD="asdf" -p 5432:5432 postgres:9.6
```

#### Discover the database:

```text
docker exec -ti clairdb bash
psql -U postgres

SELECT * FROM pg_catalog.pg_tables where schemaname not in ( 'pg_catalog','information_schema' );

postgres=# SELECT * FROM pg_catalog.pg_tables where schemaname not in ( 'pg_catalog','information_schema' );
 schemaname |              tablename               | tableowner | tablespace | hasindexes | hasrules | hastriggers | rowsecurity
------------+--------------------------------------+------------+------------+------------+----------+-------------+-------------
 public     | schema_migrations                    | postgres   |            | t          | f        | f           | f
 public     | layer                                | postgres   |            | t          | f        | t           | f
 public     | layer_diff_featureversion            | postgres   |            | t          | f        | t           | f
 public     | namespace                            | postgres   |            | t          | f        | t           | f
 public     | feature                              | postgres   |            | t          | f        | t           | f
 public     | featureversion                       | postgres   |            | t          | f        | t           | f
 public     | vulnerability_fixedin_feature        | postgres   |            | t          | f        | t           | f
 public     | vulnerability_affects_featureversion | postgres   |            | t          | f        | t           | f
 public     | keyvalue                             | postgres   |            | t          | f        | f           | f
 public     | lock                                 | postgres   |            | t          | f        | f           | f
 public     | vulnerability                        | postgres   |            | t          | f        | t           | f
 public     | vulnerability_notification           | postgres   |            | t          | f        | t           | f
(12 rows)


curl -I -X GET  http://localhost:6061/health
HTTP/1.1 200 OK
Server: clair
Date: Sun, 08 Mar 2020 19:50:25 GMT
Content-Length: 0


curl -L -O https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_amd64
chmod +x clair-scanner_linux_amd64



```

#### Run clair

Follow the [instructions.](https://github.com/quay/clair/blob/master/Documentation/running-clair.md#docker)

Run Clair health check

```text
$ curl -I -X GET  http://localhost:6061/health
HTTP/1.1 200 OK
Server: clair
Date: Sun, 08 Mar 2020 19:50:25 GMT
Content-Length: 0
```

### Run security scan against Clair form CLI

Source: [https://www.muspells.net/blog/2019/05/docker-image-scanner-for-vulnerabilities-with-clair/](https://www.muspells.net/blog/2019/05/docker-image-scanner-for-vulnerabilities-with-clair/)

```text
curl -L -O https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_amd64
chmod +x clair-scanner_linux_amd64

./clair-scanner_linux_amd64 docker.io/postgres:9.6
2020/03/10 13:18:12 [INFO] ▶ Start clair-scanner
2020/03/10 13:18:15 [INFO] ▶ Server listening on port 9279
2020/03/10 13:18:15 [INFO] ▶ Analyzing a05ecb27b9eb7ab8738107be1ce93cf76e6bbeaab3f7b391f0ba447e79e55a71
2020/03/10 13:18:15 [INFO] ▶ Analyzing 4c389e15e81cda3a5cb9783f2a5e4a94abcaad73ee8e0dbd4d250fcc83ef2dad
2020/03/10 13:18:15 [INFO] ▶ Analyzing a1a80525b5823b6b2c9a95849b5baade0d0404ad7fc483ec8f17986195fde818
2020/03/10 13:18:15 [INFO] ▶ Analyzing e91d09a2f1daf17b94a6ff41be462016777afb24a4a537e3a5efa9f7de4efd5d
2020/03/10 13:18:15 [INFO] ▶ Analyzing ddaaa2630f352e02639d6835a6f11b0058361766e758ea8876d2e90c6e709f08
2020/03/10 13:18:15 [INFO] ▶ Analyzing 19bbdaf3a1b3beebae93d01037fd94eade3cf2807d610c4e29a3134ddc067a3c
2020/03/10 13:18:15 [INFO] ▶ Analyzing be37444db6fb07848d4b4bcfd1299d656e73b5438be16a83aef6c115bfeb66b5
2020/03/10 13:18:15 [INFO] ▶ Analyzing 624e05ebecf1b951c797e43bad4e71c4f451f5633b7237e93a6149682d7e260b
2020/03/10 13:18:15 [INFO] ▶ Analyzing 7965ea0ac3e66aae3ffbacce7e19ffedbe27911a6b8bb279d3910292070dbfa4
2020/03/10 13:18:15 [INFO] ▶ Analyzing 52a9eb7357d108377b7203ae15eee20f1b895dc0fe60d505fc214f02f5810614
2020/03/10 13:18:15 [INFO] ▶ Analyzing 72e74df85e97178364980c97f6d3acadabb04e7fcc9b8c5d61d22bd3bb4c3416
2020/03/10 13:18:15 [INFO] ▶ Analyzing 6b4c521f1407b3b26cbb6d269013ed665db5e5c0be68d0f1c81a631be63f25d7
2020/03/10 13:18:15 [INFO] ▶ Analyzing 9f2254738e833333cbf4710c6522451a8f8444e7851cb636d4dfb415f8cb17af
2020/03/10 13:18:15 [INFO] ▶ Analyzing 7c01ba4da571b684dee273b91515846764ebfa0a103ae4eb528d8f4e2996e3f4
2020/03/10 13:18:15 [INFO] ▶ Image [docker.io/postgres:9.6] contains NO unapproved vulnerabilities

```

!!! warning
    Empty vulnerability database! It takes several minutes to fetch vulnerability data.

    During the first run, Clair will bootstrap its database with vulnerability data from the configured data sources. It can take several minutes before the database has been fully populated, but once this data is stored in the database, subsequent updates will take far less time.
    [Source](https://github.com/quay/clair/blob/master/Documentation/running-clair.md#troubleshooting)


Check vulnerability database: `docker exec -ti clairdb sh -c "echo 'SELECT count(*) FROM public.vulnerability;' | psql -U postgres"`

```bash
$ docker pull  quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer:latest
Trying to pull repository quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer ...
latest: Pulling from quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer
0a63a759fe25: Pull complete
9d6c79b335fa: Pull complete
b711aecef065: Pull complete
5309a652d757: Pull complete
619b1b067d5c: Pull complete
d451521d8812: Pull complete
8a9186768383: Pull complete
Digest: sha256:f05966a0266e8a42824655fc5b04565b275496195d56eb2c34a3c4b2d9e11765
Status: Downloaded newer image for quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer:latest
$ ./clair-scanner_linux_amd64  quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer:latest
2020/03/10 13:31:05 [INFO] ▶ Start clair-scanner
2020/03/10 13:31:08 [INFO] ▶ Server listening on port 9279
2020/03/10 13:31:08 [INFO] ▶ Analyzing ff9ceab5d534bc70fbf0a2b545a0882abcaba3df26689a468d946e3d61eb7d8e
2020/03/10 13:31:09 [INFO] ▶ Analyzing 28ba496308dd49d6951fd474c55d9dc108a59ea2bbc0c353ac84404ae991e4c8
2020/03/10 13:31:09 [INFO] ▶ Analyzing 69a0c7d6a422c095d83ab606ea056d1dd18003a430a76d81ec52f3b2c6634081
2020/03/10 13:31:09 [INFO] ▶ Analyzing 01eebed9a722e55a6921395a1a9593be6f075919584d0b669f91fd4c7330b1d3
2020/03/10 13:31:10 [INFO] ▶ Analyzing 038fefdaa677e22f9991cddcdc3b231214f7245fed3e3badcc3312978e09584f
2020/03/10 13:31:10 [INFO] ▶ Analyzing 5bab7dc8b42cfa559c8ac0a6b0c9c81c6474a0e0ae17cb78b507e18758cd277e
2020/03/10 13:31:10 [INFO] ▶ Analyzing da74271f3c0d74897a8b83405d84a66ac229d56a1344fb60f4095adb2978c914
2020/03/10 13:31:10 [INFO] ▶ Image [quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer:latest] contains NO unapproved vulnerabilities
```

```bash
./clair-scanner_linux_amd64 docker.io/postgres:9.6 | grep '\[INFO\]'
2020/03/10 13:33:36 [INFO] ▶ Start clair-scanner
2020/03/10 13:33:39 [INFO] ▶ Server listening on port 9279
2020/03/10 13:33:39 [INFO] ▶ Analyzing a05ecb27b9eb7ab8738107be1ce93cf76e6bbeaab3f7b391f0ba447e79e55a71
2020/03/10 13:33:39 [INFO] ▶ Analyzing 4c389e15e81cda3a5cb9783f2a5e4a94abcaad73ee8e0dbd4d250fcc83ef2dad
2020/03/10 13:33:39 [INFO] ▶ Analyzing a1a80525b5823b6b2c9a95849b5baade0d0404ad7fc483ec8f17986195fde818
2020/03/10 13:33:39 [INFO] ▶ Analyzing e91d09a2f1daf17b94a6ff41be462016777afb24a4a537e3a5efa9f7de4efd5d
2020/03/10 13:33:39 [INFO] ▶ Analyzing ddaaa2630f352e02639d6835a6f11b0058361766e758ea8876d2e90c6e709f08
2020/03/10 13:33:39 [INFO] ▶ Analyzing 19bbdaf3a1b3beebae93d01037fd94eade3cf2807d610c4e29a3134ddc067a3c
2020/03/10 13:33:39 [INFO] ▶ Analyzing be37444db6fb07848d4b4bcfd1299d656e73b5438be16a83aef6c115bfeb66b5
2020/03/10 13:33:39 [INFO] ▶ Analyzing 624e05ebecf1b951c797e43bad4e71c4f451f5633b7237e93a6149682d7e260b
2020/03/10 13:33:39 [INFO] ▶ Analyzing 7965ea0ac3e66aae3ffbacce7e19ffedbe27911a6b8bb279d3910292070dbfa4
2020/03/10 13:33:39 [INFO] ▶ Analyzing 52a9eb7357d108377b7203ae15eee20f1b895dc0fe60d505fc214f02f5810614
2020/03/10 13:33:39 [INFO] ▶ Analyzing 72e74df85e97178364980c97f6d3acadabb04e7fcc9b8c5d61d22bd3bb4c3416
2020/03/10 13:33:39 [INFO] ▶ Analyzing 6b4c521f1407b3b26cbb6d269013ed665db5e5c0be68d0f1c81a631be63f25d7
2020/03/10 13:33:39 [INFO] ▶ Analyzing 9f2254738e833333cbf4710c6522451a8f8444e7851cb636d4dfb415f8cb17af
2020/03/10 13:33:39 [INFO] ▶ Analyzing 7c01ba4da571b684dee273b91515846764ebfa0a103ae4eb528d8f4e2996e3f4
2020/03/10 13:33:39 [WARN] ▶ Image [docker.io/postgres:9.6] contains 112 total vulnerabilities
2020/03/10 13:33:39 [ERRO] ▶ Image [docker.io/postgres:9.6] contains 112 unapproved vulnerabilities
```

```bash
docker exec -ti clairdb sh -c "echo 'SELECT count(*) FROM public.vulnerability;' | psql -U postgres"
 count
--------
 152397
(1 row)
```

