## Install
```shell
docker pull ghcr.io/ittoyxk/freeswitch:latest
```

## Run
```shell
docker run -d --name freeswitch --ulimit core=-1 --network host --restart always ghcr.io/ittoyxk/freeswitch:latest
```