#!/bin/bash
#
# Jakob Hilarius Nielsen <http://syscall.dk>, 2012
#
# Simple script for recursively finding subtitles using Periscope.
##

MAX_TRIES=3

FILES=$(find . -type f | egrep "avi$|mkv$|mp4$|m4v$")

for f in $FILES
do
    filename=$(basename $f)
    path=$(dirname $f)
    
    extension="${filename##*.}"
    filename="${filename%.*}"
    
    if [[ ! -e "$path/$filename.srt" ]]; then
        config="$path/.$filename.subleech"
        $(touch $config)
        tries=$(cat $config | tr -d ' ')
        
        if [[ $tries < $MAX_TRIES ]]; then
            # TODO: exec periscope
            echo $filename
        fi
        
        tries=$(($tries+1))
        $(echo $tries > $config)
    fi
done