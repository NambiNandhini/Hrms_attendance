-- HRMS Attendance Management - complete database + demo data
CREATE DATABASE IF NOT EXISTS hrms_attendance CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hrms_attendance;
SET FOREIGN_KEY_CHECKS=0;
CREATE TABLE IF NOT EXISTS shifts (
 id VARCHAR(10) PRIMARY KEY,
 name VARCHAR(100) NOT NULL,
 type VARCHAR(20) NOT NULL,
 start_time TIME NOT NULL,
 end_time TIME NOT NULL,
 grace_minutes INT NOT NULL DEFAULT 0,
 half_day_threshold_minutes INT NOT NULL DEFAULT 240,
 overnight_shift TINYINT(1) NOT NULL DEFAULT 0,
 working_hours DECIMAL(4,1) NOT NULL DEFAULT 8
);
CREATE TABLE IF NOT EXISTS employees (
 id VARCHAR(20) PRIMARY KEY, emp_code VARCHAR(30) UNIQUE NOT NULL, name VARCHAR(120) NOT NULL, department VARCHAR(50) NOT NULL, designation VARCHAR(120) NOT NULL,
 shift_id VARCHAR(10) NOT NULL, join_date DATE NOT NULL, active TINYINT(1) NOT NULL DEFAULT 1, week_off_days VARCHAR(30) NOT NULL DEFAULT '0',
 FOREIGN KEY (shift_id) REFERENCES shifts(id)
);
CREATE TABLE IF NOT EXISTS users (
 id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(80) UNIQUE NOT NULL, password_hash VARCHAR(255) NOT NULL,
 role ENUM('admin','employee') NOT NULL, emp_id VARCHAR(20) NULL, active TINYINT(1) NOT NULL DEFAULT 1,
 FOREIGN KEY (emp_id) REFERENCES employees(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS leave_types (
 code VARCHAR(10) PRIMARY KEY, name VARCHAR(100) NOT NULL, priority_no INT NOT NULL, annual_days DECIMAL(5,1) NOT NULL DEFAULT 0,
 active TINYINT(1) NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS punch_records (
 id VARCHAR(20) PRIMARY KEY, emp_id VARCHAR(20) NOT NULL, punch_date DATE NOT NULL, punch_time TIME NOT NULL, punch_type ENUM('IN','OUT') NOT NULL,
 source ENUM('BIOMETRIC','MANUAL') NOT NULL, remarks VARCHAR(255) NULL, FOREIGN KEY(emp_id) REFERENCES employees(id), INDEX(punch_date), INDEX(emp_id)
);
CREATE TABLE IF NOT EXISTS attendance_records (
 id VARCHAR(20) PRIMARY KEY, emp_id VARCHAR(20) NOT NULL, attendance_date DATE NOT NULL, status VARCHAR(10) NOT NULL, punch_in TIME NULL, punch_out TIME NULL,
 working_minutes INT NOT NULL DEFAULT 0, late_minutes INT NOT NULL DEFAULT 0, early_out_minutes INT NOT NULL DEFAULT 0, overtime_minutes INT NOT NULL DEFAULT 0,
 is_manually_edited TINYINT(1) NOT NULL DEFAULT 0, edited_by VARCHAR(120) NULL, edit_remarks VARCHAR(500) NULL,
 approval_status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING', FOREIGN KEY(emp_id) REFERENCES employees(id), INDEX(attendance_date), UNIQUE KEY employee_attendance_day (emp_id, attendance_date)
);
CREATE TABLE IF NOT EXISTS leave_balances (
 emp_id VARCHAR(20) PRIMARY KEY, year_no INT NOT NULL, month_no INT NOT NULL, el DECIMAL(5,1) NOT NULL, fl DECIMAL(5,1) NOT NULL, cpl DECIMAL(5,1) NOT NULL, cl DECIMAL(5,1) NOT NULL, cl_carried_forward DECIMAL(5,1) NOT NULL, INDEX leave_balance_period (year_no, month_no)
);
CREATE TABLE IF NOT EXISTS leave_applications (
 id VARCHAR(20) PRIMARY KEY, emp_id VARCHAR(20) NOT NULL, leave_type VARCHAR(10) NOT NULL, from_date DATE NOT NULL, to_date DATE NOT NULL, days DECIMAL(5,1) NOT NULL,
 reason VARCHAR(255) NOT NULL, status ENUM('PENDING','APPROVED','REJECTED','CANCELLED') NOT NULL, applied_on DATE NOT NULL, approved_by VARCHAR(120) NULL, approved_on DATE NULL, remarks VARCHAR(500) NULL,
 FOREIGN KEY(emp_id) REFERENCES employees(id)
);
CREATE TABLE IF NOT EXISTS leave_transactions (
 id VARCHAR(20) PRIMARY KEY, emp_id VARCHAR(20) NOT NULL, leave_type VARCHAR(10) NOT NULL, transaction_date DATE NOT NULL, days DECIMAL(5,1) NOT NULL, balance DECIMAL(5,1) NOT NULL,
 txn_type ENUM('CREDIT','DEBIT','CARRYFORWARD') NOT NULL, reference_id VARCHAR(20) NULL, remarks VARCHAR(255) NOT NULL, FOREIGN KEY(emp_id) REFERENCES employees(id)
);
CREATE TABLE IF NOT EXISTS monthly_processing (
 id VARCHAR(20) PRIMARY KEY, emp_id VARCHAR(20) NOT NULL, year_no INT NOT NULL, month_no INT NOT NULL, total_days INT NOT NULL, working_days INT NOT NULL, present_days INT NOT NULL,
 absent_days INT NOT NULL, half_days INT NOT NULL, late_days INT NOT NULL, early_out_days INT NOT NULL, week_off_days INT NOT NULL, holidays INT NOT NULL, el DECIMAL(5,1) NOT NULL,
 fl DECIMAL(5,1) NOT NULL, cpl DECIMAL(5,1) NOT NULL, cl DECIMAL(5,1) NOT NULL, lop DECIMAL(5,1) NOT NULL, overtime_hours DECIMAL(6,2) NOT NULL,
 processed_on DATE NULL, processed_by VARCHAR(120) NULL, approval_status VARCHAR(20) NOT NULL, FOREIGN KEY(emp_id) REFERENCES employees(id), UNIQUE KEY employee_processing_month (emp_id, year_no, month_no), INDEX processing_period (year_no, month_no)
);
CREATE TABLE IF NOT EXISTS holidays (id VARCHAR(20) PRIMARY KEY, holiday_date DATE NOT NULL, name VARCHAR(150) NOT NULL, type VARCHAR(20) NOT NULL);

-- DATA: shifts
DELETE FROM `shifts`;
INSERT INTO `shifts` (`id`,`name`,`type`,`start_time`,`end_time`,`grace_minutes`,`half_day_threshold_minutes`,`overnight_shift`,`working_hours`) VALUES ('S1','Shift A (Morning)','A','06:00','14:00',10,240,0,8);
INSERT INTO `shifts` (`id`,`name`,`type`,`start_time`,`end_time`,`grace_minutes`,`half_day_threshold_minutes`,`overnight_shift`,`working_hours`) VALUES ('S2','Shift B (Afternoon)','B','14:00','22:00',10,240,0,8);
INSERT INTO `shifts` (`id`,`name`,`type`,`start_time`,`end_time`,`grace_minutes`,`half_day_threshold_minutes`,`overnight_shift`,`working_hours`) VALUES ('S3','Shift C (Night)','C','22:00','06:00',10,240,1,8);
INSERT INTO `shifts` (`id`,`name`,`type`,`start_time`,`end_time`,`grace_minutes`,`half_day_threshold_minutes`,`overnight_shift`,`working_hours`) VALUES ('S4','General Shift','General','08:30','17:30',15,270,0,9);

-- DATA: employees
DELETE FROM `employees`;
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E001','MFG-001','Rajesh Kumar','Production','Operator','S1','2021-03-15',1,'0');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E002','MFG-002','Priya Sharma','Quality','QC Inspector','S4','2020-07-01',1,'0');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E003','MFG-003','Arjun Singh','Production','Line Supervisor','S2','2019-11-10',1,'0');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E004','MFG-004','Deepa Nair','Maintenance','Technician','S3','2022-01-20',1,'0');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E005','MFG-005','Vikram Patel','Production','Operator','S1','2023-04-05',1,'0');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E006','MFG-006','Sneha Reddy','HR','HR Executive','S4','2021-08-12',1,'0,6');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E007','MFG-007','Mohammed Farhan','Stores','Store Keeper','S4','2020-03-22',1,'0');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E008','MFG-008','Kavitha Iyer','Quality','QA Engineer','S4','2019-06-15',1,'0,6');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E009','MFG-009','Suresh Babu','Production','Machine Operator','S2','2022-09-01',1,'0');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E010','MFG-010','Anita Desai','Admin','Admin Officer','S4','2020-12-10',1,'0,6');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E011','MFG-011','Ravi Chandran','Production','Senior Operator','S1','2018-05-20',1,'0');
INSERT INTO `employees` (`id`,`emp_code`,`name`,`department`,`designation`,`shift_id`,`join_date`,`active`,`week_off_days`) VALUES ('E012','MFG-012','Pooja Mehta','Safety','Safety Officer','S4','2021-02-14',1,'0,6');

