-- =====================================================================
-- BANKING MANAGEMENT SYSTEM - COMPLETE MYSQL 8.0+ PROJECT
-- Based on the supplied Banking Management SQL Project requirements.
-- =====================================================================
-- Notes:
-- 1) Recreates bank_db from scratch.
-- 2) SQL_SAFE_UPDATES is disabled only for this session and restored at end.
-- 3) DCL commands are included but commented because admin/root is required.
-- 4) Invalid-trigger test and final DROP DATABASE are intentionally commented.
-- =====================================================================

SET @original_sql_safe_updates = @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;

DROP DATABASE IF EXISTS bank_db;
CREATE DATABASE bank_db;
USE bank_db;

-- ===================================================================================================================================

-- =====================================================================
-- 1. DATABASE & TABLE BASICS
-- =====================================================================

CREATE TABLE branches (
    branch_id INT PRIMARY KEY AUTO_INCREMENT,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(60) NOT NULL,
    ifsc_code VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_branch_name UNIQUE (branch_name),
    CONSTRAINT uq_branch_ifsc UNIQUE (ifsc_code)
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    city VARCHAR(60) NOT NULL,
    registered_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    CONSTRAINT uq_customer_email UNIQUE (email),
    CONSTRAINT uq_customer_phone UNIQUE (phone),
    CONSTRAINT chk_customer_status CHECK (status IN ('Active','Inactive','Suspended'))
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL,
    phone VARCHAR(20),
    branch_id INT NOT NULL,
    manager_id INT NULL,
    job_title VARCHAR(80) NOT NULL,
    salary DECIMAL(12,2) NOT NULL,
    hire_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT uq_employee_email UNIQUE (email),
    CONSTRAINT chk_employee_salary CHECK (salary >= 0),
    CONSTRAINT fk_employee_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT fk_employee_manager FOREIGN KEY (manager_id) REFERENCES employees(employee_id) ON DELETE SET NULL
);

