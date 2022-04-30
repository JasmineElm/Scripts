#!/usr/bin/env bash

###  DEBUG          ###########################################################
set -u -e -o errtrace -o pipefail
trap "echo ""errexit: line $LINENO. Exit code: $?"" >&2" ERR
IFS=$'\n\t'

###  DESCRIPTION    ###########################################################
# backup $HOME, and /etc to a cloud provider  to be run as root
# Depends on `rclone`: 
#   curl https://rclone.org/install.sh | sudo bash
###  VARIABLES      ###########################################################

_FULL_PATH="$(realpath "${0}")"
_PATH=${_FULL_PATH%/*}
_FULL_FN=${_FULL_PATH##*/}
_EXT=${_FULL_FN##*.}
_FN=${_FULL_FN%.*}
_logfile=$_PATH/$_FN.log

_HSTNM=$(hostname)
_DTSTR=$(date +%y%m%d-%H)
_LOCAL="/storage/" # where do you want the backup saving?
_BKUPS="backups"   # backup directory name
_PRMRY="pcloud"    # primary cloud provider (hot backup)
_SCNDY="google"    # secondary cloud provider (cold backup)
_SNPNM="$_HSTNM-$_DTSTR.tar.gz" # snapshot name

###  FUNCTIONS      ###########################################################

function _hot_copy {
  rclone copy   -v $_LOCAL$_BKUPS/ $_PRMRY:$_BKUPS
  rclone delete -v --min-age 2d    $_PRMRY:$_BKUPS --include $_HSTNM
}

function _cold_copy {
  rclone copy   -v $_LOCAL$_BKUPS/ $_SCNDY:$_BKUPS
  rclone delete -v --min-age 14d   $_SCNDY:$_BKUPS --include $_HSTNM
}

function _clear_local {
  find $_LOCAL$_BKUPS -iname "$(hostname)*" -mtime +1 -delete;
}

function _backup {
  _hot_copy
  _cold_copy
  _clear_local
}


function _snapshot {
  tar cvfz $_LOCAL$_BKUPS/$_SNPNM \
    --exclude={"/storage","/bin","/boot","/dev","/lib","/lib32","/lib64"} \
    --exclude={"/libx32","lost+found","/media","/mnt","/opt","/proc","/usr"} \
    --exclude={"/root","/run","/sbin","/snap","srv","/sys","/tmp","/var"} \
    --exclude={"*ropbox*","Downloads",".cache",".mozilla",".vscode",".local"} \
    --exclude={"Trash","Cache*","gems","*otero","*git","*bsidian","plugged"} \
    --exclude={"Code",".npm","ale",".bundle"} /
}

_main() {
  _snapshot
  _backup
}

_main
