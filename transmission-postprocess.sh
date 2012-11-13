#!/bin/bash
#
# Jakob Hilarius <http://syscall.dk>, 2012
#
# Modify settings.json
#
# "script-torrent-done-enabled": true,
# "script-torrent-done-filename": "/path/to/transmission-postprocess.sh",
#

DIR="${TR_TORRENT_DIR}/${TR_TORRENT_NAME}/"
cd "$DIR"
/usr/local/bin/unrar e "$DIR/*.rar" > unrar.log

#transmission-remote -n $TR_USERNAME:$TR_PASSWORD -t$TR_TORRENT_ID --remove-and-delete