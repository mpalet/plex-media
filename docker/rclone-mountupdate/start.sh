#!/bin/bash

mkdir -p $RemoteMountPoint
mkdir -p $UnionMountPoint
mkdir -p $TempMountPoint
mkdir -p $ConfigDir

ConfigPath="$ConfigDir/$ConfigName"

function term_handler {
  kill -SIGTERM ${!} #kill last spawned background process
  echo "sending SIGTERM to child pid"
#  kill -SIGTERM "$pid_rclone"
#  wait "$pid_rclone"
  fuse_unmount
  rm -rf $TempMountPoint/*
  echo "exiting now"
#  kill $(jobs -p)
  exit $?
}

function fuse_unmount {
  echo "Unmounting: fusermount -u $RemoteMountPoint $(date +%Y.%m.%d-%T)"
  fusermount -u -z $RemoteMountPoint
  
  echo "Unmounting: fusermount -u $UnionMountPoint $(date +%Y.%m.%d-%T)"
  fusermount -u -z $UnionMountPoint
}

function mount_unionfs() {
  FUSE_OPT="-o default_permissions -o allow_other -o use_ino -o nonempty -o suid"
  UNION_OPT="-o cow -o noinitgroups"

  unionfs-fuse $FUSE_OPT $UNION_OPT $TempMountPoint=rw:$RemoteMountPoint=ro $UnionMountPoint
}


function inotify_loop {
  while inotifywait -r -e MOVED_TO "$TempMountPoint"; do
    pids=`jobs -p`
    for pid in $pids; do
      wait $pid
    done

    remote_update &
  done
}

function timer_update_loop {
  while true; do 
    remote_update
    sleep 300
  done
}

function remote_update {
  /usr/sbin/rclone -v --config $ConfigPath \
        move $TempMountPoint $RemotePath --exclude ".wh*" --exclude "*.partial~" --exclude "*~"
}

# SIGHUP is for cache clearing
trap term_handler SIGINT SIGTERM

echo "============================================="
echo "Mounting union $UnionMountPoint to $RemoteMountPoint and $TempMountPoint $(date +%Y.%m.%d-%T)"

mount_unionfs

inotify_loop &
timer_update_loop &


echo "============================================="
echo "Mounting $RemotePath to $RemoteMountPoint at $(date +%Y.%m.%d-%T)"

while true
do
  /usr/sbin/rclone --config $ConfigPath mount $RemotePath $RemoteMountPoint $MountCommands & wait ${!}
  echo "rclone crashed at: $(date +%Y.%m.%d-%T)"
  #  tail -f /dev/null & wait ${!}
  fuse_unmount
  #  sleep 1
done

exit 144
