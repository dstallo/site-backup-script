#!/bin/bash

###### PULLING BACKUP SCRIPT ######
# Script for pulling Webfiles & Databases backups from FTP servers.

# Backup script root directory.
SCRIPT_ROOT_DIRECTORY=`dirname "$0"`

# Include config file
source $SCRIPT_ROOT_DIRECTORY/config/config.sh

# Log functions
function echolog() {
    echo "$(date -u): $1" >> $LOG_FILE
}

function echoerror() {
    echo "$(date -u): $1" >> $ERROR_FILE
}

echolog "Backup pulling script started"
start_time=$SECONDS

# Run through server configuration files on $SERVERS_DIRECTORY.
for server_file in $SERVERS_DIRECTORY/*.sh; do
    source $server_file
    server_filename=$(basename -- "$server_file")
    server="${server_filename%.*}"

    echolog "Downloading folder /$FTP_BACKUP_DIRECTORY on server $server"

    # Create folder for server files.
    mkdir -p $TEMP_DIRECTORY/$server

    wget_exit_code=0
    
    # Download every file in server backup directory.
    wget_error=$(wget -r -nv -nH -nc -nd -P $TEMP_DIRECTORY/$server ftp://$FTP_USER:$FTP_PASSWORD@$FTP_HOST/$FTP_BACKUP_DIRECTORY/ 2>&1) || wget_exit_code=$?;
    
    # Check if wget exit code 
    if [ "$wget_exit_code" -gt 0 ]; then
        echoerror "Failed to download backup files from $server."
        echoerror "WGET exit code: $wget_exit_code"
        echoerror "WGET error message: $wget_error"
        continue;
    fi

    download_count=`ls -l | wc -l`
    
    # Check downloaded file count (alert on 0)
    if [ "$download_count" -eq 0 ]; then
        echoerror "No backup files were found at $server. Please check webhosting backup cronjob."
        continue;
    fi

    # Run for each downloaded file
    for file in $TEMP_DIRECTORY/$server/*; do
        filesize=$(ls -l $file | awk '{print $5}')
        filename=$(basename -- "$file")

        # Check minimum file size
        if [ "$filesize" -lt $MINIMUM_FILESIZE_ERROR ]; then
            echoerror "File $filename downloaded from server $server is too small (lower than $MINIMUM_FILESIZE_ERROR bytes). Please check webhosting backup cronjob."
        fi

        # Get MD5 checksum
        md5=$(md5sum $file | awk '{print $1}') 2>> $ERROR_FILE

        echolog "Downloaded file $filename with $filesize bytes. Checksum: $md5"

        # Move to final backup destination.
        cp $file $FINAL_BACKUP_DIRECTORY/ 2>> $ERROR_FILE && rm $file 2>> $ERROR_FILE

        # Delete downloaded files from FTP server if $DELETE_BACKUPS_UPON_PULL is true
        if [ "$DELETE_BACKUPS_UPON_PULL" = true ] ; then
            echolog "Deleting file $filename from $server ..."
            curl --fail --silent --show-error "ftp://$FTP_HOST:$FTP_PORT/" --user "$FTP_USER:$FTP_PASSWORD" -Q "DELE /$FTP_BACKUP_DIRECTORY/$filename" >> /dev/null 2>> $ERROR_FILE && echolog "File $filename successfully deleted on server $server" || echoerror "Failed to delete file $filename on $server"
        fi

    done

    echolog "Finished with server $server"

done

echolog "Backup pulling script finished. It took $(( SECONDS - start_time )) seconds."