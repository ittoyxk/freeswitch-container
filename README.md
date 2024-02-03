## Install
```shell
docker pull ghcr.io/ittoyxk/freeswitch:v1.10.11
```

## Run
```shell
docker run -d --name freeswitch --ulimit core=-1 --network host --restart always ghcr.io/ittoyxk/freeswitch:v1.10.11
```