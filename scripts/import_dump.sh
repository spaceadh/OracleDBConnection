#!/bin/bash
# Oracle Data Pump Import Script
# Usage: ./import_dump.sh <dmp_file_name> [schema_name] [tablespace_name]

set -e

DMP_FILE="$1"
TARGET_SCHEMA="${2:-IMPORTED_SCHEMA}"
TABLESPACE="${3:-USERS}"

if [ -z "$DMP_FILE" ]; then
    echo "Usage: $0 <dmp_file_name> [schema_name] [tablespace_name]"
    echo ""
    echo "Available .dmp files:"
    ls -la /opt/oracle/import/*.DMP 2>/dev/null || echo "No .DMP files found"
    exit 1
fi

echo "=== Oracle Data Pump Import ==="
echo "DMP File: $DMP_FILE"
echo "Target Schema: $TARGET_SCHEMA"
echo "Target Tablespace: $TABLESPACE"
echo "================================"

# Check if file exists
if [ ! -f "/opt/oracle/import/$DMP_FILE" ]; then
    echo "Error: File /opt/oracle/import/$DMP_FILE not found"
    exit 1
fi

# Create target schema if it doesn't exist
echo "Creating target schema..."
sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba << EOF
-- Create user if not exists
DECLARE
    user_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM dba_users WHERE username = UPPER('$TARGET_SCHEMA');
    IF user_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER $TARGET_SCHEMA IDENTIFIED BY ImportPassword123 DEFAULT TABLESPACE $TABLESPACE TEMPORARY TABLESPACE TEMP QUOTA UNLIMITED ON $TABLESPACE';
        EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SYNONYM, CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER TO $TARGET_SCHEMA';
        EXECUTE IMMEDIATE 'GRANT IMP_FULL_DATABASE TO $TARGET_SCHEMA';
        DBMS_OUTPUT.PUT_LINE('User $TARGET_SCHEMA created successfully.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('User $TARGET_SCHEMA already exists.');
    END IF;
END;
/

-- Grant directory permissions
GRANT READ, WRITE ON DIRECTORY IMPORT_DIR TO $TARGET_SCHEMA;
EOF

echo "Schema preparation completed."
echo ""

# Run the import
echo "Starting Data Pump import..."
echo "This may take several minutes depending on the file size..."

impdp sys/OraclePassword123@XEPDB1 \
    directory=IMPORT_DIR \
    dumpfile=$DMP_FILE \
    schemas=EGF \
    remap_schema=EGF:$TARGET_SCHEMA \
    remap_tablespace=EGF_DATA:$TABLESPACE \
    transform=OID:N \
    exclude=USER,ROLE,GRANT \
    logfile=import_${TARGET_SCHEMA}_$(date +%Y%m%d_%H%M%S).log

echo ""
echo "Import completed! Check the log file for details."
echo ""
echo "To connect to the imported schema:"
echo "Username: $TARGET_SCHEMA"
echo "Password: ImportPassword123"
echo "Database: XEPDB1"