#!/bin/bash

###### PULLING BACKUP SCRIPT ######
# Script for pulling Webfiles & Databases backups from FTP servers.
# For each server configured on ./config/servers folder, the script will download the last web & database backups. 
# Once done, if DELETE_BACKUPS_UPON_PULL is enabled, it will delete them from remote server.
# This script must be executed on final backup destination server.
# The server's configuration files, should contain the following env variables
# FTP_HOST=""
# FTP_USER=""
# FTP_PASSWORD=""
# FTP_PORT=

###### DEPENDENCIES
# ftp


###################################

# Backup script root directory.
SCRIPT_ROOT_DIRECTORY=`dirname "$0"`

# Include config file
source $SCRIPT_ROOT_DIRECTORY/config/config.sh

current=`date +%Y%m%d_%H%M`

for server_file in $SERVERS_DIRECTORY/*.sh; do
    source $server_file
    server_filename=$(basename -- "$server_file")
    server="${server_filename%.*}"

    echo "$current: Downloading $server"

    mkdir -p $TEMP_DIRECTORY/$server
    cd $TEMP_DIRECTORY/$server
    
    # Download every file in server backup directory.
    wget -r -nv -nH -nc -nd ftp://$FTP_USER:$FTP_PASSWORD@$FTP_HOST/$FTP_BACKUP_DIRECTORY/ 2>&1 | grep -i "failed\|error" 1>&2; 
    
    # Get wget exit code to check if there were any problems (although they should already be logged to stderr)
    wget_exit_code=${PIPESTATUS[0]}

    if [ "$wget_exit_code" -gt 0 ]; then
        echo "$current: Failed to download backup files from $server. WGET exit code: $get_exit_code"
        continue;
    fi

    download_count=`ls -l | wc -l`
    
    if [ "$download_count" -eq 0 ]; then
        echo "$current: No backup files were found at $server. Please check webhosting backup cronjob." 1>&2
        continue;
    fi

    for file in $TEMP_DIRECTORY/$server/*; do
        filesize=$(ls -l $file | awk '{print  $5}')
        filename=$(basename -- "$file")
        if [ "$filesize" -lt $MINIMUM_FILESIZE_ERROR ]; then
            echo "$current: File $filename downloaded from server $server is too small (lower than $MINIMUM_FILESIZE_ERROR bytes). Please check webhosting backup cronjob." 1>&2
        fi
        md5=$(md5sum $file)

        echo "$current: Downloaded file $filename from $server. Checksum: $md5"

        mv $file $FINAL_BACKUP_DIRECTORY/
    done

    ## Delete downloaded files from FTP server.
done

## Download examples
    #curl -p - --insecure  "ftp://82.45.34.23:21/CurlPutTest/testfile.xml" --user "testuser:testpassword" -o "C:\test\testfile.xml" --ftp-create-dirs
    
    ## Delete
    #curl -p - --insecure  "ftp://82.45.34.23:21/CurlPutTest/testfile.xml" --user "testuser:testpassword" -Q "–DELE  /CurlPutTest/testfile.xml" --ftp-create-dirs

    #ftp -inv $FTP_HOST <<EOF
    #    user $FTP_USER $FTP_PASSWORD
    #    cd $FTP_ROOT/$REMOTE_BACKUP_DIRECTORY
    #    mget *
    #    bye
    #EOF
    #echo $server//$FTP_HOST:$FTP_PORT/$FTP_USER@$FTP_PASSWORD
    #wget -r -nH --cut-dirs=5 -nc ftp://user:pass@server//absolute/path/to/directory