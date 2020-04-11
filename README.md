# docker-plexdrive-encfs

Docker image for [plexdrive](https://github.com/plexdrive/plexdrive) mount
- Ubuntu 18.04
- pooling filesystem (with encfs + unionfs)

## Usage

```yaml
version: '3'

services:
  plexdrive:
    container_name: plexdrive
    image: ghtsto/plexdrive-encfs
    restart: always
    network_mode: "bridge"
    volumes:
      - ${DATA_DIR}/plexdrive/config:/config
      - ${DATA_DIR}/plexdrive/cache:/cache
      - ${DATA_DIR}/plexdrive/data:/data:shared
      - ${DATA_DIR}/plexdrive/local-encrypted:/local
      - ${DATA_DIR}/plexdrive/encfs.xml:/encfs.xml
      - ${DATA_DIR}/plexdrive/encfspass:/encfspass
    privileged: true
    devices:
      - /dev/fuse
    cap_add:
      - MKNOD
      - SYS_ADMIN
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - PLEXDRIVE_OPTS=${PLEXDRIVE_OPTS}
```

First, up and run your container as above. It will be waiting for two plexdrive configuration files to be ready. You can create those files using built-in script by

```bash
docker-compose exec <service_name> plexdrive_setup
```

Once you finish typing your API token, shell stops responding. No worries, it is expected. Simply escape by ```Ctrl+C```, and go to ```/config```. You will find two json files generated. Container running in background will proceed to execute mounting command for plexdrive.

Once google drive contents are mounted with plexdrive, the container will mount decrypted remote and local directories then mount a merged directory which is accessible at ```${DATA_DIR}/plexdrive/data```.

### plexdrive mount

Here is the internal command for plexdrive mount.

```bash
plexdrive mount /cloud \
    -c /config/ \
    --cache-file=/cache/cache.bolt \
    --uid=${PUID:-911} \
    --gid=${PGID:-911} \
    --umask=022 \
    -o allow_other \
    ${PLEXDRIVE_OPTS}
```

Variables with capital letters are only configurable by the container environment variable.

| ENV  | Description  | Default  |
|---|---|---|
| ```PUID``` / ```PGID```  | uid and gid for running an app  | ```911``` / ```911```  |
| ```TZ```  | timezone, required for correct timestamp in log  |   |
| ```PLEXDRIVE_OPTS```  | additioanl arguments which will be appended to the basic options  |   |

After plexdrive mounts /cloud, encfs is used to create decrypted mounts of /cloud and /local
```bash
ENCFS6_CONFIG="/encfs.xml" /usr/bin/encfs -v --extpass="/bin/cat /encfspass" /cloud /data-decrypted
ENCFS6_CONFIG="/encfs.xml" /usr/bin/encfs -v --extpass="/bin/cat /encfspass" /local /local-decrypted
```

```bash
unionfs \
    -o uid=${PUID:-911},gid=${PGID:-911},umask=022,allow_other \
    -o ${UFS_USER_OPTS} \
    /local-decrypted=RW:/data-decrypted=RO /data
```
where a default value of ```UFS_USER_OPTS``` is

```bash
UFS_USER_OPTS="cow,direct_io,nonempty,auto_cache,sync_read"
```
