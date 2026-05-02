-- References --:
-- https://skyvia.com/blog/how-to-import-csv-file-into-mysql/#:~:text=While%20still%20in%20the%20MySQL,directly%20into%20the%20MySQL%20prompt.
-- https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html
-- https://www.w3schools.com/sql/sql_ref_join.asp
-- https://www.w3schools.com/sql/sql_case.asp


-- SQL Assessment
-- This script contains all tasks completed in sequence.

-- Task 1: Table Design
-- Create tables for company and individual employee data.
CREATE DATABASE company_employee_data;
USE company_employee_data;

CREATE TABLE company_data(
	Install INT NOT NULL PRIMARY KEY,
    XHR_Sector_Grouped INT,
    emp_band INT,
    Turnover_3_Bands INT 
);

-- Install is used as the link between both tables.
CREATE TABLE individual_data(
	ParticipantRecordId INT NOT NULL PRIMARY KEY,
    Install INT NOT NULL,
    Jobtitle VARCHAR(100),
    Level INT,
    Global_function_group_2020 INT,
    Basic_Salary DECIMAL(10,2) NOT NULL,
    Bonus DECIMAL(10,2),
    Basic_plus_Bonus_plus_Allowances_2020 DECIMAL(10,2),
    Region INT,
    
    FOREIGN KEY (Install)
		REFERENCES company_data(Install)
);

-- Task 2: Data Loading
-- Loading the CSV data into the tables without changing the original files.
SELECT COUNT(*) 
FROM individual_data i
LEFT JOIN company_data c ON i.Install = c.Install
WHERE c.Install IS NULL;

SELECT COUNT(*) FROM individual_data;
SELECT COUNT(*) FROM company_data; 

-- Check row counts after loading. 
SELECT COUNT(*) FROM company_data;
SELECT COUNT(*) FROM individual_data;

-- Check foreign key violations (should be 0). 
SELECT COUNT(*) 
FROM individual_data i
LEFT JOIN company_data c ON i.Install = c.Install
WHERE c.Install IS NULL;

-- Preview the first 10 rows from the individual employee dataset.
SELECT * FROM individual_data LIMIT 10;
-- Preview the first 10 rows from the company dataset.
SELECT * FROM company_data LIMIT 10;

-- Task 3: CTE with Derived Fields
-- Joined companies and employees data and create calculated.
WITH joined_tables AS (
	SELECT 
		c.Install,
        c.XHR_Sector_Grouped,
        c.emp_band,
        c.Turnover_3_Bands,
        i.ParticipantRecordID,
        i.JobTitle,
        i.Level,
        i.Global_function_group_2020,
        i.Basic_Salary,
        i.Bonus,
        i.Basic_plus_Bonus_plus_Allowances_2020,
        i.Region,
        
-- Calculate salary plus bonus.
        (i.Basic_Salary + i.Bonus) AS sum_basic_bonus,

-- Check whether calculated values match the provided total compensation field.
        CASE 
			WHEN (i.Basic_Salary + i.Bonus) = i.Basic_plus_Bonus_plus_Allowances_2020
            THEN TRUE
            ELSE FALSE
		END AS is_sum_match_Basic_plus_Allowances_2020
        
FROM company_data c
JOIN individual_data i ON c.Install = i.Install
)

-- Task 4: Dataset Overview.
-- Summary stats for employees and companies. 
SELECT 
    COUNT(ParticipantRecordID) AS total_number_of_employees,
    COUNT(DISTINCT Install) AS total_number_of_companies,
    SUM(CASE
        WHEN JobTitle IS NULL OR JobTitle = '' THEN 1
        ELSE 0
    END) AS employees_with_missing_jobtitle,
    AVG(Basic_Salary) AS average_basic_salary,
    COUNT(Bonus) AS employees_with_known_bonus
FROM joined_tables;

-- Task 5: Regional Analysis
-- Analysed employee and salary info by region.
WITH joined_tables AS (
	SELECT 
		c.Install,
        c.XHR_Sector_Grouped,
        c.emp_band,
        c.Turnover_3_Bands,
        i.ParticipantRecordID,
        i.JobTitle,
        i.Level,
        i.Global_function_group_2020,
        i.Basic_Salary,
        i.Bonus,
        i.Basic_plus_Bonus_plus_Allowances_2020,
        i.Region,
        -- Calculated salary + bonus.
        (i.Basic_Salary + i.Bonus) AS sum_basic_bonus,
        
-- Checked whether calculated values matched the provided total compensation field.
        CASE 
			WHEN (i.Basic_Salary + i.Bonus) = i.Basic_plus_Bonus_plus_Allowances_2020
            THEN TRUE
            ELSE FALSE
		END AS is_sum_match_Basic_plus_Allowances_2020
        
FROM company_data c
JOIN individual_data i ON c.Install = i.Install
)

SELECT
	Region,
    -- Employee count per region.
    COUNT(*) AS employee_count,
    -- Average salary per region.
    AVG(Basic_Salary) AS average_basic_salary,
    -- Avg bonus per region.
    AVG(Bonus) AS average_bonus,
    -- Total salary payroll per region. 
    SUM(Basic_Salary) AS total_payroll,
    -- Count employees where bonus is missing. 
    SUM(CASE 
        WHEN Bonus IS NULL THEN 1 
        ELSE 0 
    END)
    AS missing_bonus_count
    
FROM joined_tables
GROUP BY Region;

