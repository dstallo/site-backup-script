# site-backup-script
Scripts for backup automation of web sites.

## Generation script (generate.sh)

This script must be executed locally on webhosting server. It will handle the generation of backup files on webhosts. This script generate backups for web files and databases.
All configuration variables should be setup at ./config/config.sh
This script reads credentials for different databases from {DATABASES_CNF_DIRECTORY} in mysqldump .cnf file format and backups each one to {BACKUP_DIRECTORY}/YYYY-MM-DD-{database}_{RANDOM}.gz. Database name should not be placed inside the .cnf, instead it must be the cnf filename.
Also, it backups all the website files located at {WEB_ROOT_DIRECTORY}, and leaves them in {BACKUP_DIRECTORY}/YYYYMMDD_HHII_web_{RANDOM}.gz
Finally it removes old backup files, older than {DELETE_BACKUPS_OLDER_THAN_DAYS} (if pulling script is active and DELETE_BACKUPS_UPON_PULL is enabled, there will be nothing to delete).
A final note, this script is recommended to be run on a daily basis, but its not mandatory. It uses standard $RANDOM variable to prevent overwrites.

### Database configuration files
The database's configuration files should contain the following attributes
- user={database_user}
- password={database_password}
- host={database_host}

### Dependencies for generate.sh
- mysqldump
- gzip
- tar
- find

## Pulling script (pull.sh)
This script should be placed and executed on final backup destination server. For each server configured on ./config/servers folder, the script will download the last generated backups. 
Once done, if DELETE_BACKUPS_UPON_PULL is enabled, it will delete them from remote server.

### Server configuration files
The server's configuration files, should contain the following env variables
- FTP_HOST="{ftp_hostname}"
- FTP_USER="{ftp_username}"
- FTP_PASSWORD="{ftp_password}"
- FTP_BACKUP_DIRECTORY="{Directory where backups are saved on webhost}"

### Dependencies for pull.sh
- wget