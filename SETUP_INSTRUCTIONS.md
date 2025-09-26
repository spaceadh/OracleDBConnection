# Oracle Database Docker Development Environment - Complete Setup Guide

A comprehensive guide to set up Oracle Database with Docker, web interface, and .dmp file import capabilities.

## 🎯 What This Setup Provides

- ✅ Oracle Database XE 21c in Docker
- ✅ CloudBeaver web interface for database management
- ✅ Java and Go connectivity tests
- ✅ Oracle Data Pump import for .dmp files
- ✅ Sample schema with business data
- ✅ Complete development environment

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites
- Docker Desktop installed and running
- Git (optional, for cloning)
- 8GB+ RAM recommended

### 1. Initial Setup
```powershell
# Navigate to project directory
cd d:\Personal\OracleDBConnection

# Start Oracle Database (first time takes 2-3 minutes)
docker-compose up -d oracle-db

# Wait for database initialization (watch logs)
docker-compose logs -f oracle-db
# Wait for: "Pluggable database XEPDB1 opened read write"
```

### 2. Start Web Interface
```powershell
# Start CloudBeaver web interface
docker-compose up -d cloudbeaver

# Open CloudBeaver in browser
# URL: http://localhost:8080
```

### 3. Connect to Database
**CloudBeaver Connection Settings:**
- **Database Type**: Oracle
- **Host**: `oracle-db`
- **Port**: `1521`
- **Database**: `XEPDB1`
- **Username**: `app_schema`
- **Password**: `AppSchema123`
---

or 
```
jdbc:oracle:thin:@oracle-db:1521/XEPDB1
```


## 📋 Complete Step-by-Step Setup

### Phase 1: Database Infrastructure

#### 1.1 Start Oracle Database
```powershell
# Start Oracle XE container
docker-compose up -d oracle-db

# Check container status
docker-compose ps

# Monitor startup progress
docker-compose logs -f oracle-db
```

**Expected Output:**
```
Pluggable database XEPDB1 opened read write
DATABASE IS READY TO USE!
```

#### 1.2 Verify Database Status
```powershell
# Check PDB status
"SELECT name, open_mode FROM v\$pdbs;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123 as sysdba
```

**Expected Output:**
```
XEPDB1    READ WRITE
```

### Phase 2: Sample Schema Setup
#### 2.1 Create Application Schema
```powershell
# Create tables and database objects
Get-Content .\db-init-scripts\01_create_app_schema.sql | docker exec -i oracle-xe-db sqlplus sys/OraclePassword123@XEPDB1 as sysdba
```

#### 2.2 Create Sample Tables and Data
# Load sample data
Get-Content .\db-init-scripts\01_app_sample_data.sql | docker exec -i oracle-xe-db sqlplus sys/OraclePassword123@XEPDB1 as sysdba
```

### Phase 3: Web Interface Setup

#### 3.1 Start CloudBeaver
```powershell
# Start CloudBeaver container
docker-compose up -d cloudbeaver

# Check if running
docker-compose ps
```

#### 3.2 Initial CloudBeaver Configuration
1. Open browser to: `http://localhost:8080`
2. Complete initial setup wizard (create admin account)
3. Add new Oracle connection with these settings:

**Connection Configuration:**
```
Database Type: Oracle
Host: oracle-db
Port: 1521
Database: XEPDB1
Username: app_schema
Password: AppSchema123
```

or 
```
jdbc:oracle:thin:@oracle-db:1521/XEPDB1
```

### Phase 4: .DMP File Import Setup

#### 4.1 Prepare Import Environment
```powershell
# Create Oracle directory for imports
"CREATE OR REPLACE DIRECTORY IMPORT_DIR AS '/opt/oracle/import';" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba
```

#### 4.2 Create Import User (EGFDMIS)
Get-Content .\db-init-scripts\02_create_egf_schema.sql | docker exec -i oracle-xe-db sqlplus sys/OraclePassword123@XEPDB1 as sysdba

