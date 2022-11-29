#!/bin/bash

###### ROTATE BACKUP SCRIPT ######
# Script to rotate backup files on a daily and monthly basis.

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

rotation_type=$1

# Validation of rotation type.
if [ "$rotation_type" != "daily" ] && [ "$rotation_type" != "monthly" ]; then
    echo "Wrong script usage. You should specify a valid rotation type as the first and only parameter." 1>&2;
    echo "Usage: rotate.sh daily|monthly" 1>&2;
    exit 1;
fi

rotation_type_u="$(echo $rotation_type | awk '{$1=toupper(substr($1,0,1))substr($1,2)}1')"

echolog "$rotation_type_u rotation script started"

# Create monthly folder if not exists on final backup directory
mkdir -p "$FINAL_BACKUP_DIRECTORY/monthly"

# For daily executions
if [ "$rotation_type" = "daily" ]; then

    # Delete files older than 7 days.
    $(find $FINAL_BACKUP_DIRECTORY -type f -mtime +7 -name '*.gz' -maxdepth 1 -execdir rm -- '{}' \;) && echolog "Older than 7 days backups correctly deleted" || echoerror "Error while deleting backups older than 7 days"

# For monthly executions
else
    # Save files from the last 24 hours into monthly folder
    $(find $FINAL_BACKUP_DIRECTORY -type f -mtime -1 -name '*.gz' -maxdepth 1 -execdir cp -- '{}' $FINAL_BACKUP_DIRECTORY/monthly/ \;) && echolog "Monthly backups correctly saved"
    
    # Delete files older than 1 year on monthly folder
    $(find $FINAL_BACKUP_DIRECTORY/monthly -type f -mtime +365 -name '*.gz' -maxdepth 1 -execdir rm -- '{}' \;) && echolog "Older than 1 year backups correctly deleted" || echoerror "Error while deleting backups older than 1 year"

fi

echolog "$rotation_type_u rotation script finished"