#!/bin/bash

# Output colors
NORMAL="\\033[0;39m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"

#load variables
source .env


log() {
  echo "$BLUE > $1 $NORMAL"
}

error() {
  echo ""
  echo "$RED >>> ERROR - $1$NORMAL"
}

help() {
  echo "-----------------------------------------------------------------------"
  echo "                      Available commands                              -"
  echo "-----------------------------------------------------------------------"
  echo -e -n "$BLUE"
  echo "   > stop - To stop containers"
  echo "   > start - To start containers"
  echo "   > help - Display this help"
  echo -e -n "$NORMAL"
  echo "-----------------------------------------------------------------------"

}

start() {
#  fix-permissions
  mount_aufs
  docker-compose up -d
}

stop() {
  docker-compose down
  umount $UNION_PATH
}

mount_aufs() {
  mkdir -p $TMP_PATH
  mkdir -p $REMOTE_PATH
  mkdir -p $UNION_PATH

  mount -t aufs -o br=$TMP_PATH=rw:$REMOTE_PATH=ro -o udba=reval none $UNION_PATH  
}

mount_unionfs() {
  FUSE_OPT="-o default_permissions -o allow_other -o use_ino -o nonempty -o suid"
  UNION_OPT="-o cow -o noinitgroups"

  mkdir -p $TMP_PATH
  mkdir -p $REMOTE_PATH
  mkdir -p $UNION_PATH

  unionfs-fuse $FUSE_OPT $UNION_OPT $TMP_PATH=rw:$REMOTE_PATH=ro $UNION_PATH
}

fix-permissions() {
  chown -R www-data:www-data nextcloud/apps nextcloud/cache nextcloud/config
  chown -R 999:999 nextcloud/db
  chmod -R 700 nextcloud/apps nextcloud/cache nextcloud/config nextcloud/db
}

#execute literal arguments
$@