#### 4.3 Import .DMP Files
```powershell
# For multi-file dump sets (like EGF_EXP_14AUG24_*.DMP)
docker exec oracle-xe-db impdp EGFDMIS/EgfPass2017@XEPDB1 directory=IMPORT_DIR dumpfile=EGF_EXP_14AUG24_%U.DMP full=Y transform=OID:N logfile=import_egf_full.log

# For single .dmp files
docker exec oracle-xe-db impdp EGFDMIS/EgfPass2017@XEPDB1 directory=IMPORT_DIR dumpfile=YOUR_FILE.DMP full=Y transform=OID:N logfile=import_single.log
```

---

## 🧪 Testing Connectivity

### Java Connectivity Test
```powershell
cd java-test
mvn clean compile exec:java
```

**Expected Output:**
```
✓ Basic connection successful!
✓ Connection with properties successful!
✓ Connection pool created successfully!
✓ Database operations test successful!
```

### Go Connectivity Test
```powershell
cd go-test
go mod tidy
go run main.go
```

**Expected Output:**
```
✓ Basic connection successful!
✓ Query operations successful!
✓ Transaction handling successful!
✓ Prepared statements successful!
✓ Stored procedures and functions successful!
```

---

## 🔧 Management Commands

### Container Management
```powershell
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart oracle-db

# View logs
docker-compose logs oracle-db
docker-compose logs cloudbeaver

# Check container status
docker-compose ps
```

### Database Administration
```powershell
# Connect as SYSDBA
docker exec -it oracle-xe-db sqlplus sys/OraclePassword123@XEPDB1 as sysdba

# Connect as app_schema
docker exec -it oracle-xe-db sqlplus app_schema/AppSchema123@XEPDB1

# Connect as EGFDMIS (after import)
docker exec -it oracle-xe-db sqlplus EGFDMIS/EgfPass2017@XEPDB1

# Check database status
"SELECT status FROM v\$instance;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123 as sysdba

# List all users
"SELECT username FROM dba_users ORDER BY username;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba
```

### Import Operations
```powershell
# List available .dmp files
docker exec oracle-xe-db ls -la /opt/oracle/import/*.DMP

# Check import logs
docker exec oracle-xe-db ls -la /opt/oracle/import/*.log
docker exec oracle-xe-db tail -f /opt/oracle/import/import_egf_full.log

# Check imported objects
"SELECT owner, object_type, COUNT(*) FROM dba_objects WHERE owner NOT IN ('SYS','SYSTEM','APEX_030200','APEX_040000','APEX_040200','APEX_050000','APEX_180000','APEX_190000','APEX_200000','APEX_210000','OUTLN','FLOWS_FILES','HR','MDSYS','CTXSYS','XDB','ANONYMOUS','XS\$NULL','GSMADMIN_INTERNAL','DBSNMP','APPQOSSYS','DBSFWUSER','GGSYS','OJVMSYS','DVF','DVSYS','LBACSYS') GROUP BY owner, object_type ORDER BY owner, object_type;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba
```

---

## 🌐 Access Points

### Web Interfaces
| Service | URL | Username | Password | Description |
|---------|-----|----------|----------|-------------|
| CloudBeaver | http://localhost:8080 | app_schema | AppSchema123 | Web-based database client |
| CloudBeaver (Import) | http://localhost:8080 | EGFDMIS | EgfPass2017 | Access imported .dmp data |
| Oracle EM Express | http://localhost:5500/em | sys | OraclePassword123 | Oracle Enterprise Manager |

### Database Connections
| User | Password | Schema | Purpose |
|------|----------|--------|---------|
| sys | OraclePassword123 | - | System administrator |
| app_schema | AppSchema123 | Sample business data | Application development |
| EGFDMIS | EgfPass2017 | Imported .dmp data | Production data access |

