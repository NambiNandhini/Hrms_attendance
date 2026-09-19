# HRMS Attendance Management Module — Core PHP

## Included modules
- Dashboard
- Employee Master — search/filter, add/edit employee, shift and week-off assignment
- Shift Configuration — shift timing, grace period, half-day threshold, overnight flag
- Punch Records — biometric history + manual punch entry
- Attendance — status filtering and manual correction workflow
- Leave Balances — EL / FL / CPL / CL / carry-forward
- Leave Applications — approve/reject workflow
- Leave Transactions — credit/debit/carry-forward audit history
- Monthly Processing — processing draft creation and status view
- Reports — attendance distribution and operational report shortcuts
- Login and role-based access — Admin and Employee portals
- Employee leave dashboard — balances, applications, status and history
- Employee registration — new employees receive an Employee ID login and initial leave balance
- Public employee signup — new employees can register from the login page before signing in
- Attendance exports — employees can filter a month and download attendance as PDF or Excel files
- Leave type configuration — automatic deduction priority
- Cron processing — automatic attendance and leave deduction

## Run on XAMPP/WAMP
1. Extract this folder into `C:/xampp/htdocs/hrms/` (or your WAMP `www` folder).
2. Start **Apache** and **MySQL**.
3. Open phpMyAdmin: `http://localhost/phpmyadmin/`.
4. In phpMyAdmin, import `sql/hrms_attendance.sql`. This single file creates the `hrms_attendance` database, tables, indexes, constraints, and demo data.
5. Open `http://localhost/hrms/`. You will be redirected to the login screen.

## Working flow

### 1. Employee registration and login

New employees can start from the login page:

1. Open `http://localhost/hrms/register.php`, or click **New employee? Register here** on the login page.
2. Enter the employee name, department, designation, joining date, and weekly off.
3. HRMS automatically creates an Employee ID such as `E013`.
4. HRMS creates the employee account, assigns the default general shift, and creates the initial leave balance.
5. The registration confirmation displays the login details.
6. The employee signs in at `login.php` using the Employee ID and the common employee password `employee123`.

Employee signup accounts are active immediately. The employee can access only the employee portal and cannot open admin pages.

### 2. Admin login and employee management

1. Sign in with the admin account: `admin` / `admin123`.
2. Open **Employees** to search, edit, or add employees.
3. When an admin adds an employee, HRMS generates the Employee ID login and displays the login ID and password in the confirmation message.
4. The employee receives the same employee portal access after signing in.
5. Admin and employee sessions have separate logout labels and permissions.

### 3. Employee portal

After an employee signs in, the dashboard shows data filtered by that employee's ID:

- Employee profile, department, designation, and login ID
- EL, FL, CPL, and CL leave balances
- Attendance records for the selected month
- Leave application history and approval status
- Apply-for-leave form
- Attendance PDF and Excel download buttons

An employee cannot view another employee's attendance, leave balance, leave history, or downloads.

### 4. Attendance flow

1. Attendance is entered through biometric records or the admin **Punch Records** page.
2. Admin can run monthly processing from **Monthly Processing**, or the daily cron can process the previous day.
3. The processor calculates present, absent, half-day, late, early-out, overtime, week-off, holiday, and missing-punch statuses.
4. The employee dashboard displays only the signed-in employee's processed attendance.
5. The month selector controls both the attendance table and the PDF/Excel export month.

### 5. Leave application flow

1. Employee opens **Apply for Leave** and selects a leave type and date range.
2. HRMS creates the request with `PENDING` status.
3. Admin opens **Leave Applications** and approves or rejects it.
4. On approval, the requested leave type balance is reduced and a debit is added to **Leave Transactions**.
5. Rejected requests do not reduce the balance.
6. The employee sees the updated status in the dashboard leave history.

### 6. Automatic leave deduction

During attendance processing, an absent working day is automatically deducted using the configured active leave priority:

`EL -> FL -> CPL -> CL`

The priority can be changed from **Leave Types**. Weekly offs (`WO`) and holidays are not deducted. If all configured balances are exhausted, the remaining absence is recorded as `LOP`.

### 7. Attendance downloads

On the employee dashboard:

1. Select the required attendance month.
2. Click **Download Attendance PDF** for a printable PDF report.
3. Click **Download Excel** for a real `.xlsx` workbook.

Both downloads are protected by login and employee downloads contain only that employee's records. The endpoints are `download.php` for PDF and `excel.php` for Excel.

### 8. Daily cron flow

Run the following command once per day after attendance for the previous day is available:

```text
php C:/wamp64/www/hrms/cron.php
```

The cron process:

1. Reads active employees and their shifts.
2. Calculates attendance through yesterday.
3. Updates attendance records without creating duplicate automatic deductions.
4. Applies leave priority and records leave transactions.
5. Creates or updates monthly processing summaries.

Manual monthly processing remains available to administrators for a complete month close.

## Main URLs

- Login: `login.php`
- Employee signup: `register.php`
- Admin or employee application: `index.php`
- Logout: `logout.php`
- Attendance PDF: `download.php?month=YYYY-MM`
- Attendance Excel: `excel.php?month=YYYY-MM`
- Daily processing: `cron.php`

### Demo accounts
- Admin: `admin` / `admin123`
- Employee: employee ID such as `E001` / `employee123`

Every active employee receives an account using their employee ID (`E001`, `E002`, etc.) and the common employee password `employee123`. Employees can only see their own attendance, leave balance, and leave history.

### Automatic cron processing
Run this daily from Windows Task Scheduler or a server cron at the end of the attendance day:

```text
php C:/wamp64/www/hrms/cron.php
```

The processor is idempotent for automatic deductions and follows the configured leave type priority. Weekly offs are not deducted; unused CL carry-forward remains visible in the balance and transaction model.

### MySQL credentials
The default configuration is:
- Host: `localhost`
- Database: `hrms_attendance`
- Username: `root`
- Password: empty

If your XAMPP/WAMP MySQL password is different, edit `config.php`.

## Notes
The application stores all data in MySQL and does not read JSON data at runtime. No demo records are inserted automatically.