CREATE TABLE accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    account_number VARCHAR(20) NOT NULL,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    account_type VARCHAR(30) NOT NULL,
    balance DECIMAL(14,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    opened_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    last_activity_date DATE NULL,
    CONSTRAINT uq_account_number UNIQUE (account_number),
    CONSTRAINT chk_account_type CHECK (account_type IN ('Savings','Current','Fixed Deposit')),
    CONSTRAINT chk_account_balance CHECK (balance >= 0),
    CONSTRAINT chk_account_status CHECK (status IN ('Active','Inactive','Frozen','Closed')),
    CONSTRAINT fk_account_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_account_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

CREATE TABLE transactions (
    transaction_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    account_id INT NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    amount DECIMAL(14,2) NOT NULL,
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(255) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Completed',
    transfer_reference VARCHAR(50) NULL,
    CONSTRAINT chk_transaction_type CHECK (transaction_type IN ('Deposit','Withdrawal','Debit','Credit','Transfer Out','Transfer In')),
    CONSTRAINT chk_transaction_amount CHECK (amount > 0),
    CONSTRAINT chk_transaction_status CHECK (status IN ('Completed','Pending','Failed')),
    CONSTRAINT fk_transaction_account FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE beneficiaries (
    beneficiary_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    beneficiary_name VARCHAR(100) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(30) NOT NULL,
    ifsc_code VARCHAR(20) NOT NULL,
    added_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_beneficiary_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE loans (
    loan_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    loan_type VARCHAR(40) NOT NULL,
    principal_amount DECIMAL(14,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_loan_principal CHECK (principal_amount > 0),
    CONSTRAINT chk_loan_interest CHECK (interest_rate >= 0),
    CONSTRAINT chk_loan_dates CHECK (end_date > start_date),
    CONSTRAINT chk_loan_status CHECK (status IN ('Active','Closed','Defaulted')),
    CONSTRAINT fk_loan_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_loan_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

CREATE TABLE loan_payments (
    loan_payment_id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id INT NOT NULL,
    amount DECIMAL(14,2) NOT NULL,
    payment_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    payment_method VARCHAR(30) NOT NULL DEFAULT 'Bank Transfer',
    CONSTRAINT chk_loan_payment_amount CHECK (amount > 0),
    CONSTRAINT fk_loan_payment_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE
);

CREATE TABLE cards (
    card_id INT PRIMARY KEY AUTO_INCREMENT,
    account_id INT NOT NULL,
    card_number VARCHAR(19) NOT NULL,
    card_type VARCHAR(20) NOT NULL,
    expiry_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    daily_limit DECIMAL(12,2) NOT NULL DEFAULT 50000,
    CONSTRAINT uq_card_number UNIQUE (card_number),
    CONSTRAINT chk_card_type CHECK (card_type IN ('Debit','Credit')),
    CONSTRAINT chk_card_status CHECK (status IN ('Active','Blocked','Expired')),
    CONSTRAINT chk_card_limit CHECK (daily_limit > 0),
    CONSTRAINT fk_card_account FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE CASCADE
);

CREATE TABLE audit_logs (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(60) NOT NULL,
    action_type VARCHAR(30) NOT NULL,
    record_id BIGINT NULL,
    old_value TEXT NULL,
    new_value TEXT NULL,
    log_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DESCRIBE customers;
DESCRIBE branches;
DESCRIBE employees;
DESCRIBE accounts;
DESCRIBE transactions;
DESCRIBE beneficiaries;
DESCRIBE loans;
DESCRIBE loan_payments;
DESCRIBE cards;
DESCRIBE audit_logs;

-- ===================================================================================================================================

-- =====================================================================
-- 2. SAMPLE DATA
-- =====================================================================

INSERT INTO branches (branch_name, city, ifsc_code) VALUES
('Jubilee Hills Branch','Hyderabad','BANK0001001'),
('Banjara Hills Branch','Hyderabad','BANK0001002'),
('Secunderabad Branch','Secunderabad','BANK0001003'),
('Gachibowli Branch','Hyderabad','BANK0001004'),
('Kukatpally Branch','Hyderabad','BANK0001005');

INSERT INTO customers (customer_name,email,phone,city,registered_date,status) VALUES
('Arjun Reddy','arjun.reddy@example.com','9000000001','Hyderabad','2025-11-10','Active'),
('Ananya Sharma','ananya.sharma@example.com','9000000002','Hyderabad','2025-12-15','Active'),
('Vikram Rao','vikram.rao@example.com','9000000003','Secunderabad','2026-01-05','Active'),
('Kavya Nair','kavya.nair@example.com','9000000004','Bengaluru','2026-01-20','Active'),
('Rohit Mehta','rohit.mehta@example.com','9000000005','Mumbai','2026-02-02','Active'),
('Sneha Iyer','sneha.iyer@example.com','9000000006','Hyderabad','2026-02-18','Active'),
('Aditya Verma','aditya.verma@example.com','9000000007','Pune','2026-03-01','Active'),
('Meera Joshi','meera.joshi@example.com','9000000008','Chennai','2026-03-15','Active'),
('Nikhil Kumar','nikhil.kumar@example.com','9000000009','Hyderabad','2026-04-01','Inactive'),
('Priya Singh','priya.singh@example.com','9000000010','Delhi','2026-04-12','Active'),
('Aman Gupta','aman.gupta@example.com','9000000011','Hyderabad','2026-04-22','Active'),
('Divya Reddy','divya.reddy@example.com','9000000012','Secunderabad','2026-05-01','Active'),
('Rahul Das','rahul.das@example.com','9000000013','Kolkata','2026-05-15','Active'),
('Pooja Shah','pooja.shah@example.com','9000000014','Ahmedabad','2026-06-01','Active'),
('Akash Jain','akash.jain@example.com','9000000015','Hyderabad','2026-06-18','Active'),
('Neha Kapoor','neha.kapoor@example.com','9000000016','Delhi','2026-07-02','Active'),
('Sanjay Rao','sanjay.rao@example.com','9000000017','Hyderabad','2026-07-20','Active'),
('Aisha Khan','aisha.khan@example.com','9000000018','Mumbai',DATE_SUB(CURDATE(),INTERVAL 25 DAY),'Active'),
('Kiran Patel','kiran.patel@example.com','9000000019','Hyderabad',DATE_SUB(CURDATE(),INTERVAL 10 DAY),'Active'),
('Maya Thomas','maya.thomas@example.com','9000000020','Kochi',DATE_SUB(CURDATE(),INTERVAL 5 DAY),'Active');

INSERT INTO employees (employee_name,email,phone,branch_id,manager_id,job_title,salary,hire_date) VALUES
('Anita Rao','anita.rao@bank.com','9100000001',1,NULL,'Branch Manager',95000,'2021-01-10');

INSERT INTO employees (employee_name,email,phone,branch_id,manager_id,job_title,salary,hire_date) VALUES
('Kiran Reddy','kiran.reddy@bank.com','9100000002',1,1,'Relationship Manager',60000,'2022-03-05'),
('Megha Das','megha.das@bank.com','9100000003',1,1,'Account Officer',62000,'2022-08-19'),
('Ravi Kumar','ravi.kumar@bank.com','9100000004',1,1,'Cashier',58000,'2023-02-11'),
('Sneha Bose','sneha.bose@bank.com','9100000005',1,1,'Senior Analyst',105000,'2020-06-25'),
('Suresh Nair','suresh.nair@bank.com','9100000006',2,NULL,'Branch Manager',90000,'2021-04-15');

INSERT INTO employees (employee_name,email,phone,branch_id,manager_id,job_title,salary,hire_date) VALUES
('Pooja Rao','pooja.rao@bank.com','9100000007',2,6,'Account Officer',55000,'2023-05-10'),
('Naveen Shah','naveen.shah@bank.com','9100000008',3,NULL,'Branch Manager',85000,'2021-09-01');

INSERT INTO employees (employee_name,email,phone,branch_id,manager_id,job_title,salary,hire_date) VALUES
('Divya Nair','divya.nair@bank.com','9100000009',3,8,'Relationship Manager',57000,'2024-01-18'),
('Arvind Menon','arvind.menon@bank.com','9100000010',4,NULL,'Branch Manager',88000,'2022-02-14');

INSERT INTO accounts (account_number,customer_id,branch_id,account_type,balance,status,opened_date,last_activity_date) VALUES
('100000000001',1,1,'Savings',125000,'Active','2025-11-12','2026-09-20'),
('100000000002',2,1,'Current',85000,'Active','2025-12-18','2026-09-18'),
('100000000003',3,1,'Savings',47000,'Active','2026-01-06','2026-09-10'),
('100000000004',4,1,'Fixed Deposit',250000,'Active','2026-01-22','2026-08-30'),
('100000000005',5,1,'Savings',66000,'Active','2026-02-05','2026-09-15'),
('100000000006',6,1,'Current',92000,'Active','2026-02-20','2026-09-21'),
('100000000007',7,2,'Savings',15000,'Inactive','2026-03-05','2026-05-01'),
('100000000008',8,2,'Current',180000,'Active','2026-03-18','2026-09-19'),
('100000000009',9,2,'Savings',54000,'Active','2026-04-03','2026-09-12'),
('100000000010',10,2,'Fixed Deposit',310000,'Active','2026-04-14','2026-08-28'),
('100000000011',11,2,'Savings',73500,'Active','2026-04-25','2026-09-17'),
('100000000012',12,2,'Current',99000,'Active','2026-05-03','2026-09-20'),
('100000000013',13,3,'Savings',44500,'Active','2026-05-18','2026-09-08'),
('100000000014',14,3,'Current',28000,'Inactive','2026-06-03','2026-06-30'),
('100000000015',15,3,'Savings',88000,'Active','2026-06-20','2026-09-16'),
('100000000016',16,3,'Fixed Deposit',420000,'Active','2026-07-04','2026-08-25'),
('100000000017',17,3,'Savings',61000,'Active','2026-07-22','2026-09-13'),
('100000000018',18,3,'Current',132000,'Active','2026-08-02','2026-09-19'),
('100000000019',1,4,'Current',215000,'Active','2026-01-10','2026-09-22'),
('100000000020',2,4,'Savings',37500,'Active','2026-02-01','2026-09-11'),
('100000000021',3,4,'Fixed Deposit',520000,'Active','2026-02-14','2026-08-20'),
('100000000022',4,4,'Savings',12000,'Inactive','2026-03-01','2026-04-10'),
('100000000023',5,4,'Current',145000,'Active','2026-03-22','2026-09-09'),
('100000000024',6,4,'Savings',76000,'Active','2026-04-04','2026-09-14'),
('100000000025',7,5,'Current',68000,'Active','2026-04-18','2026-09-05'),
('100000000026',8,5,'Savings',105000,'Active','2026-05-02','2026-09-20'),
('100000000027',9,5,'Fixed Deposit',600000,'Active','2026-05-21','2026-08-15'),
('100000000028',10,5,'Savings',56500,'Active','2026-06-05','2026-09-07'),
('100000000029',11,5,'Current',199000,'Active','2026-06-25','2026-09-18'),
('100000000030',12,5,'Savings',33000,'Frozen','2026-07-01',NULL);

INSERT INTO transactions (account_id,transaction_type,amount,transaction_date,description,status,transfer_reference) VALUES
(1,'Deposit',25000,'2026-01-05 10:15:00','Salary credit','Completed',NULL),
(1,'Debit',6000,'2026-01-12 14:10:00','Shopping','Completed',NULL),
(2,'Deposit',40000,'2026-01-18 11:00:00','Business receipt','Completed',NULL),
(2,'Withdrawal',12000,'2026-01-28 16:20:00',NULL,'Completed',NULL),
(3,'Credit',15000,'2026-02-03 09:30:00','Refund','Completed',NULL),
(3,'Debit',3500,'2026-02-09 18:00:00','Utility bill','Completed',NULL),
(4,'Deposit',50000,'2026-02-14 12:45:00','FD top-up','Completed',NULL),
(5,'Withdrawal',8000,'2026-02-20 13:10:00','ATM withdrawal','Completed',NULL),
(6,'Deposit',22000,'2026-02-25 10:40:00','Salary','Completed',NULL),
(6,'Debit',7500,'2026-03-02 17:30:00',NULL,'Completed',NULL),
(7,'Deposit',10000,'2026-03-05 10:00:00','Cash deposit','Completed',NULL),
(8,'Credit',32000,'2026-03-10 11:15:00','Client payment','Completed',NULL),
(8,'Debit',9500,'2026-03-15 15:10:00','Insurance','Completed',NULL),
(9,'Deposit',18000,'2026-03-22 09:45:00','Salary','Completed',NULL),
(10,'Credit',45000,'2026-04-01 12:05:00','Interest credit','Completed',NULL),
(11,'Debit',11000,'2026-04-05 19:20:00','Travel booking','Completed',NULL),
(12,'Deposit',27000,'2026-04-12 10:10:00','Business deposit','Completed',NULL),
(12,'Withdrawal',5000,'2026-04-16 13:40:00',NULL,'Completed',NULL),
(13,'Deposit',16000,'2026-04-25 11:30:00','Salary','Completed',NULL),
(13,'Debit',4200,'2026-05-02 16:45:00','Online purchase','Completed',NULL),
(14,'Withdrawal',7000,'2026-05-08 14:25:00','ATM','Completed',NULL),
(15,'Credit',23000,'2026-05-12 10:35:00','Refund','Completed',NULL),
(15,'Debit',6500,'2026-05-18 18:15:00','Electronics','Completed',NULL),
(16,'Deposit',60000,'2026-05-25 09:50:00','FD deposit','Completed',NULL),
(17,'Debit',9000,'2026-06-01 17:05:00','Rent','Completed',NULL),
(18,'Credit',35000,'2026-06-06 10:20:00','Consulting income','Completed',NULL),
(18,'Withdrawal',15000,'2026-06-12 13:25:00',NULL,'Completed',NULL),
(19,'Deposit',48000,'2026-06-18 11:10:00','Business receipt','Completed',NULL),
(19,'Debit',18000,'2026-06-19 12:20:00','Vendor payment','Completed',NULL),
(20,'Deposit',12500,'2026-06-24 10:30:00','Transfer received','Completed',NULL),
(21,'Credit',70000,'2026-07-01 09:40:00','FD interest','Completed',NULL),
(21,'Debit',25000,'2026-07-04 16:15:00','Investment','Completed',NULL),
(22,'Deposit',6000,'2026-07-08 11:25:00','Cash deposit','Completed',NULL),
(23,'Credit',30000,'2026-07-12 10:05:00','Client payment','Completed',NULL),
(23,'Debit',14000,'2026-07-13 10:30:00','Vendor payment','Completed',NULL),
(24,'Deposit',21000,'2026-07-18 09:15:00','Salary','Completed',NULL),
(24,'Debit',5200,'2026-07-22 19:05:00',NULL,'Completed',NULL),
(25,'Withdrawal',10000,'2026-07-28 13:00:00','ATM','Completed',NULL),
(26,'Deposit',34000,'2026-08-02 10:45:00','Salary','Completed',NULL),
(26,'Debit',8200,'2026-08-03 18:10:00','Shopping','Completed',NULL),
(27,'Credit',80000,'2026-08-07 12:15:00','FD interest','Completed',NULL),
(27,'Debit',22000,'2026-08-10 15:30:00','Investment','Completed',NULL),
(28,'Deposit',19000,'2026-08-16 09:55:00','Salary','Completed',NULL),
(28,'Withdrawal',4500,'2026-08-20 14:20:00',NULL,'Completed',NULL),
(29,'Credit',50000,'2026-08-25 10:10:00','Business receipt','Completed',NULL),
(29,'Debit',16500,'2026-08-26 11:35:00','Supplier payment','Completed',NULL),
(1,'Transfer Out',20000,'2026-09-02 10:00:00','Transfer to savings','Completed','TRF-SEED-001'),
(20,'Transfer In',20000,'2026-09-02 10:00:05','Transfer received','Completed','TRF-SEED-001'),
(5,'Debit',12500,'2026-09-10 18:30:00','Education fee','Completed',NULL),
(19,'Deposit',55000,'2026-09-18 11:50:00','Business settlement','Completed',NULL);

-- Account 30 intentionally has no transactions.

INSERT INTO beneficiaries (customer_id,beneficiary_name,bank_name,account_number,ifsc_code,added_date) VALUES
(1,'Riya Reddy','ABC Bank','500000000001','ABCD0001010','2026-01-15'),
(2,'Sohan Sharma','XYZ Bank','500000000002','XYZB0002020','2026-02-10'),
(3,'Karan Rao','ABC Bank','500000000003','ABCD0003030','2026-03-11'),
(4,'Mohan Nair','National Bank','500000000004','NATB0004040','2026-03-20'),
(5,'Reena Mehta','XYZ Bank','500000000005','XYZB0005050','2026-04-08'),
(6,'Aarav Iyer','ABC Bank','500000000006','ABCD0006060','2026-04-22'),
(7,'Dev Verma','National Bank','500000000007','NATB0007070','2026-05-14'),
(8,'Nina Joshi','XYZ Bank','500000000008','XYZB0008080','2026-06-01'),
(9,'Rakesh Kumar','ABC Bank','500000000009','ABCD0009090','2026-06-17'),
(10,'Tina Singh','National Bank','500000000010','NATB0010101','2026-07-03'),
(11,'Ajay Gupta','XYZ Bank','500000000011','XYZB0011111','2026-07-20'),
(12,'Rupa Reddy','ABC Bank','500000000012','ABCD0012121','2026-08-05');

INSERT INTO loans (customer_id,branch_id,loan_type,principal_amount,interest_rate,start_date,end_date,status) VALUES
(1,1,'Home Loan',2500000,8.50,'2024-01-01','2044-01-01','Active'),
(2,1,'Personal Loan',300000,11.50,'2025-06-01','2030-06-01','Active'),
(3,2,'Vehicle Loan',800000,9.25,'2025-09-15','2032-09-15','Active'),
(4,2,'Education Loan',1200000,8.00,'2024-07-01','2034-07-01','Active'),
(5,3,'Personal Loan',450000,12.00,'2026-01-10','2031-01-10','Active'),
(6,3,'Home Loan',3200000,8.75,'2023-04-01','2043-04-01','Active'),
(7,4,'Vehicle Loan',600000,9.50,'2025-03-12','2030-03-12','Active'),
(8,4,'Business Loan',1500000,10.00,'2024-11-01','2031-11-01','Active'),
(9,5,'Personal Loan',250000,12.50,'2025-12-01','2028-12-01','Closed'),
(10,5,'Education Loan',900000,8.25,'2026-02-01','2036-02-01','Active');

INSERT INTO loan_payments (loan_id,amount,payment_date,payment_method) VALUES
(1,25000,'2026-01-05','Auto Debit'),(1,25000,'2026-02-05','Auto Debit'),
(2,10000,'2026-01-10','Bank Transfer'),(2,10000,'2026-02-10','Bank Transfer'),
(3,15000,'2026-03-15','Auto Debit'),(3,15000,'2026-04-15','Auto Debit'),
(4,18000,'2026-05-01','Bank Transfer'),(5,12000,'2026-05-10','UPI'),
(6,30000,'2026-06-01','Auto Debit'),(6,30000,'2026-07-01','Auto Debit'),
(7,14000,'2026-07-12','Bank Transfer'),(8,22000,'2026-08-01','Auto Debit'),
(9,25000,'2026-08-15','Bank Transfer'),(10,16000,'2026-09-01','Auto Debit'),
(10,16000,'2026-09-15','Auto Debit');

INSERT INTO cards (account_id,card_number,card_type,expiry_date,status,daily_limit) VALUES
(1,'4111111111110001','Debit','2030-12-31','Active',100000),
(2,'4111111111110002','Debit','2030-11-30','Active',75000),
(3,'4111111111110003','Debit','2030-10-31','Active',50000),
(5,'4111111111110005','Debit','2030-09-30','Active',50000),
(6,'4111111111110006','Debit','2030-08-31','Active',75000),
(8,'4111111111110008','Debit','2030-07-31','Active',100000),
(9,'4111111111110009','Debit','2030-06-30','Active',50000),
(11,'4111111111110011','Debit','2030-05-31','Active',60000),
(12,'4111111111110012','Debit','2030-04-30','Active',80000),
(13,'4111111111110013','Debit','2030-03-31','Active',50000),
(15,'4111111111110015','Debit','2030-02-28','Active',75000),
(17,'4111111111110017','Debit','2030-01-31','Active',60000),
(18,'4111111111110018','Debit','2029-12-31','Active',90000),
(19,'5111111111110019','Credit','2030-12-31','Active',150000),
(20,'5111111111110020','Credit','2030-11-30','Active',100000),
(23,'5111111111110023','Credit','2030-10-31','Active',120000),
(24,'4111111111110024','Debit','2030-09-30','Active',50000),
(26,'4111111111110026','Debit','2030-08-31','Active',75000),
(28,'4111111111110028','Debit','2030-07-31','Active',50000),
(29,'5111111111110029','Credit','2030-06-30','Blocked',100000);

-- =================================================================================================================================

-- =====================================================================
-- 3. DDL COMMANDS
-- =====================================================================
ALTER TABLE customers ADD COLUMN temporary_note VARCHAR(100) NULL;
ALTER TABLE customers MODIFY COLUMN temporary_note VARCHAR(150) NULL;
ALTER TABLE customers RENAME COLUMN temporary_note TO alternate_contact;

ALTER TABLE accounts ADD COLUMN temp_remarks VARCHAR(80) NULL;
ALTER TABLE accounts MODIFY COLUMN temp_remarks VARCHAR(120) NULL;
ALTER TABLE accounts RENAME COLUMN temp_remarks TO remarks;

RENAME TABLE audit_logs TO banking_audit_logs_demo;
RENAME TABLE banking_audit_logs_demo TO audit_logs;

ALTER TABLE cards ADD CONSTRAINT chk_demo_card_limit CHECK (daily_limit <= 500000);
ALTER TABLE cards DROP CHECK chk_demo_card_limit;

CREATE TEMPORARY TABLE temp_today_transactions AS
SELECT * FROM transactions WHERE DATE(transaction_date)=CURDATE();
SELECT * FROM temp_today_transactions;
TRUNCATE TABLE temp_today_transactions;
DROP TEMPORARY TABLE temp_today_transactions;

CREATE TABLE transaction_staging (staging_id INT PRIMARY KEY AUTO_INCREMENT, notes VARCHAR(100));
DROP TABLE transaction_staging;

-- DROP DATABASE bank_db; -- only after project completion

-- ==================================================================================================================================

-- =====================================================================
-- 4. INSERT / UPDATE / DELETE
-- =====================================================================
UPDATE customers SET city='Secunderabad' WHERE customer_id=6;
UPDATE employees SET salary=ROUND(salary*1.10,2) WHERE employee_id IN (2,3);
UPDATE accounts SET status='Active' WHERE account_id=7;
DELETE FROM beneficiaries WHERE beneficiary_id=12;

INSERT INTO customers (customer_name,email,phone,city,registered_date,status)
VALUES ('Delete Demo','delete.demo@example.com','9000000099','DeleteDemo',CURDATE(),'Inactive');
DELETE FROM customers WHERE customer_id=21 AND city='DeleteDemo';

-- =================================================================================================================================

-- =====================================================================
-- 5. SELECT & OPERATORS
-- =====================================================================
SELECT * FROM customers;
SELECT customer_name,city FROM customers;
SELECT account_id,account_number,balance FROM accounts WHERE balance>50000;
SELECT transaction_id,account_id,amount FROM transactions WHERE amount BETWEEN 5000 AND 20000;
SELECT * FROM accounts WHERE account_type IN ('Savings','Current');
SELECT * FROM customers WHERE customer_name LIKE 'A%';
SELECT * FROM customers WHERE LOWER(customer_name) LIKE '%a%';
SELECT * FROM customers WHERE city<>'Hyderabad';
SELECT * FROM transactions WHERE amount BETWEEN 1000 AND 10000;
SELECT * FROM transactions WHERE description IS NULL;
SELECT * FROM transactions WHERE description IS NOT NULL;
SELECT transaction_id,amount,ROUND(amount*0.015,2) AS transaction_charge,ROUND(amount*1.015,2) AS amount_with_charge FROM transactions;
SELECT * FROM accounts WHERE balance>50000 AND status='Active';
SELECT * FROM customers WHERE city='Hyderabad' OR city='Secunderabad';
SELECT * FROM accounts WHERE NOT status='Closed';

-- =================================================================================================================================
-- =====================================================================
-- 6. DISTINCT, ORDER BY & LIMIT
-- =====================================================================
SELECT DISTINCT city FROM customers;
SELECT DISTINCT account_type FROM accounts;
SELECT * FROM accounts ORDER BY balance ASC;
SELECT * FROM accounts ORDER BY balance DESC;
SELECT * FROM customers ORDER BY customer_name ASC;
SELECT * FROM accounts ORDER BY balance DESC LIMIT 5;
SELECT * FROM transactions ORDER BY amount ASC LIMIT 3;
SELECT * FROM customers ORDER BY customer_id LIMIT 5 OFFSET 5;

-- =================================================================================================================================
-- =====================================================================
-- 7. AGGREGATE FUNCTIONS
-- =====================================================================
SELECT COUNT(*) AS total_customers FROM customers;
SELECT COUNT(*) AS total_accounts FROM accounts;
SELECT MAX(balance) AS highest_balance,MIN(balance) AS lowest_balance,ROUND(AVG(balance),2) AS average_balance FROM accounts;
SELECT SUM(amount) AS total_transaction_amount FROM transactions;
SELECT ROUND(AVG(amount),2) AS average_transaction_amount FROM transactions;
SELECT MAX(amount) AS highest_transaction_amount,MIN(amount) AS lowest_transaction_amount FROM transactions;
SELECT SUM(principal_amount) AS total_loan_principal FROM loans;
SELECT COUNT(*) AS transaction_count,SUM(amount) AS total_amount,ROUND(AVG(amount),2) AS average_amount,MIN(amount) AS minimum_amount,MAX(amount) AS maximum_amount FROM transactions;

-- =================================================================================================================================
-- =====================================================================
-- 8. GROUP BY & HAVING
-- =====================================================================
SELECT city,COUNT(*) AS customer_count FROM customers GROUP BY city ORDER BY customer_count DESC;
SELECT branch_id,COUNT(*) AS account_count FROM accounts GROUP BY branch_id;
SELECT account_type,ROUND(AVG(balance),2) AS average_balance FROM accounts GROUP BY account_type;
SELECT b.branch_id,b.branch_name,COUNT(t.transaction_id) AS transaction_count,COALESCE(SUM(t.amount),0) AS total_transaction_amount
FROM branches b LEFT JOIN accounts a ON b.branch_id=a.branch_id LEFT JOIN transactions t ON a.account_id=t.account_id
GROUP BY b.branch_id,b.branch_name;
SELECT c.customer_id,c.customer_name,COALESCE(SUM(t.amount),0) AS total_transaction_amount
FROM customers c LEFT JOIN accounts a ON c.customer_id=a.customer_id LEFT JOIN transactions t ON a.account_id=t.account_id
GROUP BY c.customer_id,c.customer_name ORDER BY total_transaction_amount DESC;
SELECT c.customer_id,c.customer_name,COUNT(a.account_id) AS total_accounts
FROM customers c LEFT JOIN accounts a ON c.customer_id=a.customer_id GROUP BY c.customer_id,c.customer_name;
SELECT b.branch_id,b.branch_name,COUNT(a.account_id) AS account_count
FROM branches b JOIN accounts a ON b.branch_id=a.branch_id GROUP BY b.branch_id,b.branch_name HAVING COUNT(a.account_id)>5;
SELECT c.customer_id,c.customer_name,SUM(t.amount) AS total_transaction_amount
FROM customers c JOIN accounts a ON c.customer_id=a.customer_id JOIN transactions t ON a.account_id=t.account_id
GROUP BY c.customer_id,c.customer_name HAVING SUM(t.amount)>50000;
SELECT b.branch_id,b.branch_name,ROUND(AVG(a.balance),2) AS average_balance
FROM branches b JOIN accounts a ON b.branch_id=a.branch_id GROUP BY b.branch_id,b.branch_name HAVING AVG(a.balance)>70000;

-- ================================================================================================================================
-- =====================================================================
-- 9. JOINS
-- =====================================================================
SELECT c.customer_id,c.customer_name,a.account_number,a.account_type,a.balance
FROM customers c INNER JOIN accounts a ON c.customer_id=a.customer_id;

SELECT a.account_number,a.account_type,a.balance,b.branch_name
FROM accounts a INNER JOIN branches b ON a.branch_id=b.branch_id;

SELECT t.transaction_id,a.account_number,t.transaction_type,t.amount,t.transaction_date
FROM transactions t INNER JOIN accounts a ON t.account_id=a.account_id;

SELECT e.employee_name,e.job_title,e.salary,b.branch_name
FROM employees e INNER JOIN branches b ON e.branch_id=b.branch_id;

SELECT c.customer_id,c.customer_name,a.account_number,a.account_type
FROM customers c LEFT JOIN accounts a ON c.customer_id=a.customer_id;

SELECT c.customer_id,c.customer_name
FROM customers c LEFT JOIN accounts a ON c.customer_id=a.customer_id
WHERE a.account_id IS NULL;

SELECT b.branch_id,b.branch_name,e.employee_name
FROM branches b LEFT JOIN employees e ON b.branch_id=e.branch_id ORDER BY b.branch_id;

SELECT c.customer_name,a.account_number,a.balance
FROM customers c RIGHT JOIN accounts a ON c.customer_id=a.customer_id;

-- FULL OUTER JOIN equivalent in MySQL.
SELECT c.customer_id,c.customer_name,a.account_id,a.account_number
FROM customers c LEFT JOIN accounts a ON c.customer_id=a.customer_id
UNION
SELECT c.customer_id,c.customer_name,a.account_id,a.account_number
FROM customers c RIGHT JOIN accounts a ON c.customer_id=a.customer_id;

-- Employee-manager self join.
SELECT e.employee_name AS employee,m.employee_name AS manager
FROM employees e LEFT JOIN employees m ON e.manager_id=m.employee_id;

-- Employees sharing the same manager.
SELECT e1.employee_name AS employee_1,e2.employee_name AS employee_2,m.employee_name AS manager
FROM employees e1
JOIN employees e2 ON e1.manager_id=e2.manager_id AND e1.employee_id<e2.employee_id
JOIN employees m ON e1.manager_id=m.employee_id;

-- CROSS JOIN branches and account types.
SELECT b.branch_name,at.account_type
FROM branches b
CROSS JOIN (
    SELECT 'Savings' AS account_type
    UNION ALL SELECT 'Current'
    UNION ALL SELECT 'Fixed Deposit'
) at;

-- ==================================================================================================================================
-- =====================================================================
-- 10. MULTI-TABLE JOINS
-- =====================================================================
-- customer -> account -> transaction
SELECT c.customer_name,a.account_number,t.transaction_id,t.transaction_type,t.amount,t.transaction_date
FROM customers c JOIN accounts a ON c.customer_id=a.customer_id
JOIN transactions t ON a.account_id=t.account_id
ORDER BY c.customer_id,t.transaction_date;

-- customer -> loan -> loan payment
SELECT c.customer_name,l.loan_id,l.loan_type,l.principal_amount,lp.loan_payment_id,lp.amount AS payment_amount,lp.payment_date
FROM customers c JOIN loans l ON c.customer_id=l.customer_id
LEFT JOIN loan_payments lp ON l.loan_id=lp.loan_id
ORDER BY l.loan_id,lp.payment_date;

-- employee -> branch
SELECT e.employee_id,e.employee_name,e.job_title,b.branch_name,b.city
FROM employees e JOIN branches b ON e.branch_id=b.branch_id;

-- Four-table account report.
SELECT c.customer_name,a.account_number,b.branch_name,t.transaction_type,t.amount,t.transaction_date
FROM customers c
JOIN accounts a ON c.customer_id=a.customer_id
JOIN branches b ON a.branch_id=b.branch_id
LEFT JOIN transactions t ON a.account_id=t.account_id
ORDER BY c.customer_name,t.transaction_date;

-- Five-table banking report.
SELECT c.customer_name,a.account_number,b.branch_name,t.transaction_type,t.amount,cd.card_type,cd.status AS card_status
FROM customers c
JOIN accounts a ON c.customer_id=a.customer_id
JOIN branches b ON a.branch_id=b.branch_id
LEFT JOIN transactions t ON a.account_id=t.account_id
LEFT JOIN cards cd ON a.account_id=cd.account_id
ORDER BY c.customer_name,a.account_number;

-- ===================================================================================================================================
-- =====================================================================
-- 11. SUBQUERIES
-- =====================================================================
SELECT * FROM accounts WHERE balance>(SELECT AVG(balance) FROM accounts);
SELECT * FROM accounts WHERE balance=(SELECT MAX(balance) FROM accounts);
SELECT * FROM accounts
WHERE balance=(SELECT MAX(balance) FROM accounts WHERE balance<(SELECT MAX(balance) FROM accounts));

SELECT * FROM customers
WHERE customer_id IN (
    SELECT DISTINCT a.customer_id FROM accounts a JOIN transactions t ON a.account_id=t.account_id
);

SELECT * FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT a.customer_id FROM accounts a JOIN transactions t ON a.account_id=t.account_id
);

SELECT * FROM accounts
WHERE account_id NOT IN (SELECT DISTINCT account_id FROM transactions);

SELECT customer_id,customer_name,total_amount
FROM (
    SELECT c.customer_id,c.customer_name,COALESCE(SUM(t.amount),0) AS total_amount
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id=a.customer_id
    LEFT JOIN transactions t ON a.account_id=t.account_id
    GROUP BY c.customer_id,c.customer_name
) customer_totals
WHERE total_amount>(
    SELECT AVG(x.total_amount)
    FROM (
        SELECT c2.customer_id,COALESCE(SUM(t2.amount),0) AS total_amount
        FROM customers c2
        LEFT JOIN accounts a2 ON c2.customer_id=a2.customer_id
        LEFT JOIN transactions t2 ON a2.account_id=t2.account_id
        GROUP BY c2.customer_id
    ) x
);

SELECT * FROM employees WHERE salary>(SELECT AVG(salary) FROM employees);

-- ==================================================================================================================================
-- =====================================================================
-- 12. ANY, ALL & EXISTS
-- =====================================================================
SELECT * FROM accounts
WHERE balance>ALL (SELECT balance FROM accounts WHERE branch_id=2);

SELECT * FROM accounts
WHERE balance>ANY (SELECT balance FROM accounts WHERE branch_id=2);

SELECT c.* FROM customers c
WHERE EXISTS (SELECT 1 FROM accounts a WHERE a.customer_id=c.customer_id);

SELECT c.* FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM accounts a WHERE a.customer_id=c.customer_id);

SELECT * FROM customers WHERE customer_id IN (SELECT customer_id FROM accounts);
SELECT c.* FROM customers c WHERE EXISTS (SELECT 1 FROM accounts a WHERE a.customer_id=c.customer_id);

-- =====================================================================================================================================
-- =====================================================================
-- 13. CORRELATED SUBQUERIES
-- =====================================================================
SELECT a.account_id,a.account_number,a.branch_id,a.balance
FROM accounts a
WHERE a.balance>(SELECT AVG(a2.balance) FROM accounts a2 WHERE a2.branch_id=a.branch_id);

SELECT e.employee_id,e.employee_name,e.branch_id,e.salary
FROM employees e
WHERE e.salary>(SELECT AVG(e2.salary) FROM employees e2 WHERE e2.branch_id=e.branch_id);

-- Customers above their city average outbound spending.
SELECT c.customer_id,c.customer_name,c.city,
       (SELECT COALESCE(SUM(t.amount),0)
        FROM accounts a JOIN transactions t ON a.account_id=t.account_id
        WHERE a.customer_id=c.customer_id
          AND t.transaction_type IN ('Withdrawal','Debit','Transfer Out')) AS customer_spending
FROM customers c
WHERE (SELECT COALESCE(SUM(t.amount),0)
       FROM accounts a JOIN transactions t ON a.account_id=t.account_id
       WHERE a.customer_id=c.customer_id
         AND t.transaction_type IN ('Withdrawal','Debit','Transfer Out'))
      >
      (SELECT COALESCE(SUM(CASE WHEN t2.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t2.amount ELSE 0 END),0)
              / NULLIF(COUNT(DISTINCT c2.customer_id),0)
       FROM customers c2
       LEFT JOIN accounts a2 ON c2.customer_id=a2.customer_id
       LEFT JOIN transactions t2 ON a2.account_id=t2.account_id
       WHERE c2.city=c.city);

SELECT a.account_id,a.account_number,a.branch_id,a.balance
FROM accounts a
WHERE a.balance=(SELECT MAX(a2.balance) FROM accounts a2 WHERE a2.branch_id=a.branch_id);

-- ====================================================================================================================================
-- =====================================================================
-- 14. CASE EXPRESSIONS
-- =====================================================================
SELECT account_number,balance,
       CASE WHEN balance<50000 THEN 'Low' WHEN balance<150000 THEN 'Medium' ELSE 'High' END AS balance_category
FROM accounts;

SELECT c.customer_id,c.customer_name,
       COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0) AS spending,
       CASE
         WHEN COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0)<10000 THEN 'Low Spender'
         WHEN COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0)<30000 THEN 'Medium Spender'
         ELSE 'High Spender'
       END AS spending_category
FROM customers c
LEFT JOIN accounts a ON c.customer_id=a.customer_id
LEFT JOIN transactions t ON a.account_id=t.account_id
GROUP BY c.customer_id,c.customer_name;

SELECT employee_name,salary,
       CASE WHEN salary<60000 THEN 'Junior Salary Band' WHEN salary<90000 THEN 'Mid Salary Band' ELSE 'Senior Salary Band' END AS salary_category
FROM employees;

SELECT loan_id,principal_amount,
       CASE WHEN principal_amount<500000 THEN 'Small Loan' WHEN principal_amount<1500000 THEN 'Medium Loan' ELSE 'Large Loan' END AS loan_category
FROM loans;

SELECT transaction_id,status,
       CASE status WHEN 'Completed' THEN 'Transaction completed successfully'
                   WHEN 'Pending' THEN 'Transaction is awaiting completion'
                   WHEN 'Failed' THEN 'Transaction failed'
                   ELSE 'Unknown status' END AS status_message
FROM transactions;

-- ======================================================================================================================================
-- =====================================================================
-- 15. MYSQL FUNCTIONS
-- =====================================================================
SELECT customer_name,
       UPPER(customer_name) AS upper_name,
       LOWER(customer_name) AS lower_name,
       CONCAT(customer_name,' - ',city) AS customer_location,
       SUBSTRING(customer_name,1,5) AS first_five_chars,
       LENGTH(customer_name) AS name_length,
       REPLACE(customer_name,'a','@') AS replaced_name,
       TRIM(CONCAT('   ',customer_name,'   ')) AS trimmed_name
FROM customers LIMIT 10;

SELECT amount,ROUND(amount/3,2) AS rounded_value,CEIL(amount/3) AS ceiling_value,
       FLOOR(amount/3) AS floor_value,ABS(amount-10000) AS absolute_difference
FROM transactions LIMIT 10;

SELECT CURDATE() AS current_date_value,NOW() AS current_datetime_value,
       YEAR(CURDATE()) AS current_year,MONTH(CURDATE()) AS current_month,DAY(CURDATE()) AS current_day,
       DATEDIFF(CURDATE(),'2026-01-01') AS days_since_year_start,
       DATE_ADD(CURDATE(),INTERVAL 30 DAY) AS date_after_30_days,
       DATE_SUB(CURDATE(),INTERVAL 30 DAY) AS date_before_30_days;

SELECT transaction_id,
       IFNULL(description,'No description') AS description_ifnull,
       COALESCE(description,transfer_reference,'No details') AS transaction_details,
       NULLIF(status,'Completed') AS null_if_completed
FROM transactions LIMIT 10;

SELECT * FROM transactions WHERE YEAR(transaction_date)=YEAR(CURDATE());
SELECT * FROM customers WHERE registered_date>=DATE_SUB(CURDATE(),INTERVAL 30 DAY);

SELECT loan_id,loan_type,start_date,end_date,
       DATEDIFF(end_date,start_date) AS loan_duration_days,
       TIMESTAMPDIFF(YEAR,start_date,end_date) AS loan_duration_years
FROM loans;

-- =================================================================================================================================

-- =====================================================================
-- 16. UNION & SET OPERATIONS
-- =====================================================================
SELECT city FROM customers
UNION
SELECT city FROM branches;

SELECT city FROM customers
UNION ALL
SELECT city FROM branches;

SELECT 'UNION distinct rows' AS comparison,COUNT(*) AS row_count
FROM (SELECT city FROM customers UNION SELECT city FROM branches) u
UNION ALL
SELECT 'UNION ALL rows',COUNT(*)
FROM (SELECT city FROM customers UNION ALL SELECT city FROM branches) ua;

SELECT customer_name AS person_name,email,'Customer' AS person_type FROM customers
UNION ALL
SELECT employee_name,email,'Employee' FROM employees;

-- ==================================================================================================================================
-- =====================================================================
-- 17. COMMON TABLE EXPRESSIONS (CTE)
-- =====================================================================
WITH high_balance_accounts AS (
    SELECT * FROM accounts WHERE balance>100000
)
SELECT * FROM high_balance_accounts;

WITH customer_spending AS (
    SELECT c.customer_id,c.customer_name,
           COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0) AS spending
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id=a.customer_id
    LEFT JOIN transactions t ON a.account_id=t.account_id
    GROUP BY c.customer_id,c.customer_name
)
SELECT * FROM customer_spending ORDER BY spending DESC;