### Connection Strings
```
# JDBC (Java)
jdbc:oracle:thin:@localhost:1521/XEPDB1

# Go-ora (Go)
oracle://app_schema:AppSchema123@localhost:1521/XEPDB1
oracle://EGFDMIS:EgfPass2017@localhost:1521/XEPDB1

# SQL*Plus
sqlplus app_schema/AppSchema123@localhost:1521/XEPDB1
sqlplus EGFDMIS/EgfPass2017@localhost:1521/XEPDB1
```

---

## 📊 Sample Data Structure

### app_schema Tables
- **departments**: 5 sample departments with locations and managers
- **employees**: 10 sample employees across departments
- **projects**: 5 sample projects with budgets and timelines
- **employee_projects**: Employee-project assignments with roles

### Available Database Objects
- **Sequences**: Auto-incrementing primary keys
- **Triggers**: Automatic ID generation and timestamp updates
- **Views**: `employee_details`, `project_summary`
- **Stored Procedures**: `get_employee_count`
- **Functions**: `get_department_budget`

---

## 🚨 Troubleshooting

### Database Won't Start
```powershell
# Check container logs
docker-compose logs oracle-db

# Remove corrupted volumes and restart
docker-compose down -v
docker volume rm oracledbconnection_oracle-data
docker-compose up -d oracle-db
```

### Web Interface Connection Issues
```powershell
# Verify database is accepting connections
"SELECT 1 FROM dual;" | docker exec -i oracle-xe-db sqlplus -s app_schema/AppSchema123@XEPDB1

# Check CloudBeaver container
docker-compose logs cloudbeaver

# Restart CloudBeaver
docker-compose restart cloudbeaver
```

### Import Issues
```powershell
# Check directory permissions
"SELECT directory_name, directory_path FROM dba_directories WHERE directory_name = 'IMPORT_DIR';" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba

# Verify .dmp files are accessible
docker exec oracle-xe-db ls -la /opt/oracle/import/

# Check import logs for errors
docker exec oracle-xe-db cat /opt/oracle/import/import_egf_full.log
```

### Java/Go Test Failures
```powershell
# Java - check Maven and Java versions
mvn --version
java --version

# Go - check Go version and dependencies
go version
go mod tidy

# Test direct database connection
docker exec -it oracle-xe-db sqlplus app_schema/AppSchema123@XEPDB1
```

---

## 🔄 Maintenance Tasks

### Daily Operations
```powershell
# Check database status
docker-compose ps

# View recent logs
docker-compose logs --tail 50 oracle-db

# Monitor container resources
docker stats oracle-xe-db oracle-cloudbeaver
```

### Weekly Maintenance
```powershell
# Check database size
"SELECT tablespace_name, ROUND(SUM(bytes)/1024/1024/1024,2) AS GB FROM dba_data_files GROUP BY tablespace_name;" | docker exec -i oracle-xe-db sqlplus -s sys/OraclePassword123@XEPDB1 as sysdba

# Update container images
docker-compose pull
docker-compose up -d --force-recreate

# Cleanup old logs
docker system prune -f
```

---

## 📚 Additional Resources

- **Project Documentation**: [README.md](./README.md)
- **Database Operations Guide**: [DATABASE_OPERATIONS.md](./DATABASE_OPERATIONS.md)
- **Import Scripts**: [scripts/README.md](./scripts/README.md)
- **Oracle Documentation**: [Oracle Database XE](https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinst/)
- **CloudBeaver Documentation**: [DBeaver CloudBeaver](https://cloudbeaver.io/)

---

## 🎉 Success Verification

After completing this setup, you should have:

✅ Oracle Database XE running in Docker  
✅ CloudBeaver web interface accessible at http://localhost:8080  
✅ Sample app_schema with business data  
✅ EGFDMIS user with imported .dmp data  
✅ Java connectivity test passing  
✅ Go connectivity test passing  
✅ Complete development environment ready  

**Congratulations! Your Oracle Database development environment is ready! 🚀**

---

*Last Updated: September 26, 2025*  
*Version: 1.0 - Complete Setup Guide*