-- DATA: punch_records
DELETE FROM `punch_records`;
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P001','E001','2026-09-01','06:08:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P002','E001','2026-09-01','14:05:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P003','E001','2026-09-02','06:22:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P004','E001','2026-09-02','14:02:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P005','E001','2026-09-03','06:05:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P006','E001','2026-09-03','13:45:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P007','E001','2026-09-04','06:15:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P008','E001','2026-09-05','06:03:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P009','E001','2026-09-05','14:08:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P010','E002','2026-09-01','08:35:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P011','E002','2026-09-01','17:32:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P012','E002','2026-09-02','08:48:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P013','E002','2026-09-02','17:30:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P014','E002','2026-09-03','08:30:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P015','E002','2026-09-03','17:35:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P016','E002','2026-09-04','08:55:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P017','E002','2026-09-04','17:28:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P018','E002','2026-09-05','08:30:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P019','E002','2026-09-05','14:00:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P020','E003','2026-09-01','14:12:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P021','E003','2026-09-01','22:05:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P022','E003','2026-09-02','14:05:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P023','E003','2026-09-02','22:02:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P024','E004','2026-09-01','22:05:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P025','E004','2026-09-02','06:08:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P026','E004','2026-09-02','22:00:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P027','E004','2026-09-03','06:10:00','OUT','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P028','E001','2026-09-04','14:00:00','OUT','MANUAL','Manual entry - biometric not working');
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P029','E001','2026-09-17','06:07:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P030','E002','2026-09-17','08:32:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P031','E003','2026-09-17','14:03:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P032','E005','2026-09-17','06:28:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P033','E006','2026-09-17','08:45:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P034','E007','2026-09-17','08:31:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P035','E009','2026-09-17','14:09:00','IN','BIOMETRIC',NULL);
INSERT INTO `punch_records` (`id`,`emp_id`,`punch_date`,`punch_time`,`punch_type`,`source`,`remarks`) VALUES ('P036','E011','2026-09-17','06:02:00','IN','BIOMETRIC',NULL);

