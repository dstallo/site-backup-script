#!/bin/bash

#### GENERATE BACKUP SCRIPT ####

# Script for generating backup files on webhosts. This script generate backups for web files and databases.

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