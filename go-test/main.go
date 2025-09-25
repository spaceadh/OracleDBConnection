package main

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/sijms/go-ora/v2"
)

// Database connection parameters
const (
	dbURL = "oracle://app_schema:AppSchema123@localhost:1521/XEPDB1"
)

// Employee represents an employee record
type Employee struct {
	ID        int       `json:"id"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Email     string    `json:"email"`
	JobTitle  string    `json:"job_title"`
	Salary    float64   `json:"salary"`
	DeptID    int       `json:"dept_id"`
	HireDate  time.Time `json:"hire_date"`
	Status    string    `json:"status"`
}

// Department represents a department record
type Department struct {
	ID        int    `json:"id"`
	Name      string `json:"name"`
	Location  string `json:"location"`
	ManagerID *int   `json:"manager_id"`
}

func main() {
	fmt.Println("=== Oracle Database Connectivity Test (Go) ===\n")

	// Test 1: Basic connection
	testBasicConnection()

	// Test 2: Query operations
	testQueryOperations()

	// Test 3: Transaction handling
	testTransactionHandling()

	// Test 4: Prepared statements
	testPreparedStatements()

	// Test 5: Stored procedures and functions
	testStoredProceduresAndFunctions()

	fmt.Println("=== All Go tests completed ===")
}

// testBasicConnection tests basic database connectivity
func testBasicConnection() {
	fmt.Println("1. Testing basic database connection...")

	db, err := sql.Open("oracle", dbURL)
	if err != nil {
		log.Printf("✗ Failed to open database connection: %v", err)
		return
	}
	defer db.Close()

	// Set connection pool settings
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(time.Hour)

	// Test the connection
	if err := db.Ping(); err != nil {
		log.Printf("✗ Failed to ping database: %v", err)
		return
	}

	fmt.Println("✓ Basic connection successful!")

	// Get database version
	var version string
	err = db.QueryRow("SELECT BANNER FROM V$VERSION WHERE ROWNUM = 1").Scan(&version)
	if err != nil {
		log.Printf("✗ Failed to get database version: %v", err)
		return
	}

	fmt.Printf("  Database version: %s\n", version)

	// Test simple query
	var message string
	var currentTime time.Time
	err = db.QueryRow("SELECT 'Hello Oracle from Go!' as message, SYSDATE as current_time FROM DUAL").
		Scan(&message, &currentTime)
	if err != nil {
		log.Printf("✗ Failed to execute test query: %v", err)
		return
	}

	fmt.Printf("  Message: %s\n", message)
	fmt.Printf("  Server time: %s\n", currentTime.Format("2006-01-02 15:04:05"))
	fmt.Println()
}

// testQueryOperations tests various query operations
func testQueryOperations() {
	fmt.Println("2. Testing query operations...")

	db, err := sql.Open("oracle", dbURL)
	if err != nil {
		log.Printf("✗ Failed to open database connection: %v", err)
		return
	}
	defer db.Close()

	// Query departments
	fmt.Println("  Querying departments...")
	departments, err := getDepartments(db)
	if err != nil {
		log.Printf("✗ Failed to query departments: %v", err)
		return
	}

	for _, dept := range departments {
		managerInfo := "No manager"
		if dept.ManagerID != nil {
			managerInfo = fmt.Sprintf("Manager ID: %d", *dept.ManagerID)
		}
		fmt.Printf("    %d: %s (%s) - %s\n", dept.ID, dept.Name, dept.Location, managerInfo)
	}

	// Query employees
	fmt.Println("  Querying employees...")
	employees, err := getEmployees(db, 5) // Limit to 5 employees
	if err != nil {
		log.Printf("✗ Failed to query employees: %v", err)
		return
	}

	for _, emp := range employees {
		fmt.Printf("    %d: %s %s (%s) - $%.2f\n",
			emp.ID, emp.FirstName, emp.LastName, emp.JobTitle, emp.Salary)
	}

	fmt.Println("✓ Query operations successful!")
	fmt.Println()
}

// testTransactionHandling tests transaction management
func testTransactionHandling() {
	fmt.Println("3. Testing transaction handling...")

	db, err := sql.Open("oracle", dbURL)
	if err != nil {
		log.Printf("✗ Failed to open database connection: %v", err)
		return
	}
	defer db.Close()

	// Start a transaction
	tx, err := db.Begin()
	if err != nil {
		log.Printf("✗ Failed to begin transaction: %v", err)
		return
	}

	// Insert a test employee
	_, err = tx.Exec(`INSERT INTO employees (first_name, last_name, email, job_title, salary, dept_id) 
		VALUES ('Go', 'Tester', 'go.tester@company.com', 'Go Developer', 70000, 1)`)
	if err != nil {
		tx.Rollback()
		log.Printf("✗ Failed to insert test employee: %v", err)
		return
	}

	fmt.Println("  Inserted test employee in transaction")

	// Query the inserted employee (should be visible within transaction)
	var count int
	err = tx.QueryRow("SELECT COUNT(*) FROM employees WHERE email = 'go.tester@company.com'").Scan(&count)
	if err != nil {
		tx.Rollback()
		log.Printf("✗ Failed to query within transaction: %v", err)
		return
	}

	fmt.Printf("  Found %d test employee(s) within transaction\n", count)

	// Rollback the transaction
	err = tx.Rollback()
	if err != nil {
		log.Printf("✗ Failed to rollback transaction: %v", err)
		return
	}

	fmt.Println("  Transaction rolled back")

	// Verify the employee was not committed
	err = db.QueryRow("SELECT COUNT(*) FROM employees WHERE email = 'go.tester@company.com'").Scan(&count)
	if err != nil {
		log.Printf("✗ Failed to verify rollback: %v", err)
		return
	}

	fmt.Printf("  Found %d test employee(s) after rollback\n", count)
	fmt.Println("✓ Transaction handling successful!")
	fmt.Println()
}

// testPreparedStatements tests prepared statement functionality
func testPreparedStatements() {
	fmt.Println("4. Testing prepared statements...")

	db, err := sql.Open("oracle", dbURL)
	if err != nil {
		log.Printf("✗ Failed to open database connection: %v", err)
		return
	}
	defer db.Close()

	// Prepare a statement
	stmt, err := db.Prepare("SELECT emp_id, first_name, last_name, salary FROM employees WHERE dept_id = ? AND salary > ?")
	if err != nil {
		log.Printf("✗ Failed to prepare statement: %v", err)
		return
	}
	defer stmt.Close()

	// Execute with different parameters
	rows, err := stmt.Query(1, 70000) // IT department, salary > 70000
	if err != nil {
		log.Printf("✗ Failed to execute prepared statement: %v", err)
		return
	}
	defer rows.Close()

	fmt.Println("  IT employees with salary > $70,000:")
	for rows.Next() {
		var empID int
		var firstName, lastName string
		var salary float64

		err := rows.Scan(&empID, &firstName, &lastName, &salary)
		if err != nil {
			log.Printf("✗ Failed to scan row: %v", err)
			continue
		}

		fmt.Printf("    %d: %s %s - $%.2f\n", empID, firstName, lastName, salary)
	}

	if err = rows.Err(); err != nil {
		log.Printf("✗ Error iterating rows: %v", err)
		return
	}

	fmt.Println("✓ Prepared statements successful!")
	fmt.Println()
}

// testStoredProceduresAndFunctions tests calling stored procedures and functions
func testStoredProceduresAndFunctions() {
	fmt.Println("5. Testing stored procedures and functions...")

	db, err := sql.Open("oracle", dbURL)
	if err != nil {
		log.Printf("✗ Failed to open database connection: %v", err)
		return
	}
	defer db.Close()

	// Test stored procedure - get_employee_count
	fmt.Println("  Testing stored procedure (get_employee_count)...")
	var empCount int
	_, err = db.Exec("BEGIN get_employee_count(1, :1); END;", sql.Out{Dest: &empCount})
	if err != nil {
		log.Printf("✗ Failed to call stored procedure: %v", err)
	} else {
		fmt.Printf("    IT department has %d employees\n", empCount)
	}

	// Test function - get_department_budget
	fmt.Println("  Testing function (get_department_budget)...")
	var budget float64
	err = db.QueryRow("SELECT get_department_budget(1) FROM DUAL").Scan(&budget)
	if err != nil {
		log.Printf("✗ Failed to call function: %v", err)
	} else {
		fmt.Printf("    IT department total budget: $%.2f\n", budget)
	}

	fmt.Println("✓ Stored procedures and functions successful!")
	fmt.Println()
}

// getDepartments retrieves all departments
func getDepartments(db *sql.DB) ([]Department, error) {
	rows, err := db.Query("SELECT dept_id, dept_name, location, manager_id FROM departments ORDER BY dept_id")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var departments []Department
	for rows.Next() {
		var dept Department
		var managerID sql.NullInt64

		err := rows.Scan(&dept.ID, &dept.Name, &dept.Location, &managerID)
		if err != nil {
			return nil, err
		}

		if managerID.Valid {
			managerIDInt := int(managerID.Int64)
			dept.ManagerID = &managerIDInt
		}

		departments = append(departments, dept)
	}

	return departments, rows.Err()
}

// getEmployees retrieves employees with optional limit
func getEmployees(db *sql.DB, limit int) ([]Employee, error) {
	query := "SELECT emp_id, first_name, last_name, email, job_title, salary, dept_id, hire_date, status FROM employees"
	if limit > 0 {
		query += fmt.Sprintf(" WHERE ROWNUM <= %d", limit)
	}
	query += " ORDER BY emp_id"

	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var employees []Employee
	for rows.Next() {
		var emp Employee

		err := rows.Scan(&emp.ID, &emp.FirstName, &emp.LastName, &emp.Email,
			&emp.JobTitle, &emp.Salary, &emp.DeptID, &emp.HireDate, &emp.Status)
		if err != nil {
			return nil, err
		}

		employees = append(employees, emp)
	}

	return employees, rows.Err()
}
