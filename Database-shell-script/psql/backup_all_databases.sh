#!/bin/bash

# Prompt user for PostgreSQL credentials and host
read -p "Enter PostgreSQL Host (e.g., localhost): " DB_HOST
read -p "Enter PostgreSQL Username: " DB_USER
read -sp "Enter PostgreSQL Password: " DB_PASSWORD
echo ""

# Export the password for pg_dump
export PGPASSWORD="$DB_PASSWORD"

# Set backup directory to the current working directory and create a 'backup' folder
BACKUP_DIR="$(pwd)/backup"
mkdir -p "$BACKUP_DIR"  # Create the directory if it doesn't exist

# Fetch all available databases, excluding system databases like template0 and template1
DATABASES=$(psql -U $DB_USER -h $DB_HOST -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

# Loop through each database and back them up with progress
for DB_NAME in $DATABASES
do
    DB_NAME=$(echo $DB_NAME | xargs)  # Trim any leading/trailing spaces
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$(date +%Y%m%d%H%M%S).sql"
    echo "Backing up $DB_NAME to $BACKUP_FILE..."

    # Dump the database and show progress with pv
    pg_dump -U $DB_USER -h $DB_HOST $DB_NAME | pv -t -e -b -N $DB_NAME > $BACKUP_FILE

    if [ $? -eq 0 ]; then
        echo "$DB_NAME backup completed successfully."
    else
        echo "Error occurred during the backup of $DB_NAME."
    fi
done

# Unset the password after backup is complete for security
unset PGPASSWORD

# Notify user of completion
echo "All backups have been completed and are stored in $BACKUP_DIR."
