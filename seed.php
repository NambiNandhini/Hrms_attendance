<?php
require __DIR__.'/config.php';
$pdo = new PDO('mysql:host='.DB_HOST.';charset=utf8mb4', DB_USER, DB_PASS, [
	PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);
try {
 $pdo->exec(file_get_contents(__DIR__.'/sql/hrms_attendance.sql'));
 $pdo->exec("INSERT IGNORE INTO leave_types(code,name,priority_no,annual_days) VALUES ('EL','Earned Leave',1,18),('FL','Flexi Leave',2,4),('CPL','Compensatory Leave',3,2),('CL','Casual Leave',4,3)");
 $adminHash = password_hash('admin123', PASSWORD_DEFAULT);
 $employeeHash = password_hash('employee123', PASSWORD_DEFAULT);
 $pdo->exec("DELETE FROM users WHERE username='employee'");
 $pdo->prepare("INSERT INTO users(username,password_hash,role,emp_id) VALUES ('admin',?,'admin',NULL) ON DUPLICATE KEY UPDATE password_hash=VALUES(password_hash),role='admin',emp_id=NULL,active=1")->execute([$adminHash]);
 $employeeStatement = $pdo->prepare("INSERT INTO users(username,password_hash,role,emp_id) VALUES (?,?,'employee',?) ON DUPLICATE KEY UPDATE password_hash=VALUES(password_hash),role='employee',emp_id=VALUES(emp_id),active=1");
 foreach ($pdo->query('SELECT id FROM employees WHERE active=1')->fetchAll(PDO::FETCH_COLUMN) as $employeeId) {
  $employeeStatement->execute([$employeeId, $employeeHash, $employeeId]);
 }
 foreach ([
  'ALTER TABLE attendance_records ADD UNIQUE KEY employee_attendance_day (emp_id, attendance_date)',
  'ALTER TABLE monthly_processing ADD UNIQUE KEY employee_processing_month (emp_id, year_no, month_no)',
 ] as $migration) {
  try {$pdo->exec($migration);} catch(Throwable $ignored) {}
 }
 echo '<h2>HRMS database schema initialized successfully.</h2><p>Import your MySQL data into the <b>'.e(DB_NAME).'</b> database, then <a href="index.php">open HRMS</a>.</p>';
} catch(Throwable $e) {
 http_response_code(500);
 echo '<pre>'.htmlspecialchars($e->getMessage()).'</pre>';
}
