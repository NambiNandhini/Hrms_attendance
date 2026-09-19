<?php
$titles = ['dashboard' => 'Dashboard', 'employees' => 'Employee Master', 'shifts' => 'Shift Timings', 'punches' => 'Punch Records', 'attendance' => 'Attendance Records', 'leave-balance' => 'Leave Balances', 'leave-applications' => 'Leave Applications', 'leave-transactions' => 'Leave Transactions', 'monthly-processing' => 'Monthly Processing', 'reports' => 'Reports', 'leave-types' => 'Leave Types', 'employee-dashboard' => 'My Dashboard', 'employee-leave' => 'Apply for Leave'];
$page = $_GET['page'] ?? 'dashboard';
?>
<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>HRMS — <?= e($titles[$page] ?? 'HRMS') ?></title>
    <link rel="icon" type="image/svg+xml" href="assets/hrms-logo.svg?v=20260920">
    <link rel="stylesheet" href="assets/style.css">
    <link rel="stylesheet" href="assets/light-theme.css">
</head>

<body>
    <div class="app">
        <aside class="sidebar">
            <div class="logo"><img src="assets/hrms-logo.svg?v=20260920" alt="HRMS - Human Resource Management System"><small>Leave &amp; Attendance</small></div>
            <nav><?php $groups = $user['role'] === 'admin' ? ['Overview' => [['dashboard', '▦', 'Dashboard']], 'Master Data' => [['employees', '◈', 'Employees'], ['shifts', '⏱', 'Shifts'], ['leave-types', '◌', 'Leave Types']], 'Attendance Management' => [['punches', '⬛', 'Punch Records'], ['attendance', '▤', 'Attendance']], 'Leave' => [['leave-balance', '◉', 'Leave Balances'], ['leave-applications', '◎', 'Leave Applications'], ['leave-transactions', '≡', 'Leave Status']], 'Processing' => [['monthly-processing', '◫', 'Monthly Processing']], 'Reports' => [['reports', '◪', 'Reports']]] : ['Employee' => [['employee-dashboard', '▦', 'My Dashboard'], ['employee-leave', '◎', 'Apply for Leave']]];
                    foreach ($groups as $g => $items): ?><div class="nav-group">
                        <div class="nav-label"><?= e($g) ?></div><?php foreach ($items as [$slug, $icon, $label]): ?><a class="sidebar-item <?= $page === $slug ? 'active' : '' ?>" href="index.php?page=<?= $slug ?>"><span><?= $icon ?></span><?= e($label) ?></a><?php endforeach; ?>
                    </div><?php endforeach; ?></nav>
            <div class="sidebar-footer">
                <div><?= e(strtoupper($user['role'])) ?> </div><a class="sidebar-item" href="logout.php">Log out </a>
            </div>
        </aside>
        <div class="content">
            <header class="topbar">
                <div><span class="crumb">HRMS</span><span>/</span><strong><?= e($titles[$page] ?? 'Dashboard') ?></strong></div>
                <div class="user"><span class="live"><i></i> </span><b><?= e(strtoupper(substr($user['username'], 0, 2))) ?></b><span><strong><?= e($user['username']) ?></strong><small><?= e(ucfirst($user['role'])) ?></small></span></div>
            </header>
            <main><?php flash(); ?>