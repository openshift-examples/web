# Hetzner Storage Box

For all example we use `HETZNER_STORAGE_USERNAME` and `HETZNER_STORAGE_PASSWORD` environment variables.

```bash
export HETZNER_STORAGE_USERNAME=..
export HETZNER_STORAGE_PASSWORD=..
```

## via WebDav

|Action|Command|
|---|---|
|List|`curl -u ${HETZNER_STORAGE_USERNAME}:${HETZNER_STORAGE_PASSWORD} https://${HETZNER_STORAGE_USERNAME}.your-storagebox.de/`|
|Upload|`curl -u ${HETZNER_STORAGE_USERNAME}:${HETZNER_STORAGE_PASSWORD}  -T '/path/to/local/file.txt' https://${HETZNER_STORAGE_USERNAME}.your-storagebox.de/`|

## via SFTP

```bash
sftp -P 23 ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de
```

## via rsync

```
rsync --progress -e 'ssh -p23' --recursive ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de:homer/root/hetzner-ocp4 /root/

rsync --progress -e 'ssh -p23' --recursive ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de:homer/root/hetzner-ocp4 /root/

rsync --progress -e 'ssh -p23' --recursive ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de:homer/images /var/lib/libvirt/images

rsync --progress -e 'ssh -p23' --recursive ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de:homer/root/cka /var/lib/libvirt/images
```

## Backup example

Setup SSH key-auth: https://docs.hetzner.com/de/robot/storage-box/backup-space-ssh-keys/

```bash
echo -e "mkdir /.ssh \n chmod 700 .ssh \n put /root/.ssh/id_rsa.pub .ssh/authorized_keys \n chmod 600 .ssh/authorized_keys" | sftp -P 23 ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de
```

Prep for backup
```bash
echo -e "mkdir $(hostname)" | sftp -P 23 ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de
```

Run backup

```bash
rsync --progress -e 'ssh -p23' --recursive \
  --exclude '.vscode-server' \
  --exclude '.cache' \
  --exclude '.kube/cache' \
  /root \
  ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de:$(hostname)-$(date +%F)
```


### Restore

```bash
# Select backup
$ echo -e "ls"  | sftp -P 23 ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de
sftp> ls
homer               host01              host01-2020-12-18

$ export RESTORE_FROM=host01-2020-12-18

$ rsync --progress -e 'ssh -p23' --recursive \
  --exclude '.vscode-server' \
  --exclude '.cache' \
  --exclude '.ssh/authorized_keys' \
  ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de:${RESTORE_FROM}/root/ \
  /root/
```


## Partial restore:

Rsync filter example:
```
"*"         means everything
"dir1"      transfers empty directory [dir1]
"dir*"      transfers empty directories like: "dir1", "dir2", "dir3", etc...
"file*"     transfers files whose names start with [file]
"dir**"     transfers every path that starts with [dir] like "dir1/file.txt", "dir2/bar/ffaa.html", etc...
"dir***"    same as above
"dir1/*"    does nothing
"dir1/**"   does nothing
"dir1/***"  transfers [dir1] directory and all its contents like "dir1/file.txt", "dir1/fooo.sh", "dir1/fold/baar.py", etc...
```

The exclude and include order is very important!

### SSH Keys only
```bash
export RESTORE_FROM=host01-2020-12-18
rsync --progress -avz -e 'ssh -p23' --recursive \
  --exclude='known_hosts' \
  --exclude='authorized_keys' \
  --include='.ssh**' \
  --exclude='*' \
  ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de:${RESTORE_FROM}/root/ \
  /root/

chown -R root:root ~
chmod -R 600 ~/.ssh/

```

### Cluster-configs
```bash
export RESTORE_FROM=host01-2020-12-18
rsync --progress -avz -e 'ssh -p23' --recursive  \
  --include='hetzner-ocp4/cluster.yml' \
  --include='hetzner-ocp4/cluster-*.yaml' \
  --include='hetzner-ocp4/' \
  --exclude='*' \
  ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de:${RESTORE_FROM}/root/ \
  /root/
```

## Create mirror of mirror.openshift.pub


```
export

OCP Mirrror:

export HETZNER_STORAGE_USERNAME=u221214-sub5
export HETZNER_STORAGE_PASSWORD=2a51mq474OG2Lo6b

sftp -P 23 ${HETZNER_STORAGE_USERNAME}@${HETZNER_STORAGE_USERNAME}.your-storagebox.de

mkdir -p https://mirror.openshift.com/pub/openshift-v4/clients/ocp
mkdir -p openshift-v4/dependencies/rhcos
mkdir -p openshift-v4/clients/helm


your-storagebox.de

curl -T '/path/to/local/file.txt' 'https://example.com/test/'

curl -XGET -u $HUSER:$HPASS https://${HUSER}.your-storagebox.de/

curl -XGET -u $HUSER:$HPASS https://${HUSER}.your-storagebox.de/
```

export CLIENT=4.6.1
export RHCOS=4.6.1


wget --mirror
  https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${CLIENT}/openshift-install-linux-${CLIENT}.tar.gz
  https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${CLIENT}/openshift-install-linux-${CLIENT}.tar.gz
openshift-client-linux-4.6.1.tar.gz)