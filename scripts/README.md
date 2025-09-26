# Oracle Data Pump Import Utilities

This directory contains scripts and utilities for importing Oracle .dmp files into your database.

## Available Scripts

### import_dump.sh
Comprehensive import script for Oracle Data Pump files.

**Usage:**
```bash
./import_dump.sh <dmp_file_name> [schema_name] [tablespace_name]
```

**Parameters:**
- `dmp_file_name`: Name of the .dmp file in the db-data directory
- `schema_name`: Target schema name (default: IMPORTED_SCHEMA)
- `tablespace_name`: Target tablespace (default: USERS)

## PowerShell Import Commands

### Quick Import (using first .dmp file)
```powershell
# Import EGF_EXP_14AUG24_01.DMP to EGF_SCHEMA
docker exec oracle-xe-db impdp sys/OraclePassword123@XEPDB1 directory=IMPORT_DIR dumpfile=EGF_EXP_14AUG24_01.DMP schemas=EGF remap_schema=EGF:EGF_SCHEMA remap_tablespace=EGF_DATA:USERS transform=OID:N exclude=USER,ROLE,GRANT logfile=import_egf_01.log
```

### Step-by-Step Import Process

1. **Create target schema:**
```powershell
"CREATE USER EGF_SCHEMA IDENTIFIED BY ImportPassword123 DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP QUOTA UNLIMITED ON USERS;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba
```

2. **Grant permissions:**
```powershell
"GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SYNONYM, CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER, IMP_FULL_DATABASE TO EGF_SCHEMA;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba
```

3. **Grant directory access:**
```powershell
"GRANT READ, WRITE ON DIRECTORY IMPORT_DIR TO EGF_SCHEMA;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba
```

4. **Run the import:**
```powershell
docker exec oracle-xe-db impdp sys/OraclePassword123@XEPDB1 directory=IMPORT_DIR dumpfile=EGF_EXP_14AUG24_01.DMP schemas=EGF remap_schema=EGF:EGF_SCHEMA remap_tablespace=EGF_DATA:USERS transform=OID:N exclude=USER,ROLE,GRANT logfile=import_egf_schema.log
```

## Import Multiple Files

For importing all related .dmp files (if they're part of a multi-file export):
```powershell
docker exec oracle-xe-db impdp sys/OraclePassword123@XEPDB1 directory=IMPORT_DIR dumpfile=EGF_EXP_14AUG24_%U.DMP schemas=EGF remap_schema=EGF:EGF_SCHEMA remap_tablespace=EGF_DATA:USERS transform=OID:N exclude=USER,ROLE,GRANT logfile=import_egf_full.log
```

## Check Import Status

### View import logs:
```powershell
docker exec oracle-xe-db ls -la /opt/oracle/import/*.log
docker exec oracle-xe-db tail -f /opt/oracle/import/import_egf_schema.log
```

### Check imported objects:
```powershell
"SELECT object_type, COUNT(*) FROM dba_objects WHERE owner = 'EGF_SCHEMA' GROUP BY object_type ORDER BY object_type;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba
```

### Connect to imported schema:
```powershell
docker exec -it oracle-xe-db sqlplus EGF_SCHEMA/ImportPassword123@XEPDB1
```

## CloudBeaver Connection for Imported Schema

After successful import, connect to the imported schema via CloudBeaver:
- **Host**: oracle-db
- **Port**: 1521
- **Database**: XEPDB1
- **Username**: EGF_SCHEMA
- **Password**: ImportPassword123

## Troubleshooting

### Common Issues:
1. **ORA-31626: job does not exist** - Directory permissions issue
2. **ORA-39001: invalid argument value** - Check file path and name
3. **ORA-00959: tablespace does not exist** - Use existing tablespace like USERS

### Check available tablespaces:
```powershell
"SELECT tablespace_name FROM dba_tablespaces;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba
```