-- DATA: attendance_records
DELETE FROM `attendance_records`;
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A001','E001','2026-09-01','P','06:08','14:05',477,0,0,17,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A002','E001','2026-09-02','L','06:22','14:02',460,12,0,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A003','E001','2026-09-03','EO','06:05','13:45',460,0,15,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A004','E001','2026-09-04','MP','06:15',NULL,0,0,0,0,0,NULL,NULL,'PENDING');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A005','E001','2026-09-05','P','06:03','14:08',485,0,0,25,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A006','E001','2026-09-07','WO',NULL,NULL,0,0,0,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A007','E001','2026-09-08','P','06:04','14:10',486,0,0,26,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A008','E001','2026-09-09','A',NULL,NULL,0,0,0,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A009','E001','2026-09-10','CL',NULL,NULL,0,0,0,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A010','E002','2026-09-01','P','08:35','17:32',537,0,0,27,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A011','E002','2026-09-02','L','08:48','17:30',522,3,0,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A012','E002','2026-09-03','P','08:30','17:35',545,0,0,35,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A013','E002','2026-09-04','L','08:55','17:28',513,10,2,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A014','E002','2026-09-05','HD','08:30','14:00',330,0,210,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A015','E002','2026-09-07','WO',NULL,NULL,0,0,0,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A016','E003','2026-09-01','L','14:12','22:05',473,2,0,0,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A017','E003','2026-09-02','P','14:05','22:02',477,0,0,17,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A018','E004','2026-09-01','P','22:05','06:08',483,0,0,23,0,NULL,NULL,'APPROVED');
INSERT INTO `attendance_records` (`id`,`emp_id`,`attendance_date`,`status`,`punch_in`,`punch_out`,`working_minutes`,`late_minutes`,`early_out_minutes`,`overtime_minutes`,`is_manually_edited`,`edited_by`,`edit_remarks`,`approval_status`) VALUES ('A019','E004','2026-09-02','P','22:00','06:10',490,0,0,30,0,NULL,NULL,'APPROVED');

