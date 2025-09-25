-- 02_sample_data.sql
-- Insert sample data into the created tables

-- Set the schema context
ALTER SESSION SET CURRENT_SCHEMA = app_schema;

-- Insert sample departments
INSERT INTO departments (dept_name, location, manager_id) VALUES 
    ('Information Technology', 'New York', NULL);
INSERT INTO departments (dept_name, location, manager_id) VALUES 
    ('Human Resources', 'Chicago', NULL);
INSERT INTO departments (dept_name, location, manager_id) VALUES 
    ('Finance', 'San Francisco', NULL);
INSERT INTO departments (dept_name, location, manager_id) VALUES 
    ('Marketing', 'Los Angeles', NULL);
INSERT INTO departments (dept_name, location, manager_id) VALUES 
    ('Operations', 'Seattle', NULL);

-- Insert sample employees
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('John', 'Smith', 'john.smith@company.com', '555-0101', 'IT Manager', 85000, 1);
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('Sarah', 'Johnson', 'sarah.johnson@company.com', '555-0102', 'Senior Developer', 75000, 1);
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('Michael', 'Brown', 'michael.brown@company.com', '555-0103', 'Database Administrator', 70000, 1);
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('Emily', 'Davis', 'emily.davis@company.com', '555-0201', 'HR Manager', 80000, 2);
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('David', 'Wilson', 'david.wilson@company.com', '555-0202', 'HR Specialist', 55000, 2);
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('Lisa', 'Anderson', 'lisa.anderson@company.com', '555-0301', 'Finance Manager', 90000, 3);
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('Robert', 'Taylor', 'robert.taylor@company.com', '555-0302', 'Financial Analyst', 60000, 3);
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('Jennifer', 'Martinez', 'jennifer.martinez@company.com', '555-0401', 'Marketing Manager', 82000, 4);
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('Christopher', 'Garcia', 'christopher.garcia@company.com', '555-0402', 'Marketing Specialist', 52000, 4);
INSERT INTO employees (first_name, last_name, email, phone, job_title, salary, dept_id) VALUES 
    ('Amanda', 'Rodriguez', 'amanda.rodriguez@company.com', '555-0501', 'Operations Manager', 88000, 5);

-- Update department managers
UPDATE departments SET manager_id = 1 WHERE dept_id = 1; -- John Smith for IT
UPDATE departments SET manager_id = 4 WHERE dept_id = 2; -- Emily Davis for HR
UPDATE departments SET manager_id = 6 WHERE dept_id = 3; -- Lisa Anderson for Finance
UPDATE departments SET manager_id = 8 WHERE dept_id = 4; -- Jennifer Martinez for Marketing
UPDATE departments SET manager_id = 10 WHERE dept_id = 5; -- Amanda Rodriguez for Operations

-- Insert sample projects
INSERT INTO projects (project_name, description, start_date, end_date, budget, status, dept_id) VALUES 
    ('Customer Portal Upgrade', 'Modernize the customer-facing web portal with new features', 
     DATE '2024-01-15', DATE '2024-06-30', 250000, 'ACTIVE', 1);
INSERT INTO projects (project_name, description, start_date, end_date, budget, status, dept_id) VALUES 
    ('HR Management System', 'Implement new HRMS for better employee management', 
     DATE '2024-02-01', DATE '2024-08-31', 180000, 'ACTIVE', 2);
INSERT INTO projects (project_name, description, start_date, end_date, budget, status, dept_id) VALUES 
    ('Financial Reporting Automation', 'Automate monthly and quarterly financial reports', 
     DATE '2024-03-01', DATE '2024-09-30', 120000, 'PLANNING', 3);
INSERT INTO projects (project_name, description, start_date, end_date, budget, status, dept_id) VALUES 
    ('Digital Marketing Campaign', 'Launch comprehensive digital marketing initiative', 
     DATE '2024-01-01', DATE '2024-12-31', 300000, 'ACTIVE', 4);
INSERT INTO projects (project_name, description, start_date, end_date, budget, status, dept_id) VALUES 
    ('Supply Chain Optimization', 'Optimize supply chain processes and reduce costs', 
     DATE '2023-10-01', DATE '2024-03-31', 200000, 'COMPLETED', 5);

-- Insert employee-project assignments
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (1, 1, 'Project Manager', 0.50, DATE '2024-01-15');
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (2, 1, 'Lead Developer', 0.80, DATE '2024-01-15');
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (3, 1, 'Database Specialist', 0.30, DATE '2024-01-20');
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (4, 2, 'Project Manager', 0.60, DATE '2024-02-01');
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (5, 2, 'Requirements Analyst', 0.70, DATE '2024-02-01');
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (6, 3, 'Project Manager', 0.40, DATE '2024-03-01');
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (7, 3, 'Financial Analyst', 0.90, DATE '2024-03-01');
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (8, 4, 'Project Manager', 0.70, DATE '2024-01-01');
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (9, 4, 'Marketing Specialist', 0.85, DATE '2024-01-01');
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES 
    (10, 5, 'Project Manager', 1.00, DATE '2023-10-01');

COMMIT;

-- Create some useful views for reporting
CREATE OR REPLACE VIEW employee_details AS
SELECT 
    e.emp_id,
    e.first_name || ' ' || e.last_name AS full_name,
    e.email,
    e.job_title,
    e.salary,
    d.dept_name,
    d.location,
    m.first_name || ' ' || m.last_name AS manager_name,
    e.hire_date,
    e.status
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN employees m ON e.manager_id = m.emp_id;

CREATE OR REPLACE VIEW project_summary AS
SELECT 
    p.project_id,
    p.project_name,
    p.status,
    p.start_date,
    p.end_date,
    p.budget,
    d.dept_name,
    COUNT(ep.emp_id) AS team_size,
    ROUND(AVG(ep.allocation_percentage), 2) AS avg_allocation
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employee_projects ep ON p.project_id = ep.project_id
GROUP BY p.project_id, p.project_name, p.status, p.start_date, p.end_date, p.budget, d.dept_name;

-- Create some sample stored procedures
CREATE OR REPLACE PROCEDURE get_employee_count(
    p_dept_id IN NUMBER DEFAULT NULL,
    p_count OUT NUMBER
) AS
BEGIN
    IF p_dept_id IS NULL THEN
        SELECT COUNT(*) INTO p_count FROM employees WHERE status = 'ACTIVE';
    ELSE
        SELECT COUNT(*) INTO p_count FROM employees 
        WHERE dept_id = p_dept_id AND status = 'ACTIVE';
    END IF;
END;
/

CREATE OR REPLACE FUNCTION get_department_budget(p_dept_id IN NUMBER) 
RETURN NUMBER AS
    v_total_budget NUMBER := 0;
BEGIN
    SELECT NVL(SUM(budget), 0) INTO v_total_budget
    FROM projects 
    WHERE dept_id = p_dept_id AND status IN ('ACTIVE', 'PLANNING');
    
    RETURN v_total_budget;
END;
/

COMMIT;