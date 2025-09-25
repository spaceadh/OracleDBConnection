-- 01_create_schemas.sql
-- This script creates sample schemas and tables for development

-- Create development schema and user
CREATE USER oracleUser2 IDENTIFIED BY strongPassword123
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

-- Grant necessary privileges
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SYNONYM TO oracleUser2;
GRANT CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER TO oracleUser2;

-- Connect as the new user for subsequent operations
ALTER SESSION SET CURRENT_SCHEMA = oracleUser2;

-- Create sample tables
CREATE TABLE departments (
    dept_id NUMBER(10) PRIMARY KEY,
    dept_name VARCHAR2(100) NOT NULL,
    location VARCHAR2(100),
    manager_id NUMBER(10),
    created_date DATE DEFAULT SYSDATE,
    active_flag CHAR(1) DEFAULT 'Y' CHECK (active_flag IN ('Y', 'N'))
);

CREATE TABLE employees (
    emp_id NUMBER(10) PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    hire_date DATE DEFAULT SYSDATE,
    job_title VARCHAR2(100),
    salary NUMBER(10,2),
    dept_id NUMBER(10),
    manager_id NUMBER(10),
    status VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'TERMINATED')),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_emp_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    CONSTRAINT fk_emp_manager FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

CREATE TABLE projects (
    project_id NUMBER(10) PRIMARY KEY,
    project_name VARCHAR2(200) NOT NULL,
    description CLOB,
    start_date DATE,
    end_date DATE,
    budget NUMBER(12,2),
    status VARCHAR2(20) DEFAULT 'PLANNING' CHECK (status IN ('PLANNING', 'ACTIVE', 'ON_HOLD', 'COMPLETED', 'CANCELLED')),
    dept_id NUMBER(10),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_proj_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE employee_projects (
    emp_id NUMBER(10),
    project_id NUMBER(10),
    role VARCHAR2(100),
    allocation_percentage NUMBER(3,2) DEFAULT 1.00,
    start_date DATE DEFAULT SYSDATE,
    end_date DATE,
    PRIMARY KEY (emp_id, project_id),
    CONSTRAINT fk_emp_proj_emp FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    CONSTRAINT fk_emp_proj_proj FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

-- Create sequences for primary keys
CREATE SEQUENCE dept_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE emp_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE proj_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- Create triggers for auto-incrementing primary keys
CREATE OR REPLACE TRIGGER dept_trigger
    BEFORE INSERT ON departments
    FOR EACH ROW
BEGIN
    IF :NEW.dept_id IS NULL THEN
        :NEW.dept_id := dept_seq.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER emp_trigger
    BEFORE INSERT ON employees
    FOR EACH ROW
BEGIN
    IF :NEW.emp_id IS NULL THEN
        :NEW.emp_id := emp_seq.NEXTVAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER proj_trigger
    BEFORE INSERT ON projects
    FOR EACH ROW
BEGIN
    IF :NEW.project_id IS NULL THEN
        :NEW.project_id := proj_seq.NEXTVAL;
    END IF;
END;
/

-- Create trigger to update the updated_date column
CREATE OR REPLACE TRIGGER emp_update_trigger
    BEFORE UPDATE ON employees
    FOR EACH ROW
BEGIN
    :NEW.updated_date := CURRENT_TIMESTAMP;
END;
/

COMMIT;