-- DATA: leave_balances
DELETE FROM `leave_balances`;
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E001',2026,9,12.5,3,2,1.5,1);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E002',2026,9,18,4,0,3,2);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E003',2026,9,8,2,4,0.5,0);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E004',2026,9,15,3,1,2,1.5);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E005',2026,9,6,1,0,2.5,0);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E006',2026,9,14,4,2,1,1);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E007',2026,9,10,2,1,3,2);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E008',2026,9,22,5,3,2,1);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E009',2026,9,5,1,0,1.5,0);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E010',2026,9,16,4,2,2.5,2);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E011',2026,9,20,3,2,1,1);
INSERT INTO `leave_balances` (`emp_id`,`year_no`,`month_no`,`el`,`fl`,`cpl`,`cl`,`cl_carried_forward`) VALUES ('E012',2026,9,13,4,1,2,1.5);

-- DATA: leave_applications
DELETE FROM `leave_applications`;
INSERT INTO `leave_applications` (`id`,`emp_id`,`leave_type`,`from_date`,`to_date`,`days`,`reason`,`status`,`applied_on`,`approved_by`,`approved_on`,`remarks`) VALUES ('LA001','E001','CL','2026-09-10','2026-09-10',1,'Personal work','APPROVED','2026-09-08','Sneha Reddy','2026-09-09',NULL);
INSERT INTO `leave_applications` (`id`,`emp_id`,`leave_type`,`from_date`,`to_date`,`days`,`reason`,`status`,`applied_on`,`approved_by`,`approved_on`,`remarks`) VALUES ('LA002','E002','FL','2026-09-15','2026-09-15',1,'Medical appointment','APPROVED','2026-09-12','Sneha Reddy','2026-09-13',NULL);
INSERT INTO `leave_applications` (`id`,`emp_id`,`leave_type`,`from_date`,`to_date`,`days`,`reason`,`status`,`applied_on`,`approved_by`,`approved_on`,`remarks`) VALUES ('LA003','E003','EL','2026-09-22','2026-09-24',3,'Family function','PENDING','2026-09-15',NULL,NULL,NULL);
INSERT INTO `leave_applications` (`id`,`emp_id`,`leave_type`,`from_date`,`to_date`,`days`,`reason`,`status`,`applied_on`,`approved_by`,`approved_on`,`remarks`) VALUES ('LA004','E005','CL','2026-09-18','2026-09-18',1,'Urgent personal work','PENDING','2026-09-16',NULL,NULL,NULL);
INSERT INTO `leave_applications` (`id`,`emp_id`,`leave_type`,`from_date`,`to_date`,`days`,`reason`,`status`,`applied_on`,`approved_by`,`approved_on`,`remarks`) VALUES ('LA005','E007','CPL','2026-09-20','2026-09-21',2,'Compensatory for weekend duty','APPROVED','2026-09-10','Sneha Reddy','2026-09-11',NULL);
INSERT INTO `leave_applications` (`id`,`emp_id`,`leave_type`,`from_date`,`to_date`,`days`,`reason`,`status`,`applied_on`,`approved_by`,`approved_on`,`remarks`) VALUES ('LA006','E004','EL','2026-09-25','2026-09-26',2,'Annual leave','PENDING','2026-09-16',NULL,NULL,NULL);
INSERT INTO `leave_applications` (`id`,`emp_id`,`leave_type`,`from_date`,`to_date`,`days`,`reason`,`status`,`applied_on`,`approved_by`,`approved_on`,`remarks`) VALUES ('LA007','E008','FL','2026-09-19','2026-09-19',1,'Festive occasion','REJECTED','2026-09-14','Sneha Reddy','2026-09-15','Production schedule conflict');

