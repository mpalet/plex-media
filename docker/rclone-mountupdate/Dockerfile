FROM debian:stable-slim

ENV GOPATH="/go" \
    RemotePath="remote:" \
    RemoteMountPoint="/data_remote" \
    UnionMountPoint="/data" \
    TempMountPoint="/data_temp" \
    ConfigDir="/config" \
    ConfigName=".rclone.conf" \
    MountCommands="--allow-other --allow-non-empty"

## Debian with Go Git
RUN apt-get update && apt-get -y install unionfs-fuse golang-go git fuse inotify-tools \
	&& go get -u -v github.com/ncw/rclone \
	&& cp /go/bin/rclone /usr/sbin/ \
	&& rm -rf /go \
	&& apt-get -y remove golang-go git \
        && apt-get -y autoremove \
	&& rm -rf /tmp/* /var/cache/apt/* /var/lib/apt/lists/*

ADD start.sh /start.sh
RUN chmod +x /start.sh 

#VOLUME [$AccessFolder]

CMD ["/start.sh"]

# Use this args in docker run
# --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor:unconfined
# -v /path/to/config/.rclone.conf:/config/.rclone.conf
# -v /mnt/mediaefs:/mnt/mediaefs:shared
