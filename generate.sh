#!/bin/bash

#### GENERATE BACKUP SCRIPT ####

# All configuration variables should be setup at ./config/config.sh
# This script reads credentials for different databases from {DATABASES_CNF_DIRECTORY} in mysqldump .cnf file format
# and backups each one to {DATABASES_BACKUP_DIRECTORY}/YYYY-MM-DD-{database}_{RANDOM}.gz. Database name must be the cnf filename.
# Also, it backups all the website files located at {WEB_ROOT_DIRECTORY}, and leaves them in {WEB_BACKUP_DIRECTORY}/YYYY-MM-DD_{RANDOM}.gz
# Finally it removes old backup files, older than {DELETE_BACKUPS_OLDER_THAN_DAYS} (if pulling script is active and DELETE_BACKUPS_UPON_PULL is enabled, there will be nothing to delete).
# A final note, this script is recommended to be run on a daily basis, but its not mandatory. It uses standard $RANDOM variable to prevent overwrites.
# It must be executed locally on webhosting server.

#### DEPENDENCIES

# mysqldump
# gzip
# tar

################################

# Backup script root directory.
SCRIPT_ROOT_DIRECTORY=`dirname "$0"`

# Include config file
source $SCRIPT_ROOT_DIRECTORY/config/config.sh

current=`date +%Y%m%d_%H%M`

for database_cnf_file in $DATABASES_CNF_DIRECTORY/*.cnf ; do 
    [[ -f "$database_cnf_file" ]] || continue # exclude garbage in directory
    filename=$(basename -- "$database_cnf_file")
    database="${filename%.*}"    
    database_backup_filename=$current\_$BACKUP_FILES_PREFIX\_db\_$database\_$RANDOM.sql
    
    mysqldump --defaults-file=$database_cnf_file $database > $TEMP_DIRECTORY/$database_backup_filename && gzip -c $TEMP_DIRECTORY/$database_backup_filename && mv $TEMP_DIRECTORY/$database_backup_filename.gz $BACKUP_DIRECTORY && echo "$current: DATABASE $database SUCCESSFULLY BACKED UP into $database_backup_filename.gz"
done

web_backup_filename=$current\_$BACKUP_FILES_PREFIX\_web\_$RANDOM

tar -zvcf "$TEMP_DIRECTORY/$web_backup_filename.tar.gz" -C $WEB_ROOT_DIRECTORY . && mv "$TEMP_DIRECTORY/$web_backup_filename.tar.gz" $BACKUP_DIRECTORY && echo "$current: WEBSITE SUCCESSFULLY BACKED UP into $web_backup_filename.tar.gz"

$(find $BACKUP_DIRECTORY -type f -mtime +$DELETE_BACKUPS_OLDER_THAN_DAYS -name '*.gz' -execdir rm -- '{}' \;)