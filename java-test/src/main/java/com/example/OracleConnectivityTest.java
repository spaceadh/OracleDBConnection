package com.example;

import java.sql.*;
import java.util.Properties;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

/**
 * Oracle Database Connectivity Test
 * Tests connection to Oracle XE running in Docker container
 */
public class OracleConnectivityTest {
    
    // Database connection parameters
    private static final String DB_URL = "jdbc:oracle:thin:@localhost:1521:XE";
    private static final String DB_USER = "app_schema";
    private static final String DB_PASSWORD = "AppSchema123";
    
    public static void main(String[] args) {
        System.out.println("=== Oracle Database Connectivity Test ===\n");
        
        // Test 1: Basic JDBC Connection
        testBasicConnection();
        
        // Test 2: Connection with Properties
        testConnectionWithProperties();
        
        // Test 3: Connection Pool Test
        testConnectionPool();
        
        // Test 4: Database Operations
        testDatabaseOperations();
        
        System.out.println("=== All tests completed ===");
    }
    
    /**
     * Test basic JDBC connection
     */
    private static void testBasicConnection() {
        System.out.println("1. Testing basic JDBC connection...");
        
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            if (conn != null && !conn.isClosed()) {
                System.out.println("✓ Basic connection successful!");
                
                // Get database metadata
                DatabaseMetaData metaData = conn.getMetaData();
                System.out.println("  Database: " + metaData.getDatabaseProductName());
                System.out.println("  Version: " + metaData.getDatabaseProductVersion());
                System.out.println("  Driver: " + metaData.getDriverName() + " " + metaData.getDriverVersion());
                System.out.println("  URL: " + metaData.getURL());
                System.out.println("  Username: " + metaData.getUserName());
            }
        } catch (SQLException e) {
            System.err.println("✗ Basic connection failed: " + e.getMessage());
            e.printStackTrace();
        }
        System.out.println();
    }
    
    /**
     * Test connection with additional properties
     */
    private static void testConnectionWithProperties() {
        System.out.println("2. Testing connection with properties...");
        
        Properties props = new Properties();
        props.setProperty("user", DB_USER);
        props.setProperty("password", DB_PASSWORD);
        props.setProperty("oracle.jdbc.ReadTimeout", "10000");
        props.setProperty("oracle.net.CONNECT_TIMEOUT", "10000");
        
        try (Connection conn = DriverManager.getConnection(DB_URL, props)) {
            if (conn != null && !conn.isClosed()) {
                System.out.println("✓ Connection with properties successful!");
                
                // Test a simple query
                try (Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery("SELECT 'Hello Oracle!' as message, SYSDATE as current_time FROM DUAL")) {
                    
                    if (rs.next()) {
                        System.out.println("  Message: " + rs.getString("message"));
                        System.out.println("  Server Time: " + rs.getTimestamp("current_time"));
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("✗ Connection with properties failed: " + e.getMessage());
        }
        System.out.println();
    }
    
    /**
     * Test connection pooling with HikariCP
     */
    private static void testConnectionPool() {
        System.out.println("3. Testing connection pool...");
        
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(DB_URL);
        config.setUsername(DB_USER);
        config.setPassword(DB_PASSWORD);
        config.setMaximumPoolSize(5);
        config.setMinimumIdle(2);
        config.setConnectionTimeout(30000);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        
        try (HikariDataSource dataSource = new HikariDataSource(config)) {
            System.out.println("✓ Connection pool created successfully!");
            
            // Test multiple connections
            for (int i = 1; i <= 3; i++) {
                try (Connection conn = dataSource.getConnection()) {
                    System.out.println("  Connection " + i + " acquired from pool");
                    
                    try (Statement stmt = conn.createStatement();
                         ResultSet rs = stmt.executeQuery("SELECT 'Pool Connection " + i + "' as message FROM DUAL")) {
                        
                        if (rs.next()) {
                            System.out.println("    " + rs.getString("message"));
                        }
                    }
                }
            }
            
            System.out.println("  Pool statistics:");
            System.out.println("    Active connections: " + dataSource.getHikariPoolMXBean().getActiveConnections());
            System.out.println("    Idle connections: " + dataSource.getHikariPoolMXBean().getIdleConnections());
            System.out.println("    Total connections: " + dataSource.getHikariPoolMXBean().getTotalConnections());
            
        } catch (SQLException e) {
            System.err.println("✗ Connection pool test failed: " + e.getMessage());
        }
        System.out.println();
    }
    
    /**
     * Test database operations on sample data
     */
    private static void testDatabaseOperations() {
        System.out.println("4. Testing database operations...");
        
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            
            // Test SELECT operation
            System.out.println("  Testing SELECT operations...");
            testSelectOperations(conn);
            
            // Test INSERT operation
            System.out.println("  Testing INSERT operation...");
            testInsertOperation(conn);
            
            // Test stored procedure call
            System.out.println("  Testing stored procedure call...");
            testStoredProcedure(conn);
            
            // Test function call
            System.out.println("  Testing function call...");
            testFunctionCall(conn);
            
        } catch (SQLException e) {
            System.err.println("✗ Database operations test failed: " + e.getMessage());
        }
        System.out.println();
    }
    
    private static void testSelectOperations(Connection conn) throws SQLException {
        // Query departments
        String sql = "SELECT dept_id, dept_name, location FROM departments ORDER BY dept_id";
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            System.out.println("    Departments:");
            while (rs.next()) {
                System.out.printf("      %d: %s (%s)%n", 
                    rs.getInt("dept_id"), 
                    rs.getString("dept_name"), 
                    rs.getString("location"));
            }
        }
        
        // Query employee count by department
        sql = "SELECT d.dept_name, COUNT(e.emp_id) as emp_count " +
              "FROM departments d LEFT JOIN employees e ON d.dept_id = e.dept_id " +
              "GROUP BY d.dept_name ORDER BY emp_count DESC";
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            System.out.println("    Employee count by department:");
            while (rs.next()) {
                System.out.printf("      %s: %d employees%n", 
                    rs.getString("dept_name"), 
                    rs.getInt("emp_count"));
            }
        }
    }
    
    private static void testInsertOperation(Connection conn) throws SQLException {
        String sql = "INSERT INTO employees (first_name, last_name, email, job_title, salary, dept_id) " +
                    "VALUES (?, ?, ?, ?, ?, ?)";
        
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, "Test");
            pstmt.setString(2, "User");
            pstmt.setString(3, "test.user@company.com");
            pstmt.setString(4, "Software Tester");
            pstmt.setDouble(5, 65000);
            pstmt.setInt(6, 1); // IT department
            
            int rowsAffected = pstmt.executeUpdate();
            System.out.println("    Inserted " + rowsAffected + " test employee record");
            
            // Clean up - delete the test record
            try (Statement stmt = conn.createStatement()) {
                stmt.executeUpdate("DELETE FROM employees WHERE email = 'test.user@company.com'");
                System.out.println("    Cleaned up test record");
            }
        }
    }
    
    private static void testStoredProcedure(Connection conn) throws SQLException {
        String sql = "{call get_employee_count(?, ?)}";
        
        try (CallableStatement cstmt = conn.prepareCall(sql)) {
            cstmt.setInt(1, 1); // IT department
            cstmt.registerOutParameter(2, Types.NUMERIC);
            
            cstmt.execute();
            int empCount = cstmt.getInt(2);
            System.out.println("    IT department has " + empCount + " employees");
        }
    }
    
    private static void testFunctionCall(Connection conn) throws SQLException {
        String sql = "SELECT get_department_budget(?) as budget FROM DUAL";
        
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, 1); // IT department
            
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    double budget = rs.getDouble("budget");
                    System.out.println("    IT department total budget: $" + String.format("%.2f", budget));
                }
            }
        }
    }
}