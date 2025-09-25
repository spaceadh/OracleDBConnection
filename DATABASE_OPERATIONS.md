# Database Operations Guide

Comprehensive guide for Oracle Database administration tasks, import/export operations, and useful commands.

## 📋 Table of Contents

- [Connection Methods](#connection-methods)
- [Import/Export Operations](#importexport-operations)
- [Backup and Restore](#backup-and-restore)
- [User Management](#user-management)
- [Schema Operations](#schema-operations)
- [Performance Monitoring](#performance-monitoring)
- [Maintenance Tasks](#maintenance-tasks)
- [Useful SQL Commands](#useful-sql-commands)

## 🔌 Connection Methods

### SQL*Plus Connection

```powershell
# Connect as application user
docker exec -it oracle-xe-db sqlplus app_schema/AppSchema123@XEPDB1

# Connect as system administrator
docker exec -it oracle-xe-db sqlplus sys/OraclePassword123@XEPDB1 as sysdba

# Connect as system user
docker exec -it oracle-xe-db sqlplus system/OraclePassword123@XEPDB1

# Silent connection (for scripts)
docker exec -it oracle-xe-db sqlplus -s app_schema/AppSchema123@XEPDB1
```

### SQL Developer Connection

**Connection Details:**
- **Connection Name**: Oracle Docker Dev
- **Username**: `app_schema`
- **Password**: `AppSchema123`
- **Hostname**: `localhost`
- **Port**: `1521`
- **Service Name**: `XEPDB1`

## 📦 Import/Export Operations

### Data Pump Export (expdp)

#### Export Schema

```powershell
# Create directory for exports (run as SYSDBA)
docker exec -it oracle-xe-db sqlplus sys/OraclePassword123@XEPDB1 as sysdba <<EOF
CREATE OR REPLACE DIRECTORY export_dir AS '/opt/oracle/admin/XE/dpdump/';
GRANT READ, WRITE ON DIRECTORY export_dir TO app_schema;
EXIT;
EOF

# Export entire schema
docker exec -it oracle-xe-db expdp app_schema/AppSchema123@XEPDB1 \
  DIRECTORY=export_dir \
  DUMPFILE=app_schema_full.dmp \
  LOGFILE=app_schema_full.log \
  SCHEMAS=app_schema

# Export specific tables
docker exec -it oracle-xe-db expdp app_schema/AppSchema123@XEPDB1 \
  DIRECTORY=export_dir \
  DUMPFILE=app_tables.dmp \
  LOGFILE=app_tables.log \
  TABLES=employees,departments,projects
```

#### Export with Data Filtering

```powershell
# Export employees hired after 2024
docker exec -it oracle-xe-db expdp app_schema/AppSchema123@XEPDB1 \
  DIRECTORY=export_dir \
  DUMPFILE=recent_employees.dmp \
  LOGFILE=recent_employees.log \
  TABLES=employees \
  QUERY=employees:"WHERE hire_date >= DATE '2024-01-01'"

# Export specific department data
docker exec -it oracle-xe-db expdp app_schema/AppSchema123@XEPDB1 \
  DIRECTORY=export_dir \
  DUMPFILE=it_department.dmp \
  LOGFILE=it_department.log \
  TABLES=employees,employee_projects \
  QUERY=employees:"WHERE dept_id = 1" \
  QUERY=employee_projects:"WHERE emp_id IN (SELECT emp_id FROM employees WHERE dept_id = 1)"
```

### Data Pump Import (impdp)

#### Import Full Schema

```powershell
# Import entire schema
docker exec -it oracle-xe-db impdp app_schema/AppSchema123@XEPDB1 \
  DIRECTORY=export_dir \
  DUMPFILE=app_schema_full.dmp \
  LOGFILE=import_full.log \
  SCHEMAS=app_schema

# Import with schema remap
docker exec -it oracle-xe-db impdp system/OraclePassword123@XEPDB1 \
  DIRECTORY=export_dir \
  DUMPFILE=app_schema_full.dmp \
  LOGFILE=import_remap.log \
  REMAP_SCHEMA=app_schema:new_schema \
  SCHEMAS=app_schema
```

#### Import Specific Tables

```powershell
# Import only specific tables
docker exec -it oracle-xe-db impdp app_schema/AppSchema123@XEPDB1 \
  DIRECTORY=export_dir \
  DUMPFILE=app_schema_full.dmp \
  LOGFILE=import_tables.log \
  TABLES=employees,departments

# Import with table remap
docker exec -it oracle-xe-db impdp app_schema/AppSchema123@XEPDB1 \
  DIRECTORY=export_dir \
  DUMPFILE=app_schema_full.dmp \
  LOGFILE=import_remap_table.log \
  REMAP_TABLE=app_schema.employees:app_schema.employees_backup
```

### Copy Files To/From Container

```powershell
# Copy dump file FROM container to host
docker cp oracle-xe-db:/opt/oracle/admin/XE/dpdump/app_schema_full.dmp ./backups/

# Copy dump file TO container from host
docker cp ./backups/app_schema_full.dmp oracle-xe-db:/opt/oracle/admin/XE/dpdump/

# Copy SQL script to container
docker cp ./scripts/maintenance.sql oracle-xe-db:/tmp/maintenance.sql
```

## 💾 Backup and Restore

### Cold Backup (Offline)

```powershell
# Stop the database
docker-compose stop oracle-db

# Backup data volume
docker run --rm -v oracle_oracle-data:/source -v ${PWD}/backups:/backup alpine tar czf /backup/oracle-data-backup.tar.gz -C /source .

# Start the database
docker-compose start oracle-db
```

### Hot Backup (Online)

```powershell
# Create consistent backup using RMAN
docker exec -it oracle-xe-db rman target sys/OraclePassword123@XEPDB1

# Inside RMAN
BACKUP DATABASE PLUS ARCHIVELOG;
BACKUP CURRENT CONTROLFILE;
LIST BACKUP;
EXIT;
```

### Logical Backup with Scripts

```powershell
# Create backup script
docker exec -it oracle-xe-db bash -c 'cat > /tmp/backup_schema.sql << EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SPOOL /tmp/schema_backup.sql
SELECT DBMS_METADATA.GET_DDL(object_type, object_name, owner) || CHR(10) || '/' 
FROM all_objects 
WHERE owner = 'APP_SCHEMA' 
AND object_type IN ('TABLE', 'INDEX', 'SEQUENCE', 'VIEW', 'PROCEDURE', 'FUNCTION', 'TRIGGER')
ORDER BY object_type, object_name;
SPOOL OFF
EXIT;
EOF'

# Execute backup script
docker exec -it oracle-xe-db sqlplus -s app_schema/AppSchema123@XEPDB1 @/tmp/backup_schema.sql

# Copy backup to host
docker cp oracle-xe-db:/tmp/schema_backup.sql ./backups/
```

## 👥 User Management

### Create New Users

```sql
-- Connect as SYSDBA
-- Create new application user
CREATE USER new_app_user IDENTIFIED BY NewPassword123
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

-- Grant basic privileges
GRANT CONNECT, RESOURCE TO new_app_user;

-- Grant specific privileges
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE TO new_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_schema.employees TO new_app_user;
```

### User Administration

```sql
-- List all users
SELECT username, account_status, created, default_tablespace 
FROM dba_users 
ORDER BY created DESC;

-- Check user privileges
SELECT grantee, privilege, admin_option 
FROM dba_sys_privs 
WHERE grantee = 'APP_SCHEMA';

-- Check object privileges
SELECT grantee, owner, table_name, privilege 
FROM dba_tab_privs 
WHERE grantee = 'APP_SCHEMA';

-- Lock/Unlock user
ALTER USER app_schema ACCOUNT LOCK;
ALTER USER app_schema ACCOUNT UNLOCK;

-- Change password
ALTER USER app_schema IDENTIFIED BY NewPassword123;

-- Drop user
DROP USER new_app_user CASCADE;
```

## 🗄️ Schema Operations

### Schema Information

```sql
-- List all tables in schema
SELECT table_name, num_rows, blocks, avg_row_len
FROM user_tables
ORDER BY table_name;

-- Get table structure
DESCRIBE employees;

-- Get table constraints
SELECT constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name = 'EMPLOYEES';

-- List indexes
SELECT index_name, table_name, uniqueness, status
FROM user_indexes
WHERE table_name = 'EMPLOYEES';
```

### Schema Maintenance

```sql
-- Analyze schema statistics
BEGIN
  DBMS_STATS.GATHER_SCHEMA_STATS(
    ownname => 'APP_SCHEMA',
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
    cascade => TRUE
  );
END;
/

-- Rebuild indexes
ALTER INDEX emp_email_uk REBUILD;

-- Check invalid objects
SELECT object_name, object_type, status
FROM user_objects
WHERE status = 'INVALID'
ORDER BY object_type, object_name;

-- Compile invalid objects
ALTER PROCEDURE get_employee_count COMPILE;
ALTER FUNCTION get_department_budget COMPILE;
```

## 📊 Performance Monitoring

### System Performance

```sql
-- Current database sessions
SELECT sid, serial#, username, program, status, logon_time
FROM v$session
WHERE username IS NOT NULL
ORDER BY logon_time DESC;

-- Database size information
SELECT 
  tablespace_name,
  ROUND(bytes/1024/1024, 2) AS size_mb,
  ROUND(maxbytes/1024/1024, 2) AS max_size_mb,
  ROUND((bytes/maxbytes)*100, 2) AS used_pct
FROM dba_data_files
ORDER BY tablespace_name;

-- Long running queries
SELECT sql_id, elapsed_time/1000000 as elapsed_seconds, executions, 
       buffer_gets, disk_reads, cpu_time/1000000 as cpu_seconds
FROM v$sql
WHERE elapsed_time > 1000000
ORDER BY elapsed_time DESC;
```

### Table Statistics

```sql
-- Table sizes
SELECT 
  table_name,
  num_rows,
  blocks,
  empty_blocks,
  ROUND((blocks * 8192)/1024/1024, 2) AS size_mb
FROM user_tables
ORDER BY blocks DESC NULLS LAST;

-- Index usage
SELECT i.index_name, i.table_name, u.used, u.start_monitoring, u.end_monitoring
FROM user_indexes i
LEFT JOIN v$object_usage u ON i.index_name = u.index_name
ORDER BY i.table_name, i.index_name;
```

## 🔧 Maintenance Tasks

### Daily Maintenance Script

```sql
-- Create daily maintenance procedure
CREATE OR REPLACE PROCEDURE daily_maintenance AS
BEGIN
  -- Update table statistics
  FOR rec IN (SELECT table_name FROM user_tables) LOOP
    DBMS_STATS.GATHER_TABLE_STATS(
      ownname => USER,
      tabname => rec.table_name,
      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
    );
  END LOOP;
  
  -- Check for invalid objects
  FOR rec IN (SELECT object_name, object_type FROM user_objects WHERE status = 'INVALID') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'ALTER ' || rec.object_type || ' ' || rec.object_name || ' COMPILE';
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed to compile ' || rec.object_type || ' ' || rec.object_name);
    END;
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE('Daily maintenance completed at ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
END;
/

-- Execute daily maintenance
EXEC daily_maintenance;
```

### Cleanup Scripts

```sql
-- Clean up old data (example: remove employees marked as terminated > 1 year ago)
DELETE FROM employee_projects 
WHERE emp_id IN (
  SELECT emp_id FROM employees 
  WHERE status = 'TERMINATED' 
  AND updated_date < SYSDATE - 365
);

DELETE FROM employees 
WHERE status = 'TERMINATED' 
AND updated_date < SYSDATE - 365;

COMMIT;

-- Archive old project data
CREATE TABLE projects_archive AS 
SELECT * FROM projects 
WHERE status = 'COMPLETED' 
AND end_date < SYSDATE - 180;

DELETE FROM projects 
WHERE status = 'COMPLETED' 
AND end_date < SYSDATE - 180;

COMMIT;
```

## 📝 Useful SQL Commands

### Data Query Examples

```sql
-- Employee hierarchy
SELECT LEVEL, LPAD(' ', (LEVEL-1)*2) || first_name || ' ' || last_name AS employee_hierarchy
FROM employees
START WITH manager_id IS NULL
CONNECT BY PRIOR emp_id = manager_id
ORDER SIBLINGS BY last_name, first_name;

-- Department summary with employee count and average salary
SELECT 
  d.dept_name,
  d.location,
  COUNT(e.emp_id) AS employee_count,
  ROUND(AVG(e.salary), 2) AS avg_salary,
  MIN(e.salary) AS min_salary,
  MAX(e.salary) AS max_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.status = 'ACTIVE'
GROUP BY d.dept_name, d.location
ORDER BY employee_count DESC;

-- Project allocation report
SELECT 
  p.project_name,
  p.status,
  e.first_name || ' ' || e.last_name AS employee_name,
  ep.role,
  ep.allocation_percentage * 100 AS allocation_pct,
  ROUND(e.salary * ep.allocation_percentage / 12, 2) AS monthly_cost
FROM projects p
JOIN employee_projects ep ON p.project_id = ep.project_id
JOIN employees e ON ep.emp_id = e.emp_id
WHERE p.status = 'ACTIVE'
ORDER BY p.project_name, e.last_name;
```

### Administrative Queries

```sql
-- Database version and options
SELECT banner FROM v$version;

-- Current database name and ID
SELECT name, dbid, created FROM v$database;

-- Tablespace usage
SELECT 
  tablespace_name,
  ROUND(used_space * 8192 / 1024 / 1024, 2) AS used_mb,
  ROUND(tablespace_size * 8192 / 1024 / 1024, 2) AS total_mb,
  ROUND(used_percent, 2) AS used_pct
FROM dba_tablespace_usage_metrics
ORDER BY used_percent DESC;

-- Active connections
SELECT 
  username,
  COUNT(*) AS session_count,
  status
FROM v$session
WHERE username IS NOT NULL
GROUP BY username, status
ORDER BY session_count DESC;
```

## 🚨 Emergency Procedures

### Recovery Commands

```sql
-- Check database status
SELECT status FROM v$instance;

-- Check tablespace status
SELECT tablespace_name, status FROM dba_tablespaces;

-- Check datafile status
SELECT file_name, status, enabled FROM dba_data_files;

-- Emergency startup (as SYSDBA)
STARTUP MOUNT;
ALTER DATABASE OPEN;

-- Force startup in case of issues
STARTUP FORCE;
```

### Troubleshooting

```powershell
# Check Oracle processes
docker exec oracle-xe-db ps -ef | grep ora

# Check Oracle error logs
docker exec oracle-xe-db tail -f /opt/oracle/diag/rdbms/xe/XE/trace/alert_XE.log

# Check listener status
docker exec oracle-xe-db lsnrctl status

# Restart listener
docker exec oracle-xe-db lsnrctl stop
docker exec oracle-xe-db lsnrctl start
```

---

This guide provides comprehensive database operations for your Oracle Docker environment. Always test procedures in a development environment before applying to production systems.

**Remember to:**
- 🔄 Regular backups
- 📊 Monitor performance
- 🔒 Maintain security
- 📝 Document changes

Happy database administration! 🎯