WITH customer_spending AS (
    SELECT c.customer_id,c.customer_name,
           COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0) AS spending
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id=a.customer_id
    LEFT JOIN transactions t ON a.account_id=t.account_id
    GROUP BY c.customer_id,c.customer_name
)
SELECT * FROM customer_spending
WHERE spending>(SELECT AVG(spending) FROM customer_spending);

WITH branch_totals AS (
    SELECT branch_id,SUM(balance) AS total_balance FROM accounts GROUP BY branch_id
), overall_average AS (
    SELECT AVG(total_balance) AS avg_branch_total FROM branch_totals
)
SELECT bt.branch_id,bt.total_balance,oa.avg_branch_total
FROM branch_totals bt CROSS JOIN overall_average oa;

WITH account_details AS (
    SELECT a.account_id,a.account_number,a.balance,c.customer_name,b.branch_name
    FROM accounts a
    JOIN customers c ON a.customer_id=c.customer_id
    JOIN branches b ON a.branch_id=b.branch_id
)
SELECT * FROM account_details WHERE balance>50000;

WITH monthly_totals AS (
    SELECT DATE_FORMAT(transaction_date,'%Y-%m') AS transaction_month,SUM(amount) AS total_amount
    FROM transactions GROUP BY DATE_FORMAT(transaction_date,'%Y-%m')
)
SELECT * FROM monthly_totals ORDER BY transaction_month;

