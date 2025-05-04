#!/bin/bash

#### GENERATE BACKUP SCRIPT ####
# Script for generating backup files on webhosts. This script generate backups for web files and databases.

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

echolog "Backup generation script started"
start_time=$SECONDS

# Deleting old backups on backup directory
echolog "Deleting backups older than $DELETE_BACKUPS_OLDER_THAN_DAYS days ago"
$(find $BACKUP_DIRECTORY -type f -mtime +$DELETE_BACKUPS_OLDER_THAN_DAYS -name '*.gz' -execdir rm -- '{}' \;) && echolog "Old backups correctly deleted" || echoerror "Error while deleting old backups"

# Running over each database .cnf file
for database_cnf_file in $DATABASES_CNF_DIRECTORY/*.cnf ; do 
    # exclude possible garbage in directory
    [[ -f "$database_cnf_file" ]] || continue 
    
    filename=$(basename -- "$database_cnf_file")
    database="${filename%.*}"    
    
    # Getting filename for database
    database_backup_filename=$(date +%Y%m%d%H%M%S)\_$BACKUP_FILES_PREFIX\_db\_$database\_$RANDOM.sql 
    
    echolog "Backing up database $database ..."

    # Creating mysqldump, gzip and then mv file to backup's directory.
    mysqldump --defaults-file=$database_cnf_file --no-tablespaces $database > $TEMP_DIRECTORY/$database_backup_filename 2>> $ERROR_FILE && gzip $TEMP_DIRECTORY/$database_backup_filename 2>> $ERROR_FILE && mv $TEMP_DIRECTORY/$database_backup_filename.gz $BACKUP_DIRECTORY && echolog "Database $database successfully backed up into $database_backup_filename.gz" || echoerror "Error while backing up database $database"
done

# Getting webfiles backup file name.
web_backup_filename=$(date +%Y%m%d%H%M%S)\_$BACKUP_FILES_PREFIX\_web\_$RANDOM

echolog "Backing up website folder $WEB_ROOT_DIRECTORY ..."

# Generating website backup file.
tar -zcf "$TEMP_DIRECTORY/$web_backup_filename.tar.gz" -C $WEB_ROOT_DIRECTORY . >> $LOG_FILE 2>> $ERROR_FILE && mv "$TEMP_DIRECTORY/$web_backup_filename.tar.gz" $BACKUP_DIRECTORY && echolog "Website successfully backed up into $web_backup_filename.tar.gz" || echoerror "Error while backing up website files"

echolog "Backup generation script finished. It took $(( SECONDS - start_time )) seconds."