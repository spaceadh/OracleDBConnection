# Oracle Database Docker Development Environment

A complete Oracle Database development environment using Docker, with connectivity tests in Java and Go, plus comprehensive database management tools.

## 🚀 Quick Start

### Prerequisites

- **Docker** (v20.0+ recommended)
- **Docker Compose** (v2.0+ recommended)
- **Java 11+** (for Java tests)
- **Go 1.21+** (for Go tests)
- **Maven 3.6+** (for Java project)

### 1. Start the Database

```powershell
# Clone or navigate to the project directory
cd d:\Personal\OracleDBConnection

# Start Oracle Database and Adminer
docker-compose up -d

# Check container status
docker-compose ps
```

### 2. Wait for Database Initialization

The Oracle database takes 2-3 minutes to fully initialize on first startup. Monitor the logs:

Access Adminer: http://localhost:8080

System: Oracle
Server: oracle-db:1521/XEPDB1
Username: app_schema
Password: AppSchema123

```powershell
# Watch database startup logs
docker-compose logs -f oracle-db

# Wait for this message: "DATABASE IS READY TO USE!"
```

### 3. Access Database Management Tools

**Adminer Web Interface:**
- URL: http://localhost:8080
- System: Oracle
- Server: oracle-db:1521/XEPDB1
- Username: `app_schema`
- Password: `AppSchema123`

**Oracle Enterprise Manager (Optional):**
- URL: http://localhost:5500/em
- Username: `sys` (as SYSDBA)
- Password: `OraclePassword123`

## 🧪 Running Connectivity Tests

### Java Test

```powershell
cd java-test

# Compile and run the connectivity test
mvn clean compile exec:java

# Or run with Maven lifecycle
mvn clean test
```

### Go Test

```powershell
cd go-test

# Download dependencies
go mod tidy

# Run the connectivity test
go run main.go

# Or build and run
go build -o oracle-test.exe
.\oracle-test.exe
```

## 📊 Sample Database Schema

The database includes a complete sample schema with:

### Tables
- **departments**: Company departments with locations and managers
- **employees**: Employee records with job titles, salaries, and department assignments
- **projects**: Company projects with budgets and timelines
- **employee_projects**: Many-to-many relationship between employees and projects

### Sample Data
- 5 departments (IT, HR, Finance, Marketing, Operations)
- 10 employees across different departments
- 5 projects in various stages
- Employee-project assignments with roles and allocation percentages

### Database Objects
- **Sequences**: Auto-incrementing primary keys
- **Triggers**: Automatic ID generation and timestamp updates
- **Views**: `employee_details` and `project_summary` for reporting
- **Stored Procedures**: `get_employee_count` for department statistics
- **Functions**: `get_department_budget` for financial calculations

## 🔧 Database Connection Details

### Connection Strings

**JDBC (Java):**
```
jdbc:oracle:thin:@localhost:1521:XE
```

**Go-ora (Go):**
```
oracle://app_schema:AppSchema123@localhost:1521/XE
```

**SQL*Plus:**
```powershell
docker exec -it oracle-xe-db sqlplus app_schema/AppSchema123@XEPDB1
```

### User Accounts

| Username | Password | Role | Description |
|----------|----------|------|-------------|
| `sys` | `OraclePassword123` | SYSDBA | System administrator |
| `system` | `OraclePassword123` | DBA | System user |
| `app_schema` | `AppSchema123` | Application | Application schema owner |

## 🛠️ Management Commands

### Container Management

```powershell
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart database only
docker-compose restart oracle-db

# View logs
docker-compose logs oracle-db
docker-compose logs adminer

# Access database shell
docker exec -it oracle-xe-db bash
docker exec -it oracle-xe-db sqlplus / as sysdba
```

### Database Operations

```powershell
# Connect to database
docker exec -it oracle-xe-db sqlplus app_schema/AppSchema123@XEPDB1

# Run SQL script
docker exec -i oracle-xe-db sqlplus app_schema/AppSchema123@XEPDB1 < your-script.sql

# Check database status
docker exec oracle-xe-db sqlplus -s / as sysdba <<< "SELECT status FROM v\$instance;"
```

## 📁 Project Structure

```
oracle-db-docker-project/
├── docker-compose.yml              # Docker services configuration
├── db-init-scripts/                # Database initialization scripts
│   ├── 01_create_schemas.sql       # Schema, tables, and database objects
│   └── 02_sample_data.sql          # Sample data and views
├── java-test/                      # Java connectivity test
│   ├── pom.xml                     # Maven configuration
│   └── src/main/java/com/example/
│       └── OracleConnectivityTest.java
├── go-test/                        # Go connectivity test
│   ├── go.mod                      # Go module definition
│   └── main.go                     # Go test application
├── README.md                       # This file
└── DATABASE_OPERATIONS.md          # Detailed database operations guide
```

## 🔍 Testing Features

### Java Test Features
- ✅ Basic JDBC connection
- ✅ Connection with properties
- ✅ HikariCP connection pooling
- ✅ CRUD operations
- ✅ Prepared statements
- ✅ Stored procedure calls
- ✅ Function calls
- ✅ Transaction management

### Go Test Features
- ✅ Basic database connection
- ✅ Query operations
- ✅ Transaction handling
- ✅ Prepared statements
- ✅ Stored procedures and functions
- ✅ Connection pooling
- ✅ Error handling

## 🚨 Troubleshooting

### Common Issues

**Database won't start:**
```powershell
# Check container logs
docker-compose logs oracle-db

# Remove volumes and restart
docker-compose down -v
docker-compose up -d
```

**Connection refused:**
```powershell
# Wait for database to fully initialize
docker-compose logs -f oracle-db

# Check if port is accessible
Test-NetConnection localhost -Port 1521
```

**Java test fails:**
```powershell
# Ensure Maven is installed
mvn --version

# Check Java version
java --version

# Clean and rebuild
mvn clean compile
```

**Go test fails:**
```powershell
# Ensure Go is installed
go version

# Clean module cache
go clean -modcache
go mod tidy
```

### Performance Tuning

**For development environments:**
```yaml
# Add to oracle-db service in docker-compose.yml
environment:
  - ORACLE_CHARACTERSET=AL32UTF8
  - ORACLE_EDITION=XE
  - INIT_SGA_SIZE=512M
  - INIT_PGA_SIZE=256M
```

## 📚 Additional Resources

- [Oracle Database XE Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinst/)
- [Oracle JDBC Driver Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/jjdbc/)
- [go-ora Driver Documentation](https://github.com/sijms/go-ora)
- [HikariCP Configuration](https://github.com/brettwooldridge/HikariCP)

## 📄 License

This project is provided as-is for development and educational purposes.

---

**Happy Oracle Development! 🎉**