-- DATA: leave_transactions
DELETE FROM `leave_transactions`;
INSERT INTO `leave_transactions` (`id`,`emp_id`,`leave_type`,`transaction_date`,`days`,`balance`,`txn_type`,`reference_id`,`remarks`) VALUES ('LT001','E001','EL','2026-09-01',0.5,12.5,'CREDIT',NULL,'Monthly EL accrual');
INSERT INTO `leave_transactions` (`id`,`emp_id`,`leave_type`,`transaction_date`,`days`,`balance`,`txn_type`,`reference_id`,`remarks`) VALUES ('LT002','E001','CL','2026-09-10',-1,1.5,'DEBIT','LA001','Applied leave: LA001');
INSERT INTO `leave_transactions` (`id`,`emp_id`,`leave_type`,`transaction_date`,`days`,`balance`,`txn_type`,`reference_id`,`remarks`) VALUES ('LT003','E002','EL','2026-09-01',0.5,18,'CREDIT',NULL,'Monthly EL accrual');
INSERT INTO `leave_transactions` (`id`,`emp_id`,`leave_type`,`transaction_date`,`days`,`balance`,`txn_type`,`reference_id`,`remarks`) VALUES ('LT004','E002','FL','2026-09-15',-1,4,'DEBIT','LA002','Applied leave: LA002');
INSERT INTO `leave_transactions` (`id`,`emp_id`,`leave_type`,`transaction_date`,`days`,`balance`,`txn_type`,`reference_id`,`remarks`) VALUES ('LT005','E001','CL_CF','2026-08-31',1,1,'CARRYFORWARD',NULL,'CL carry forward from Aug 2026');
INSERT INTO `leave_transactions` (`id`,`emp_id`,`leave_type`,`transaction_date`,`days`,`balance`,`txn_type`,`reference_id`,`remarks`) VALUES ('LT006','E007','CPL','2026-09-20',-2,1,'DEBIT','LA005','Applied leave: LA005');
INSERT INTO `leave_transactions` (`id`,`emp_id`,`leave_type`,`transaction_date`,`days`,`balance`,`txn_type`,`reference_id`,`remarks`) VALUES ('LT007','E003','EL','2026-09-01',0.5,8,'CREDIT',NULL,'Monthly EL accrual');
INSERT INTO `leave_transactions` (`id`,`emp_id`,`leave_type`,`transaction_date`,`days`,`balance`,`txn_type`,`reference_id`,`remarks`) VALUES ('LT008','E004','EL','2026-09-01',0.5,15,'CREDIT',NULL,'Monthly EL accrual');

-- DATA: monthly_processing
DELETE FROM `monthly_processing`;
INSERT INTO `monthly_processing` (`id`,`emp_id`,`year_no`,`month_no`,`total_days`,`working_days`,`present_days`,`absent_days`,`half_days`,`late_days`,`early_out_days`,`week_off_days`,`holidays`,`el`,`fl`,`cpl`,`cl`,`lop`,`overtime_hours`,`processed_on`,`processed_by`,`approval_status`) VALUES ('MP001','E001',2026,8,31,26,22,1,0,3,2,5,0,0,0,0,1,1,4.5,'2026-09-01','Sneha Reddy','APPROVED');
INSERT INTO `monthly_processing` (`id`,`emp_id`,`year_no`,`month_no`,`total_days`,`working_days`,`present_days`,`absent_days`,`half_days`,`late_days`,`early_out_days`,`week_off_days`,`holidays`,`el`,`fl`,`cpl`,`cl`,`lop`,`overtime_hours`,`processed_on`,`processed_by`,`approval_status`) VALUES ('MP002','E002',2026,8,31,27,24,0,1,2,1,4,0,0,1,0,0,0,6,'2026-09-01','Sneha Reddy','APPROVED');
INSERT INTO `monthly_processing` (`id`,`emp_id`,`year_no`,`month_no`,`total_days`,`working_days`,`present_days`,`absent_days`,`half_days`,`late_days`,`early_out_days`,`week_off_days`,`holidays`,`el`,`fl`,`cpl`,`cl`,`lop`,`overtime_hours`,`processed_on`,`processed_by`,`approval_status`) VALUES ('MP003','E001',2026,9,30,25,14,0,0,1,1,4,0,0,0,0,1,0,2.3,NULL,NULL,'DRAFT');

-- DATA: holidays
DELETE FROM `holidays`;
INSERT INTO `holidays` (`id`,`holiday_date`,`name`,`type`) VALUES ('H001','2026-01-26','Republic Day','NATIONAL');
INSERT INTO `holidays` (`id`,`holiday_date`,`name`,`type`) VALUES ('H002','2026-08-15','Independence Day','NATIONAL');
INSERT INTO `holidays` (`id`,`holiday_date`,`name`,`type`) VALUES ('H003','2026-10-02','Gandhi Jayanti','NATIONAL');
INSERT INTO `holidays` (`id`,`holiday_date`,`name`,`type`) VALUES ('H004','2026-11-01','Kannada Rajyotsava','REGIONAL');
INSERT INTO `holidays` (`id`,`holiday_date`,`name`,`type`) VALUES ('H005','2026-12-25','Christmas','NATIONAL');
INSERT INTO `holidays` (`id`,`holiday_date`,`name`,`type`) VALUES ('H006','2026-10-24','Dussehra','REGIONAL');
INSERT INTO `holidays` (`id`,`holiday_date`,`name`,`type`) VALUES ('H007','2026-11-12','Diwali','REGIONAL');
SET FOREIGN_KEY_CHECKS=1;
-- End of HRMS seed data.