-- Recursive CTE also demonstrates employee hierarchy.
WITH RECURSIVE employee_hierarchy AS (
    SELECT employee_id,employee_name,manager_id,1 AS hierarchy_level
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id,e.employee_name,e.manager_id,eh.hierarchy_level+1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id=eh.employee_id
)
SELECT * FROM employee_hierarchy ORDER BY hierarchy_level,employee_id;

-- =================================================================================================================================

-- =====================================================================
-- 18. WINDOW FUNCTIONS
-- =====================================================================
SELECT transaction_id,account_id,transaction_date,amount,
       ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY transaction_date,transaction_id) AS transaction_number
FROM transactions;

SELECT account_id,account_number,branch_id,balance,
       RANK() OVER (PARTITION BY branch_id ORDER BY balance DESC) AS balance_rank
FROM accounts;

SELECT account_id,account_number,branch_id,balance,
       DENSE_RANK() OVER (PARTITION BY branch_id ORDER BY balance DESC) AS dense_balance_rank
FROM accounts;

WITH ranked_accounts AS (
    SELECT a.*,ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY balance DESC) AS rn
    FROM accounts a
)
SELECT * FROM ranked_accounts WHERE rn<=3 ORDER BY branch_id,rn;

SELECT transaction_id,account_id,transaction_date,amount,
       SUM(amount) OVER (PARTITION BY account_id ORDER BY transaction_date,transaction_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_transaction_total
FROM transactions;

SELECT account_id,branch_id,balance,
       ROUND(AVG(balance) OVER (PARTITION BY branch_id),2) AS branch_average_balance
FROM accounts;

SELECT transaction_id,account_id,transaction_date,amount,
       LAG(amount) OVER (PARTITION BY account_id ORDER BY transaction_date,transaction_id) AS previous_transaction_amount
FROM transactions;

SELECT transaction_id,account_id,transaction_date,amount,
       LEAD(amount) OVER (PARTITION BY account_id ORDER BY transaction_date,transaction_id) AS next_transaction_amount
FROM transactions;

WITH employee_rank AS (
    SELECT e.*,ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY salary DESC) AS rn FROM employees e
)
SELECT * FROM employee_rank WHERE rn=1;

