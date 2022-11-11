#!/bin/bash

###### Configuration file for backup scripts.

if [[ -z $SCRIPT_ROOT_DIRECTORY ]];
then
    SCRIPT_ROOT_DIRECTORY=`dirname "$0"`
fi

# Prefix to name backup files on generation time [Used only on generate.sh]
BACKUP_FILES_PREFIX="{website}"

# Delete backups on pull (true/false) [Used on pull.sh]
DELETE_BACKUPS_UPON_PULL=true

# Time to live for old backups in days on webhosting (if not deleted on pull script) [Used on generate.sh]
DELETE_BACKUPS_OLDER_THAN_DAYS=5

# Databases directory for CNF file's for mysqldump command. If more databases are needed to be backed up, a cnf file should be added here for each. [Used on generate.sh]
DATABASES_CNF_DIRECTORY=./config/databases

# Directory for FTP server's credentials. There should be one .sh config file for each server. Server name should be used as filename. [Used on pull.sh]
SERVERS_DIRECTORY=./config/servers

# Root directory for web files to be backed up. [Used on generate.sh]
WEB_ROOT_DIRECTORY=../public_html

# Temporal directory for partial backups. Nothing should permanently be here if everything is working OK. [Used on both generate.sh and pull.sh]
TEMP_DIRECTORY=./tmp

# Server's backup directory located on webhost (locally to the website server). It should match the FTP_BACKUP_DIRECTORY on each servers's FTP credentials file [Used on generate.sh]
BACKUP_DIRECTORY=./files

# Final backup directory located on backup's final host (on backup's server) [Used only on pull.sh]
FINAL_BACKUP_DIRECTORY=../final

# Minimum filesize error in bytes 
MINIMUM_FILESIZE_ERROR=4096