-- Task 6: Sector and Turnover Analysis.
-- Analysed employee counts and avg compensation by sector and turnover band.
WITH joined_tables AS (
	SELECT 
		c.Install,
        c.XHR_Sector_Grouped,
        c.emp_band,
        c.Turnover_3_Bands,
        i.ParticipantRecordID,
        i.JobTitle,
        i.Level,
        i.Global_function_group_2020,
        i.Basic_Salary,
        i.Bonus,
        i.Basic_plus_Bonus_plus_Allowances_2020,
        i.Region,

        (i.Basic_Salary + i.Bonus) AS sum_basic_bonus,
	
        CASE 
			WHEN (i.Basic_Salary + i.Bonus) = i.Basic_plus_Bonus_plus_Allowances_2020
            THEN TRUE
            ELSE FALSE
		END AS is_sum_match_Basic_plus_Allowances_2020
        
FROM company_data c
JOIN individual_data i ON c.Install = i.Install
)
SELECT
	XHR_Sector_Grouped,
    Turnover_3_Bands,
    -- Numbers of employees in each group.
    COUNT(*) AS employee_count,
    -- Avg total comopensation.
    AVG(Basic_plus_Bonus_plus_Allowances_2020)
    AS average_total_compensation
    
FROM joined_tables

GROUP BY 
	XHR_Sector_grouped,
    Turnover_3_Bands
-- Only include groups with more than 20 employees.
HAVING COUNT(*) > 20;

-- Task 7: Salary Banding.
-- Grouped employees into salary bands based on Basic_salary. 
WITH joined_tables AS (
	SELECT 
		c.Install,
        c.XHR_Sector_Grouped,
        c.emp_band,
        c.Turnover_3_Bands,
        i.ParticipantRecordID,
        i.JobTitle,
        i.Level,
        i.Global_function_group_2020,
        i.Basic_Salary,
        i.Bonus,
        i.Basic_plus_Bonus_plus_Allowances_2020,
        i.Region,
        
        (i.Basic_Salary + i.Bonus) AS sum_basic_bonus,
        
        CASE 
			WHEN (i.Basic_Salary + i.Bonus) = i.Basic_plus_Bonus_plus_Allowances_2020
            THEN TRUE
            ELSE FALSE
		END AS is_sum_match_Basic_plus_Allowances_2020
        
FROM company_data c
JOIN individual_data i ON c.Install = i.Install
)
SELECT 
-- logical thresholds were chosen (low, med, high groups).
	CASE
		WHEN Basic_Salary < 70000 THEN 'Low'
        WHEN Basic_Salary BETWEEN 70000 AND 109999 THEN 'Medium'
        WHEN Basic_Salary >= 110000 THEN 'High'
        END AS Salary_Band,
        
        COUNT(*) AS employee_count 

FROM joined_tables 
GROUP BY Salary_Band
ORDER BY MIN(Basic_Salary);

-- Task 8: Ranking within Levels.
-- Ranked employees by salary within each level.
WITH joined_tables AS (
	SELECT 
		c.Install,
        c.XHR_Sector_Grouped,
        c.emp_band,
        c.Turnover_3_Bands,
        i.ParticipantRecordID,
        i.JobTitle,
        i.Level,
        i.Global_function_group_2020,
        i.Basic_Salary,
        i.Bonus,
        i.Basic_plus_Bonus_plus_Allowances_2020,
        i.Region,
        
        (i.Basic_Salary + i.Bonus) AS sum_basic_bonus,
        
        CASE 
			WHEN (i.Basic_Salary + i.Bonus) = i.Basic_plus_Bonus_plus_Allowances_2020
            THEN TRUE
            ELSE FALSE
		END AS is_sum_match_Basic_plus_Allowances_2020
        
FROM company_data c
JOIN individual_data i ON c.Install = i.Install
),

top_salaries AS(

SELECT
	*,
    -- Return the top 3 highest salaries per level. 
    RANK() OVER(
		PARTITION BY Level
        ORDER BY Basic_Salary DESC
	) AS salary_rank 
    
FROM joined_tables 
)

SELECT * 
FROM top_salaries
WHERE salary_rank <= 3;

-- Task 9: Business rule transformation.
-- Combined Inner London and Outer London into Greater London.
WITH joined_tables AS (
	SELECT 
		c.Install,
        c.XHR_Sector_Grouped,
        c.emp_band,
        c.Turnover_3_Bands,
        i.ParticipantRecordID,
        i.JobTitle,
        i.Level,
        i.Global_function_group_2020,
        i.Basic_Salary,
        i.Bonus,
        i.Basic_plus_Bonus_plus_Allowances_2020,
        i.Region,
        
        (i.Basic_Salary + i.Bonus) AS sum_basic_bonus,
        
        CASE 
			WHEN (i.Basic_Salary + i.Bonus) = i.Basic_plus_Bonus_plus_Allowances_2020
            THEN TRUE
            ELSE FALSE
		END AS is_sum_match_Basic_plus_Allowances_2020
        
FROM company_data c
JOIN individual_data i ON c.Install = i.Install
)

SELECT
	*,
    -- Apply updated region grouping without changing original table data. 
    CASE
    
		WHEN Region IN (1,2) THEN 'Greater London'
        WHEN Region = 3 THEN 'South East'
        WHEN Region = 4 THEN 'South West'
        WHEN Region = 5 THEN 'East Anglia'
        WHEN Region = 6 THEN 'East Midlands'
        WHEN Region = 7 THEN 'West Midlands'
        WHEN Region = 8 THEN 'North West'
        WHEN Region = 9 THEN 'North & North East'
        WHEN Region = 10 THEN 'Scotland'
        WHEN Region = 11 THEN 'Northern Ireland'
        WHEN Region = 12 THEN 'WALES'
        WHEN Region = 15 THEN 'MOBILE'
        ELSE 'Unkown'
END AS updates_region
    
FROM joined_tables;