WITH customer_spending AS (
    SELECT c.customer_id,c.customer_name,
           COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0) AS spending
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id=a.customer_id
    LEFT JOIN transactions t ON a.account_id=t.account_id
    GROUP BY c.customer_id,c.customer_name
)
SELECT customer_id,customer_name,spending,NTILE(4) OVER (ORDER BY spending DESC) AS spending_quartile
FROM customer_spending;

-- ==================================================================================================================================

-- =====================================================================
-- 19. VIEWS
-- =====================================================================
DROP VIEW IF EXISTS customer_account_view;
CREATE VIEW customer_account_view AS
SELECT c.customer_id,c.customer_name,c.city,
       a.account_id,a.account_number,a.account_type,a.balance,a.status AS account_status
FROM customers c LEFT JOIN accounts a ON c.customer_id=a.customer_id;

DROP VIEW IF EXISTS account_transaction_view;
CREATE VIEW account_transaction_view AS
SELECT a.account_id,a.account_number,
       t.transaction_id,t.transaction_type,t.amount,t.transaction_date,t.status AS transaction_status
FROM accounts a LEFT JOIN transactions t ON a.account_id=t.account_id;

DROP VIEW IF EXISTS loan_payment_view;
CREATE VIEW loan_payment_view AS
SELECT l.loan_id,l.loan_type,l.principal_amount,l.status AS loan_status,
       lp.loan_payment_id,lp.amount AS payment_amount,lp.payment_date
FROM loans l LEFT JOIN loan_payments lp ON l.loan_id=lp.loan_id;

DROP VIEW IF EXISTS employee_branch_view;
CREATE VIEW employee_branch_view AS
SELECT e.employee_id,e.employee_name,e.job_title,e.salary,
       b.branch_id,b.branch_name,b.city AS branch_city
FROM employees e JOIN branches b ON e.branch_id=b.branch_id;

SELECT * FROM customer_account_view;
SELECT * FROM account_transaction_view;
SELECT * FROM loan_payment_view;
SELECT * FROM employee_branch_view;

ALTER VIEW customer_account_view AS
SELECT c.customer_id,c.customer_name,c.email,c.city,
       a.account_id,a.account_number,a.account_type,a.balance,a.status AS account_status,
       b.branch_name
FROM customers c
LEFT JOIN accounts a ON c.customer_id=a.customer_id
LEFT JOIN branches b ON a.branch_id=b.branch_id;

DROP VIEW IF EXISTS demo_active_accounts_view;
CREATE VIEW demo_active_accounts_view AS
SELECT * FROM accounts WHERE status='Active';
DROP VIEW demo_active_accounts_view;

-- =================================================================================================================================

-- =====================================================================
-- 20. STORED PROCEDURES
-- =====================================================================
DROP PROCEDURE IF EXISTS get_all_customers;
DROP PROCEDURE IF EXISTS get_customer_accounts;
DROP PROCEDURE IF EXISTS get_branch_accounts;
DROP PROCEDURE IF EXISTS get_accounts_by_type;
DROP PROCEDURE IF EXISTS get_customer_count;
DROP PROCEDURE IF EXISTS apply_balance_growth;
DROP PROCEDURE IF EXISTS classify_account_balance;
DROP PROCEDURE IF EXISTS account_loop_demo;
DROP PROCEDURE IF EXISTS get_account_summary;

DELIMITER $$

CREATE PROCEDURE get_all_customers()
BEGIN
    SELECT * FROM customers ORDER BY customer_id;
END$$

CREATE PROCEDURE get_customer_accounts(IN p_customer_id INT)
BEGIN
    SELECT account_id,account_number,account_type,balance,status
    FROM accounts WHERE customer_id=p_customer_id ORDER BY account_id;
END$$

CREATE PROCEDURE get_branch_accounts(IN p_branch_id INT)
BEGIN
    SELECT account_id,account_number,account_type,balance,status
    FROM accounts WHERE branch_id=p_branch_id ORDER BY balance DESC;
END$$

CREATE PROCEDURE get_accounts_by_type(IN p_account_type VARCHAR(30))
BEGIN
    SELECT * FROM accounts WHERE account_type=p_account_type;
END$$

CREATE PROCEDURE get_customer_count(OUT p_customer_count INT)
BEGIN
    SELECT COUNT(*) INTO p_customer_count FROM customers;
END$$

CREATE PROCEDURE apply_balance_growth(INOUT p_balance DECIMAL(14,2),IN p_percent DECIMAL(5,2))
BEGIN
    SET p_balance=p_balance+(p_balance*p_percent/100);
END$$

CREATE PROCEDURE classify_account_balance(IN p_account_id INT)
BEGIN
    DECLARE v_balance DECIMAL(14,2);
    SELECT balance INTO v_balance FROM accounts WHERE account_id=p_account_id;
    IF v_balance<50000 THEN
        SELECT 'Low Balance' AS balance_classification;
    ELSEIF v_balance<150000 THEN
        SELECT 'Medium Balance' AS balance_classification;
    ELSE
        SELECT 'High Balance' AS balance_classification;
    END IF;
END$$

CREATE PROCEDURE account_loop_demo(IN p_limit INT)
BEGIN
    DECLARE v_counter INT DEFAULT 1;
    DECLARE v_result TEXT DEFAULT '';
    WHILE v_counter<=p_limit DO
        SET v_result=CONCAT(v_result,IF(v_result='','',', '),'Account-',v_counter);
        SET v_counter=v_counter+1;
    END WHILE;
    SELECT v_result AS loop_output;
END$$

