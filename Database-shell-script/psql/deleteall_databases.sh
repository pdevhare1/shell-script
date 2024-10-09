#!/bin/bash

# Prompt user for PostgreSQL credentials and host
read -p "Enter PostgreSQL Host for Offline Server (e.g., localhost): " DB_HOST
read -p "Enter PostgreSQL Username: " DB_USER
read -sp "Enter PostgreSQL Password: " DB_PASSWORD
echo ""

# Export the password for psql
export PGPASSWORD="$DB_PASSWORD"

# Fetch all available databases, excluding system databases
DATABASES=$(psql -U $DB_USER -h $DB_HOST -d postgres -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1');")

# Loop through each database and drop them forcefully
for DB_NAME in $DATABASES
do
    DB_NAME=$(echo $DB_NAME | xargs)  # Trim any leading/trailing spaces
    echo "Terminating connections to $DB_NAME..."

    # Terminate all active connections to the database
    psql -U $DB_USER -h $DB_HOST -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME';"

    echo "Dropping database $DB_NAME..."

    # Drop the database
    psql -U $DB_USER -h $DB_HOST -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"

    if [ $? -eq 0 ]; then
        echo "$DB_NAME dropped successfully."
    else
        echo "Error occurred while dropping $DB_NAME."
    fi
done

# Unset the password after completion for security
unset PGPASSWORD

# Notify user of completion
echo "All databases on the Offline Server have been deleted."
