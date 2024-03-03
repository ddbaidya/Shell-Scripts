#!/bin/bash



#############################################################################
###                                                                       ###
######################       Credentials        #############################
###                                                                       ###
#############################################################################


# Database credentials
DB_USER=""
DB_PASSWORD=""
DB_NAME=""
MYSQL_DUMP="mysqldump" # Don't change it


# Backup path
BACKUP_PATH="files"


# AWS credentials
AWS_ACCESS_KEY=""
AWS_SECRET_KEY=""
AWS_REGION="us-east-1"

# S3 bucket details
S3_BUCKET=""





#############################################################################
###                                                                       ###
######################      Database Backup      ############################
###                                                                       ###
#############################################################################


# Timestamp for backup file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_PATH}/${DB_NAME}_${TIMESTAMP}.sql"

# Check if mysqldump command is available
if ! command -v ${MYSQL_DUMP} &> /dev/null; then
    echo "mysqldump command not found. Please install MySQL client tools."
    exit 1
fi

# Create the backup
${MYSQL_DUMP} -u "$DB_USER" -p"$DB_PASSWORD" --password="$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"

# Check the exit status of mysqldump
if [ $? -eq 0 ]; then
    echo "Database backup successfully created: $BACKUP_FILE"
else
    echo "Error creating database backup."
    exit 1
fi




#############################################################################
###                                                                       ###
######################        Upload to S3       ############################
###                                                                       ###
#############################################################################



# Local backup file path
LOCAL_BACKUP_FILE=$BACKUP_FILE
REMOTE_BACKUP_PATH="$TIMESTAMP.sql"

# Check if the AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it before running this script."
    exit 1
fi

# Check if the AWS credentials are set
if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
    echo "AWS credentials are not set. Please provide your access key and secret key."
    exit 1
fi

# Check if the local backup file exists
if [ ! -f "$LOCAL_BACKUP_FILE" ]; then
    echo "Local backup file not found: $LOCAL_BACKUP_FILE"
    exit 1
fi

# Set AWS credentials
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
export AWS_DEFAULT_REGION="$AWS_REGION"

# Upload the backup file to S3
aws s3 cp "$LOCAL_BACKUP_FILE" "s3://$S3_BUCKET/$REMOTE_BACKUP_PATH"

# Check the exit status of the AWS CLI command
if [ $? -eq 0 ]; then
    echo "Backup successfully uploaded to S3: s3://$S3_BUCKET/$REMOTE_BACKUP_PATH"
else
    echo "Error uploading backup to S3."
    exit 1
fi


#############################################################################
###                                                                       ###
######################     Remove Temp Files     ############################
###                                                                       ###
#############################################################################

rm "$LOCAL_BACKUP_FILE"