CREATE PROCEDURE get_account_summary(IN p_account_id INT)
BEGIN
    SELECT a.account_id,a.account_number,c.customer_name,b.branch_name,
           a.account_type,a.balance,a.status,
           COUNT(t.transaction_id) AS transaction_count,
           COALESCE(SUM(t.amount),0) AS total_transaction_amount
    FROM accounts a
    JOIN customers c ON a.customer_id=c.customer_id
    JOIN branches b ON a.branch_id=b.branch_id
    LEFT JOIN transactions t ON a.account_id=t.account_id
    WHERE a.account_id=p_account_id
    GROUP BY a.account_id,a.account_number,c.customer_name,b.branch_name,a.account_type,a.balance,a.status;
END$$

DELIMITER ;

CALL get_all_customers();
CALL get_customer_accounts(1);
CALL get_branch_accounts(1);
CALL get_accounts_by_type('Savings');
SET @customer_count=0;
CALL get_customer_count(@customer_count);
SELECT @customer_count AS customer_count_from_out_parameter;
SET @projected_balance=10000.00;
CALL apply_balance_growth(@projected_balance,5.00);
SELECT @projected_balance AS balance_after_inout_procedure;
CALL classify_account_balance(1);
CALL account_loop_demo(5);
CALL get_account_summary(1);

-- ================================================================================================================================

-- =====================================================================
-- 21. USER-DEFINED FUNCTIONS
-- =====================================================================
-- Note: On servers with binary logging, creating stored functions may require
-- suitable privileges or log_bin_trust_function_creators=1.

DROP FUNCTION IF EXISTS calculate_interest;
DROP FUNCTION IF EXISTS transaction_charge;
DROP FUNCTION IF EXISTS loan_final_amount;
DROP FUNCTION IF EXISTS customer_classification;

DELIMITER $$

CREATE FUNCTION calculate_interest(p_principal DECIMAL(14,2),p_rate DECIMAL(5,2),p_years DECIMAL(6,2))
RETURNS DECIMAL(14,2)
DETERMINISTIC
BEGIN
    RETURN ROUND((p_principal*p_rate*p_years)/100,2);
END$$

CREATE FUNCTION transaction_charge(p_amount DECIMAL(14,2))
RETURNS DECIMAL(14,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(p_amount*0.005,2);
END$$

CREATE FUNCTION loan_final_amount(p_principal DECIMAL(14,2),p_rate DECIMAL(5,2),p_years DECIMAL(6,2))
RETURNS DECIMAL(14,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(p_principal+((p_principal*p_rate*p_years)/100),2);
END$$

CREATE FUNCTION customer_classification(p_customer_id INT)
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
    DECLARE v_spending DECIMAL(14,2) DEFAULT 0;
    SELECT COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0)
    INTO v_spending
    FROM accounts a
    LEFT JOIN transactions t ON a.account_id=t.account_id
    WHERE a.customer_id=p_customer_id;

    IF v_spending<10000 THEN
        RETURN 'Low Spender';
    ELSEIF v_spending<30000 THEN
        RETURN 'Medium Spender';
    ELSE
        RETURN 'High Spender';
    END IF;
END$$

DELIMITER ;

SELECT loan_id,principal_amount,interest_rate,
       calculate_interest(principal_amount,interest_rate,1) AS one_year_interest,
       loan_final_amount(principal_amount,interest_rate,1) AS one_year_final_amount
FROM loans;

SELECT transaction_id,amount,transaction_charge(amount) AS calculated_charge
FROM transactions LIMIT 10;

SELECT customer_id,customer_name,customer_classification(customer_id) AS customer_classification
FROM customers;

-- ==================================================================================================================================

-- =====================================================================
-- 22. TRIGGERS
-- =====================================================================
DROP TRIGGER IF EXISTS trg_before_transaction_insert;
DROP TRIGGER IF EXISTS trg_after_transaction_insert;
DROP TRIGGER IF EXISTS trg_after_account_update;
DROP TRIGGER IF EXISTS trg_demo_card_insert;

DELIMITER $$

CREATE TRIGGER trg_before_transaction_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.amount<=0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT='Transaction amount must be greater than zero';
    END IF;
END$$

CREATE TRIGGER trg_after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name,action_type,record_id,old_value,new_value)
    VALUES ('transactions','INSERT',NEW.transaction_id,NULL,
            CONCAT('account_id=',NEW.account_id,', type=',NEW.transaction_type,', amount=',NEW.amount,', status=',NEW.status));
END$$

CREATE TRIGGER trg_after_account_update
AFTER UPDATE ON accounts
FOR EACH ROW
BEGIN
    IF OLD.balance<>NEW.balance OR OLD.status<>NEW.status THEN
        INSERT INTO audit_logs (table_name,action_type,record_id,old_value,new_value)
        VALUES ('accounts','UPDATE',NEW.account_id,
                CONCAT('balance=',OLD.balance,', status=',OLD.status),
                CONCAT('balance=',NEW.balance,', status=',NEW.status));
    END IF;
END$$

CREATE TRIGGER trg_demo_card_insert
AFTER INSERT ON cards
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name,action_type,record_id,old_value,new_value)
    VALUES ('cards','INSERT-DEMO',NEW.card_id,NULL,NEW.card_number);
END$$

DELIMITER ;

SHOW TRIGGERS FROM bank_db;
SHOW CREATE TRIGGER trg_before_transaction_insert;
SHOW CREATE TRIGGER trg_after_transaction_insert;
SHOW CREATE TRIGGER trg_after_account_update;
DROP TRIGGER trg_demo_card_insert;

-- Invalid trigger test: intentionally commented because it must raise an error.
-- INSERT INTO transactions (account_id,transaction_type,amount,description)
-- VALUES (1,'Debit',-100,'This should be rejected');

-- ===============================================================================================================================

-- =====================================================================
-- 23. TRANSACTIONS / TCL
-- =====================================================================
-- Complete fund transfer: account 1 -> account 2.
START TRANSACTION;
UPDATE accounts
SET balance=balance-5000,last_activity_date=CURDATE()
WHERE account_id=1 AND balance>=5000;
UPDATE accounts
SET balance=balance+5000,last_activity_date=CURDATE()
WHERE account_id=2;
INSERT INTO transactions (account_id,transaction_type,amount,transaction_date,description,status,transfer_reference) VALUES
(1,'Transfer Out',5000,NOW(),'Fund transfer to account 2','Completed','TRF-DEMO-001'),
(2,'Transfer In',5000,NOW(),'Fund transfer from account 1','Completed','TRF-DEMO-001');
INSERT INTO audit_logs (table_name,action_type,record_id,old_value,new_value)
VALUES ('fund_transfer','COMMIT-DEMO',1,'source_account=1','destination_account=2, amount=5000');
COMMIT;

-- Rollback demo.
START TRANSACTION;
UPDATE accounts SET balance=balance+9999 WHERE account_id=3;
ROLLBACK;

-- SAVEPOINT demo.
START TRANSACTION;
UPDATE accounts SET balance=balance+1000 WHERE account_id=4;
SAVEPOINT after_account_4;
UPDATE accounts SET balance=balance+2000 WHERE account_id=5;
ROLLBACK TO SAVEPOINT after_account_4;
COMMIT;

-- Second complete transfer with savepoint.
START TRANSACTION;
UPDATE accounts SET balance=balance-2500 WHERE account_id=3 AND balance>=2500;
SAVEPOINT source_debited;
UPDATE accounts SET balance=balance+2500 WHERE account_id=4;
INSERT INTO transactions (account_id,transaction_type,amount,transaction_date,description,status,transfer_reference) VALUES
(3,'Transfer Out',2500,NOW(),'Transfer to account 4','Completed','TRF-DEMO-002'),
(4,'Transfer In',2500,NOW(),'Transfer from account 3','Completed','TRF-DEMO-002');
COMMIT;

SELECT account_id,account_number,balance FROM accounts WHERE account_id IN (1,2,3,4,5);
SELECT * FROM transactions WHERE transfer_reference IN ('TRF-DEMO-001','TRF-DEMO-002');

-- =================================================================================================================================

-- =====================================================================
-- 24. INDEXES
-- =====================================================================
-- UNIQUE constraints already index email and account_number; these lookup
-- indexes include those requested columns without being exact duplicates.
CREATE INDEX idx_customer_email_lookup ON customers(email,status);
CREATE INDEX idx_account_number_lookup ON accounts(account_number,status);
CREATE INDEX idx_transaction_date ON transactions(transaction_date);
CREATE INDEX idx_account_branch_type_balance ON accounts(branch_id,account_type,balance);
SHOW INDEX FROM customers;
SHOW INDEX FROM accounts;
SHOW INDEX FROM transactions;
CREATE INDEX idx_beneficiary_bank_name ON beneficiaries(bank_name);
SHOW INDEX FROM beneficiaries;
DROP INDEX idx_beneficiary_bank_name ON beneficiaries;

-- ==============================================================================================================================

-- =====================================================================
-- 25. NORMALIZATION
-- =====================================================================
DROP TABLE IF EXISTS banking_denormalized;
CREATE TABLE banking_denormalized (
    denorm_id INT PRIMARY KEY AUTO_INCREMENT,
    CustomerName VARCHAR(100),
    Phone VARCHAR(20),
    BranchName VARCHAR(100),
    Account1 VARCHAR(20),
    Account2 VARCHAR(20),
    Transaction1 DECIMAL(14,2),
    Transaction2 DECIMAL(14,2),
    Loan DECIMAL(14,2),
    ManagerName VARCHAR(100)
);

INSERT INTO banking_denormalized
(CustomerName,Phone,BranchName,Account1,Account2,Transaction1,Transaction2,Loan,ManagerName)
VALUES ('Arjun Reddy','9000000001','Jubilee Hills Branch','100000000001','100000000019',25000,6000,2500000,'Anita Rao');

-- Repeating groups: Account1/Account2 and Transaction1/Transaction2.
-- 1NF: make values atomic and keep one account/transaction combination per row.
DROP TABLE IF EXISTS banking_1nf;
CREATE TABLE banking_1nf (
    row_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    branch_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(20) NOT NULL,
    transaction_amount DECIMAL(14,2) NULL,
    loan_amount DECIMAL(14,2) NULL,
    manager_name VARCHAR(100) NULL
);

INSERT INTO banking_1nf (customer_name,phone,branch_name,account_number,transaction_amount,loan_amount,manager_name) VALUES
('Arjun Reddy','9000000001','Jubilee Hills Branch','100000000001',25000,2500000,'Anita Rao'),
('Arjun Reddy','9000000001','Gachibowli Branch','100000000019',6000,2500000,'Arvind Menon');

