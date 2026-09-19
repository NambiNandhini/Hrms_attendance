<?php
require __DIR__.'/config.php';
if (current_user()) { redirect(current_user()['role'] === 'admin' ? 'dashboard' : 'employee-dashboard'); }
$error = '';
$success = null;
$departments = ['Production','Quality','Maintenance','Stores','HR','Admin','Safety'];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo = db();
        $name = trim($_POST['name'] ?? '');
        $department = trim($_POST['department'] ?? '');
        $designation = trim($_POST['designation'] ?? '');
        $joinDate = $_POST['join_date'] ?? date('Y-m-d');
        $weekOff = implode(',', $_POST['week_off_days'] ?? ['0']);
        if ($name === '' || $designation === '' || !in_array($department, $departments, true)) {
            throw new RuntimeException('Please complete all required employee details.');
        }
        $nextNumber = (int)$pdo->query("SELECT COALESCE(MAX(CAST(SUBSTRING(id,2) AS UNSIGNED)),0)+1 FROM employees")->fetchColumn();
        $employeeId = 'E'.str_pad((string)$nextNumber, 3, '0', STR_PAD_LEFT);
        $employeeCode = 'MFG-'.str_pad((string)$nextNumber, 3, '0', STR_PAD_LEFT);
        $shiftId = $pdo->query("SELECT id FROM shifts WHERE id='S4' LIMIT 1")->fetchColumn() ?: $pdo->query('SELECT id FROM shifts ORDER BY id LIMIT 1')->fetchColumn();
        if (!$shiftId) { throw new RuntimeException('No shift configuration is available. Please contact HR.'); }
        $pdo->beginTransaction();
        $employee = $pdo->prepare('INSERT INTO employees(id,emp_code,name,department,designation,shift_id,join_date,active,week_off_days) VALUES(?,?,?,?,?,?,?,?,?)');
        $employee->execute([$employeeId,$employeeCode,$name,$department,$designation,$shiftId,$joinDate,1,$weekOff]);
        $account = $pdo->prepare("INSERT INTO users(username,password_hash,role,emp_id,active) VALUES(?,?, 'employee',?,1)");
        $account->execute([$employeeId,password_hash('employee123', PASSWORD_DEFAULT),$employeeId]);
        $balance = $pdo->prepare('INSERT INTO leave_balances(emp_id,year_no,month_no,el,fl,cpl,cl,cl_carried_forward) VALUES(?,?,?,?,?,?,?,?)');
        $balance->execute([$employeeId,(int)date('Y'),(int)date('n'),18,4,2,3,0]);
        $pdo->commit();
        $success = ['id' => $employeeId, 'password' => 'employee123'];
    } catch (Throwable $exception) {
        if (isset($pdo) && $pdo->inTransaction()) { $pdo->rollBack(); }
        $error = $exception->getCode() === '23000' ? 'This employee already exists. Please try again.' : $exception->getMessage();
    }
}
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Employee Registration | HRMS</title><link rel="stylesheet" href="assets/style.css?v=20260920"><link rel="stylesheet" href="assets/light-theme.css?v=20260920"></head><body class="login-page"><main class="login-shell register-shell"><section class="login-showcase"><div class="showcase-grid"></div><div class="showcase-top"><span class="brand-mark">H</span><span>HRMS</span><span class="secure-pill"><i></i> SYSTEM ONLINE</span></div><div class="showcase-copy"><p class="eyebrow">NEW TEAM MEMBER / 03</p><h1>Start your<br><em>workday</em> here.</h1><p>Create your employee profile and receive your Employee ID login.</p></div><div class="showcase-footer"><span>Leave &amp; Attendance Management</span><span>v2.4</span></div></section><section class="login-card-wrap"><div class="login-box"><div class="login-heading"><p class="eyebrow">EMPLOYEE SIGNUP</p><h2>Create your profile</h2><p class="muted">Your Employee ID will be generated automatically.</p></div><?php if($error): ?><div class="flash error"><?=e($error)?></div><?php endif; ?><?php if($success): ?><div class="flash success"><b>Registration complete</b><br>Login ID: <strong><?=e($success['id'])?></strong><br>Password: <strong><?=e($success['password'])?></strong><br><a href="login.php">Continue to login</a></div><?php else: ?><form method="post"><div class="field"><label>Full Name</label><input name="name" value="<?=e($_POST['name']??'')?>" required autofocus></div><div class="field"><label>Department</label><select name="department" required><option value="">Select department</option><?php foreach($departments as $department): ?><option <?=($_POST['department']??'')===$department?'selected':''?>><?=e($department)?></option><?php endforeach; ?></select></div><div class="field"><label>Designation</label><input name="designation" value="<?=e($_POST['designation']??'')?>" placeholder="e.g. Operator" required></div><div class="field"><label>Join Date</label><input type="date" name="join_date" value="<?=e($_POST['join_date']??date('Y-m-d'))?>" required></div><div class="field"><label>Weekly Off</label><select name="week_off_days[]"><option value="0">Sunday</option><option value="6">Saturday</option></select></div><button class="btn btn-primary login-submit" type="submit"><span>Create employee login</span><b>→</b></button><p class="login-note"><a href="login.php">Already registered? Sign in</a></p></form><?php endif; ?></div></section></main></body></html>
