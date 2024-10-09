#!/bin/bash

# Prompt user for PostgreSQL credentials and host
read -p "Enter PostgreSQL Host for Offline Server (e.g., localhost): " DB_HOST
read -p "Enter PostgreSQL Username: " DB_USER
read -sp "Enter PostgreSQL Password: " DB_PASSWORD
echo ""

# Export the password for psql
export PGPASSWORD="$DB_PASSWORD"

# Ask for the folder containing the backup files
read -p "Enter the path to the folder containing the .sql backup files: " BACKUP_DIR

# Check if the folder exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "The folder $BACKUP_DIR does not exist. Please check the path and try again."
    exit 1
fi

# Loop through each .sql file in the backup folder
for BACKUP_FILE in "$BACKUP_DIR"/*.sql
do
    # Extract the database name from the filename (assumes the format is dbname-YYYYMMDD.sql)
    DB_NAME=$(basename "$BACKUP_FILE" | cut -d'-' -f1)

    echo "Restoring database $DB_NAME from $BACKUP_FILE..."

    # Create the database if it doesn't exist
    psql -U $DB_USER -h $DB_HOST -d postgres -c "CREATE DATABASE $DB_NAME;"

    # Restore the database with progress bar using pv
    pv "$BACKUP_FILE" | psql -U $DB_USER -h $DB_HOST -d $DB_NAME

    if [ $? -eq 0 ]; then
        echo "$DB_NAME restored successfully."
    else
        echo "Error occurred while restoring $DB_NAME."
    fi
done

# Unset the password after completion for security
unset PGPASSWORD

# Notify user of completion
echo "All databases have been restored from $BACKUP_DIR."