-- 2NF: separate customer, account and transaction facts.
DROP TABLE IF EXISTS norm2_transactions;
DROP TABLE IF EXISTS norm2_accounts;
DROP TABLE IF EXISTS norm2_customers;
CREATE TABLE norm2_customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE
);
CREATE TABLE norm2_accounts (
    account_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    account_number VARCHAR(20) NOT NULL UNIQUE,
    branch_name VARCHAR(100) NOT NULL,
    CONSTRAINT fk_norm2_account_customer FOREIGN KEY (customer_id) REFERENCES norm2_customers(customer_id)
);
CREATE TABLE norm2_transactions (
    transaction_id INT PRIMARY KEY,
    account_id INT NOT NULL,
    amount DECIMAL(14,2) NOT NULL,
    CONSTRAINT fk_norm2_transaction_account FOREIGN KEY (account_id) REFERENCES norm2_accounts(account_id)
);
INSERT INTO norm2_customers VALUES (1,'Arjun Reddy','9000000001');
INSERT INTO norm2_accounts VALUES
(1,1,'100000000001','Jubilee Hills Branch'),
(19,1,'100000000019','Gachibowli Branch');
INSERT INTO norm2_transactions VALUES (1,1,25000),(2,19,6000);

-- 3NF: remove transitive branch dependency into its own entity.
DROP TABLE IF EXISTS norm3_accounts;
DROP TABLE IF EXISTS norm3_branches;
CREATE TABLE norm3_branches (
    branch_id INT PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL UNIQUE
);
CREATE TABLE norm3_accounts (
    account_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    account_number VARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT fk_norm3_account_customer FOREIGN KEY (customer_id) REFERENCES norm2_customers(customer_id),
    CONSTRAINT fk_norm3_account_branch FOREIGN KEY (branch_id) REFERENCES norm3_branches(branch_id)
);
INSERT INTO norm3_branches VALUES (1,'Jubilee Hills Branch'),(4,'Gachibowli Branch');
INSERT INTO norm3_accounts VALUES (1,1,1,'100000000001'),(19,1,4,'100000000019');

-- Candidate keys examples:
-- customers: customer_id, email, phone
-- branches: branch_id, branch_name, ifsc_code
-- accounts: account_id, account_number
-- cards: card_id, card_number
-- Primary keys: all *_id primary identifiers above.
-- Foreign keys: employee->branch/manager, account->customer/branch,
-- transaction->account, beneficiary->customer, loan->customer/branch,
-- loan_payment->loan, card->account.
-- BCNF: every determinant should be a candidate key.
-- 4NF: independent multivalued facts should be separated into their own tables.
-- 5NF: independent join dependencies should be decomposed and reconstructed by joins.

-- ==================================================================================================================================

-- =====================================================================
-- 26. DCL
-- =====================================================================
-- Requires administrator/root privileges; run separately if needed.
-- CREATE USER IF NOT EXISTS 'bank_reporting'@'localhost' IDENTIFIED BY 'BankReport@123';
-- GRANT SELECT ON bank_db.* TO 'bank_reporting'@'localhost';
-- GRANT INSERT, UPDATE ON bank_db.transactions TO 'bank_reporting'@'localhost';
-- SHOW GRANTS FOR 'bank_reporting'@'localhost';
-- REVOKE INSERT ON bank_db.transactions FROM 'bank_reporting'@'localhost';

-- ===============================================================================================================================

-- =====================================================================
-- 27. FINAL SQL CHALLENGE
-- =====================================================================

-- 27.1 Second-highest balance without LIMIT.
SELECT MAX(balance) AS second_highest_balance
FROM accounts
WHERE balance<(SELECT MAX(balance) FROM accounts);

-- 27.2 Third-highest balance.
SELECT MAX(balance) AS third_highest_balance
FROM accounts
WHERE balance<(
    SELECT MAX(balance)
    FROM accounts
    WHERE balance<(SELECT MAX(balance) FROM accounts)
);

-- 27.3 Highest-balance account per branch.
WITH ranked_accounts AS (
    SELECT a.*,RANK() OVER (PARTITION BY branch_id ORDER BY balance DESC) AS rnk
    FROM accounts a
)
SELECT * FROM ranked_accounts WHERE rnk=1;

-- 27.4 Second-highest-paid employee per branch.
WITH ranked_employees AS (
    SELECT e.*,DENSE_RANK() OVER (PARTITION BY branch_id ORDER BY salary DESC) AS salary_rank
    FROM employees e
)
SELECT * FROM ranked_employees WHERE salary_rank=2;

-- 27.5 Customers without accounts.
SELECT c.customer_id,c.customer_name
FROM customers c LEFT JOIN accounts a ON c.customer_id=a.customer_id
WHERE a.account_id IS NULL;

-- 27.6 Inactive accounts.
SELECT * FROM accounts WHERE status IN ('Inactive','Frozen','Closed');

-- 27.7 Highest-spending customer.
WITH customer_spending AS (
    SELECT c.customer_id,c.customer_name,
           COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0) AS spending
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id=a.customer_id
    LEFT JOIN transactions t ON a.account_id=t.account_id
    GROUP BY c.customer_id,c.customer_name
)
SELECT * FROM customer_spending
WHERE spending=(SELECT MAX(spending) FROM customer_spending);

-- 27.8 Top 3 customers per city.
WITH customer_spending AS (
    SELECT c.customer_id,c.customer_name,c.city,
           COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0) AS spending
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id=a.customer_id
    LEFT JOIN transactions t ON a.account_id=t.account_id
    GROUP BY c.customer_id,c.customer_name,c.city
), ranked_customers AS (
    SELECT cs.*,ROW_NUMBER() OVER (PARTITION BY city ORDER BY spending DESC,customer_id) AS rn
    FROM customer_spending cs
)
SELECT * FROM ranked_customers WHERE rn<=3 ORDER BY city,rn;

-- 27.9 Top account per branch.
WITH ranked_accounts AS (
    SELECT a.*,ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY balance DESC) AS rn
    FROM accounts a
)
SELECT * FROM ranked_accounts WHERE rn=1;

-- 27.10 Branches whose average balance exceeds overall average.
SELECT b.branch_id,b.branch_name,AVG(a.balance) AS branch_average_balance
FROM branches b JOIN accounts a ON b.branch_id=a.branch_id
GROUP BY b.branch_id,b.branch_name
HAVING AVG(a.balance)>(SELECT AVG(balance) FROM accounts);

-- 27.11 Employees above branch average salary.
SELECT e.employee_id,e.employee_name,e.branch_id,e.salary
FROM employees e
WHERE e.salary>(SELECT AVG(e2.salary) FROM employees e2 WHERE e2.branch_id=e.branch_id);

-- 27.12 Consecutive transactions by account.
WITH ordered_transactions AS (
    SELECT t.*,
           LAG(transaction_date) OVER (PARTITION BY account_id ORDER BY transaction_date,transaction_id) AS previous_transaction_date
    FROM transactions t
)
SELECT transaction_id,account_id,previous_transaction_date,transaction_date,
       TIMESTAMPDIFF(DAY,previous_transaction_date,transaction_date) AS days_between
FROM ordered_transactions
WHERE previous_transaction_date IS NOT NULL
  AND TIMESTAMPDIFF(DAY,previous_transaction_date,transaction_date)<=1;

-- 27.13 First and latest transaction per customer.
WITH customer_transactions AS (
    SELECT c.customer_id,c.customer_name,t.transaction_id,t.transaction_date,t.amount,
           ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY t.transaction_date,t.transaction_id) AS first_rn,
           ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY t.transaction_date DESC,t.transaction_id DESC) AS latest_rn
    FROM customers c
    JOIN accounts a ON c.customer_id=a.customer_id
    JOIN transactions t ON a.account_id=t.account_id
)
SELECT * FROM customer_transactions
WHERE first_rn=1 OR latest_rn=1
ORDER BY customer_id,transaction_date;

-- 27.14 Monthly transaction totals.
SELECT DATE_FORMAT(transaction_date,'%Y-%m') AS transaction_month,
       COUNT(*) AS transaction_count,
       SUM(amount) AS total_transaction_amount
FROM transactions
GROUP BY DATE_FORMAT(transaction_date,'%Y-%m')
ORDER BY transaction_month;

-- 27.15 Month with highest transaction volume.
WITH monthly_volume AS (
    SELECT DATE_FORMAT(transaction_date,'%Y-%m') AS transaction_month,
           COUNT(*) AS transaction_count,
           SUM(amount) AS total_amount
    FROM transactions
    GROUP BY DATE_FORMAT(transaction_date,'%Y-%m')
)
SELECT * FROM monthly_volume
WHERE transaction_count=(SELECT MAX(transaction_count) FROM monthly_volume);

-- 27.16 Running transaction total.
SELECT transaction_id,transaction_date,amount,
       SUM(amount) OVER (ORDER BY transaction_date,transaction_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM transactions;

-- 27.17 Customers whose spending increased month-over-month.
WITH monthly_customer_spending AS (
    SELECT c.customer_id,c.customer_name,DATE_FORMAT(t.transaction_date,'%Y-%m') AS spend_month,
           SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END) AS monthly_spending
    FROM customers c
    JOIN accounts a ON c.customer_id=a.customer_id
    JOIN transactions t ON a.account_id=t.account_id
    GROUP BY c.customer_id,c.customer_name,DATE_FORMAT(t.transaction_date,'%Y-%m')
), spending_with_previous AS (
    SELECT mcs.*,
           LAG(monthly_spending) OVER (PARTITION BY customer_id ORDER BY spend_month) AS previous_month_spending
    FROM monthly_customer_spending mcs
)
SELECT * FROM spending_with_previous
WHERE previous_month_spending IS NOT NULL
  AND monthly_spending>previous_month_spending;

-- 27.18 Find duplicate customer records.
-- Create one controlled duplicate. Email/phone stay unique; duplicate identity
-- for this demo is customer_name + city.
INSERT INTO customers (customer_name,email,phone,city,registered_date,status)
SELECT customer_name,'arjun.duplicate@example.com','9000000098',city,CURDATE(),status
FROM customers WHERE customer_id=1;

SELECT customer_name,city,COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_name,city
HAVING COUNT(*)>1;

-- 27.19 Remove duplicates while retaining one.
CREATE TEMPORARY TABLE duplicate_customer_ids AS
SELECT customer_id
FROM (
    SELECT customer_id,
           ROW_NUMBER() OVER (PARTITION BY customer_name,city ORDER BY customer_id) AS rn
    FROM customers
) ranked_duplicates
WHERE rn>1;

DELETE c
FROM customers c
JOIN duplicate_customer_ids d ON c.customer_id=d.customer_id;

DROP TEMPORARY TABLE duplicate_customer_ids;

SELECT customer_name,city,COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_name,city
HAVING COUNT(*)>1;

-- 27.20 Employees earning more than managers.
SELECT e.employee_id,e.employee_name,e.salary AS employee_salary,
       m.employee_name AS manager_name,m.salary AS manager_salary
FROM employees e
JOIN employees m ON e.manager_id=m.employee_id
WHERE e.salary>m.salary;

-- 27.21 Managers with more than 3 employees.
SELECT m.employee_id AS manager_id,m.employee_name AS manager_name,
       COUNT(e.employee_id) AS employee_count
FROM employees m
JOIN employees e ON e.manager_id=m.employee_id
GROUP BY m.employee_id,m.employee_name
HAVING COUNT(e.employee_id)>3;

-- 27.22 Complete banking dashboard query.
SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM branches) AS total_branches,
    (SELECT COUNT(*) FROM employees) AS total_employees,
    (SELECT COUNT(*) FROM accounts) AS total_accounts,
    (SELECT COUNT(*) FROM accounts WHERE status='Active') AS active_accounts,
    (SELECT COUNT(*) FROM accounts WHERE status<>'Active') AS non_active_accounts,
    (SELECT ROUND(SUM(balance),2) FROM accounts) AS total_account_balance,
    (SELECT COUNT(*) FROM transactions) AS total_transactions,
    (SELECT ROUND(SUM(amount),2) FROM transactions) AS total_transaction_amount,
    (SELECT COUNT(*) FROM loans WHERE status='Active') AS active_loans,
    (SELECT ROUND(SUM(principal_amount),2) FROM loans) AS total_loan_principal,
    (SELECT COUNT(*) FROM cards WHERE status='Active') AS active_cards;

-- ===============================================================================================================================

-- =====================================================================
-- 28. FINAL PROJECT REPORTS
-- =====================================================================

-- 28.1 Customer Report.
SELECT c.customer_id,c.customer_name,c.email,c.phone,c.city,c.registered_date,c.status,
       COUNT(DISTINCT a.account_id) AS account_count,
       COALESCE(SUM(a.balance),0) AS total_balance
FROM customers c
LEFT JOIN accounts a ON c.customer_id=a.customer_id
GROUP BY c.customer_id,c.customer_name,c.email,c.phone,c.city,c.registered_date,c.status
ORDER BY c.customer_id;

-- 28.2 Branch Report.
WITH branch_accounts AS (
    SELECT branch_id,COUNT(*) AS total_accounts,SUM(balance) AS total_account_balance
    FROM accounts GROUP BY branch_id
), branch_employees AS (
    SELECT branch_id,COUNT(*) AS total_employees
    FROM employees GROUP BY branch_id
)
SELECT b.branch_id,b.branch_name,b.city,
       COALESCE(ba.total_accounts,0) AS total_accounts,
       COALESCE(be.total_employees,0) AS total_employees,
       COALESCE(ba.total_account_balance,0) AS total_account_balance
FROM branches b
LEFT JOIN branch_accounts ba ON b.branch_id=ba.branch_id
LEFT JOIN branch_employees be ON b.branch_id=be.branch_id
ORDER BY b.branch_id;

-- 28.3 Employee Report.
SELECT e.employee_id,e.employee_name,e.job_title,e.salary,b.branch_name,
       m.employee_name AS manager_name
FROM employees e
JOIN branches b ON e.branch_id=b.branch_id
LEFT JOIN employees m ON e.manager_id=m.employee_id
ORDER BY b.branch_name,e.salary DESC;

-- 28.4 Account Report.
SELECT a.account_id,a.account_number,c.customer_name,b.branch_name,
       a.account_type,a.balance,a.status,a.opened_date,a.last_activity_date
FROM accounts a
JOIN customers c ON a.customer_id=c.customer_id
JOIN branches b ON a.branch_id=b.branch_id
ORDER BY a.account_id;

-- 28.5 Transaction Report.
SELECT t.transaction_id,c.customer_name,a.account_number,b.branch_name,
       t.transaction_type,t.amount,t.transaction_date,t.status,t.description
FROM transactions t
JOIN accounts a ON t.account_id=a.account_id
JOIN customers c ON a.customer_id=c.customer_id
JOIN branches b ON a.branch_id=b.branch_id
ORDER BY t.transaction_date,t.transaction_id;

-- 28.6 Loan Report.
SELECT l.loan_id,c.customer_name,b.branch_name,l.loan_type,l.principal_amount,
       l.interest_rate,l.start_date,l.end_date,l.status
FROM loans l
JOIN customers c ON l.customer_id=c.customer_id
JOIN branches b ON l.branch_id=b.branch_id
ORDER BY l.loan_id;

-- 28.7 Loan Payment Report.
SELECT lp.loan_payment_id,l.loan_id,c.customer_name,l.loan_type,
       lp.amount AS payment_amount,lp.payment_date,lp.payment_method
FROM loan_payments lp
JOIN loans l ON lp.loan_id=l.loan_id
JOIN customers c ON l.customer_id=c.customer_id
ORDER BY lp.payment_date;

-- 28.8 Card Report.
SELECT cd.card_id,cd.card_number,cd.card_type,cd.expiry_date,cd.status,cd.daily_limit,
       a.account_number,c.customer_name
FROM cards cd
JOIN accounts a ON cd.account_id=a.account_id
JOIN customers c ON a.customer_id=c.customer_id
ORDER BY cd.card_id;

-- 28.9 Customer Spending Report.
SELECT c.customer_id,c.customer_name,
       COALESCE(SUM(CASE WHEN t.transaction_type IN ('Withdrawal','Debit','Transfer Out') THEN t.amount ELSE 0 END),0) AS total_spending
FROM customers c
LEFT JOIN accounts a ON c.customer_id=a.customer_id
LEFT JOIN transactions t ON a.account_id=t.account_id
GROUP BY c.customer_id,c.customer_name
ORDER BY total_spending DESC;

-- 28.10 Branch Balance Report.
SELECT b.branch_id,b.branch_name,COUNT(a.account_id) AS account_count,
       COALESCE(SUM(a.balance),0) AS total_balance,
       ROUND(COALESCE(AVG(a.balance),0),2) AS average_balance
FROM branches b
LEFT JOIN accounts a ON b.branch_id=a.branch_id
GROUP BY b.branch_id,b.branch_name
ORDER BY total_balance DESC;

-- 28.11 Monthly Transaction Report.
SELECT DATE_FORMAT(transaction_date,'%Y-%m') AS transaction_month,
       COUNT(*) AS transaction_count,
       SUM(amount) AS total_transaction_amount,
       ROUND(AVG(amount),2) AS average_transaction_amount
FROM transactions
GROUP BY DATE_FORMAT(transaction_date,'%Y-%m')
ORDER BY transaction_month;

-- 28.12 Top 10 Customers.
WITH customer_value AS (
    SELECT c.customer_id,c.customer_name,COALESCE(SUM(a.balance),0) AS total_balance
    FROM customers c LEFT JOIN accounts a ON c.customer_id=a.customer_id
    GROUP BY c.customer_id,c.customer_name
)
SELECT * FROM customer_value ORDER BY total_balance DESC LIMIT 10;

-- 28.13 Top 10 Accounts.
SELECT a.account_id,a.account_number,c.customer_name,b.branch_name,a.balance
FROM accounts a
JOIN customers c ON a.customer_id=c.customer_id
JOIN branches b ON a.branch_id=b.branch_id
ORDER BY a.balance DESC LIMIT 10;

-- 28.14 Employee-Manager Report.
SELECT e.employee_id,e.employee_name,e.job_title,e.salary,
       m.employee_name AS manager_name,b.branch_name
FROM employees e
LEFT JOIN employees m ON e.manager_id=m.employee_id
JOIN branches b ON e.branch_id=b.branch_id
ORDER BY b.branch_name,manager_name,e.employee_name;

-- 28.15 Inactive Accounts Report.
SELECT a.account_id,a.account_number,c.customer_name,a.status,a.balance,a.last_activity_date
FROM accounts a
JOIN customers c ON a.customer_id=c.customer_id
WHERE a.status<>'Active'
ORDER BY a.account_id;

-- 28.16 Customers Without Accounts Report.
SELECT c.customer_id,c.customer_name,c.city
FROM customers c
LEFT JOIN accounts a ON c.customer_id=a.customer_id
WHERE a.account_id IS NULL;

-- 28.17 Highest-Balance Account Per Branch Report.
WITH branch_account_rank AS (
    SELECT a.*,ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY balance DESC) AS rn
    FROM accounts a
)
SELECT bar.branch_id,b.branch_name,bar.account_id,bar.account_number,bar.balance
FROM branch_account_rank bar
JOIN branches b ON bar.branch_id=b.branch_id
WHERE bar.rn=1
ORDER BY bar.branch_id;

-- 28.18 Customer Ranking Report.
WITH customer_balance AS (
    SELECT c.customer_id,c.customer_name,COALESCE(SUM(a.balance),0) AS total_balance
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id=a.customer_id
    GROUP BY c.customer_id,c.customer_name
)
SELECT customer_id,customer_name,total_balance,
       RANK() OVER (ORDER BY total_balance DESC) AS customer_rank
FROM customer_balance;

-- 28.19 Monthly Running Transaction Report.
WITH monthly_transactions AS (
    SELECT DATE_FORMAT(transaction_date,'%Y-%m') AS transaction_month,
           SUM(amount) AS monthly_total
    FROM transactions
    GROUP BY DATE_FORMAT(transaction_date,'%Y-%m')
)
SELECT transaction_month,monthly_total,
       SUM(monthly_total) OVER (ORDER BY transaction_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_transaction_total
FROM monthly_transactions
ORDER BY transaction_month;

-- =================================================================================================================================

-- =====================================================================
-- 29. FINAL VERIFICATION
-- =====================================================================
SELECT 'customers' AS table_name,COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'branches',COUNT(*) FROM branches
UNION ALL SELECT 'employees',COUNT(*) FROM employees
UNION ALL SELECT 'accounts',COUNT(*) FROM accounts
UNION ALL SELECT 'transactions',COUNT(*) FROM transactions
UNION ALL SELECT 'beneficiaries',COUNT(*) FROM beneficiaries
UNION ALL SELECT 'loans',COUNT(*) FROM loans
UNION ALL SELECT 'loan_payments',COUNT(*) FROM loan_payments
UNION ALL SELECT 'cards',COUNT(*) FROM cards
UNION ALL SELECT 'audit_logs',COUNT(*) FROM audit_logs;


-- OPTIONAL CLEANUP ONLY AFTER PROJECT COMPLETION:
-- DROP DATABASE bank_db;

-- =====================================================================
-- END OF BANKING MANAGEMENT SYSTEM SQL PROJECT
-- =====================================================================





