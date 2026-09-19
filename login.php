<?php
require __DIR__ . '/config.php';
if (current_user()) {
    redirect(current_user()['role'] === 'admin' ? 'dashboard' : 'employee-dashboard');
}
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $statement = db()->prepare('SELECT * FROM users WHERE username=? AND active=1 LIMIT 1');
        $statement->execute([trim($_POST['username'] ?? '')]);
        $user = $statement->fetch();
        if ($user && password_verify($_POST['password'] ?? '', $user['password_hash'])) {
            login_user($user);
            redirect($user['role'] === 'admin' ? 'dashboard' : 'employee-dashboard');
        }
        $error = 'Invalid username or password.';
    } catch (Throwable $exception) {
        $error = 'Database is not ready. Import the SQL file and run seed.php first.';
    }
}
?>
<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>HRMS Login</title>
    <link rel="stylesheet" href="assets/style.css?v=20260920">
    <link rel="stylesheet" href="assets/light-theme.css?v=20260920">
</head>

<body class="login-page">
    <main class="login-shell">
        <section class="login-showcase">
            <div class="showcase-grid"></div>
            <div class="showcase-top"><img class="showcase-logo" src="assets/hrms-logo.svg" alt="HRMS - Human Resource Management System"><span class="secure-pill"><i></i> SYSTEM ONLINE</span></div>
            <div class="showcase-copy">
                <p class="eyebrow">PEOPLE OPERATIONS / 02</p>
                <h1>Your people,<br><em>in sync.</em></h1>
                <p>Attendance, leave, approvals, and employee records in one calm workspace.</p>
            </div>
            <div class="showcase-footer"><span>Leave &amp; Attendance Management</span><span>v2.4</span></div>
        </section>
        <section class="login-card-wrap">
            <form class="login-box" method="post">
                <div class="login-heading">
                    <p class="eyebrow">WELCOME BACK</p>
                    <h2>Sign in to HRMS</h2>
                    <p class="muted">Use Admin or your Employee ID to continue.</p>
                </div>
                <?php if ($error): ?><div class="flash error"><?= e($error) ?></div><?php endif; ?>
                <div class="field input-field"><label for="username">Admin username / Employee ID</label><span class="input-icon">@</span><input id="username" name="username" autocomplete="username"  required autofocus></div>
                <div class="field input-field"><label for="password">Password</label><span class="input-icon">*</span><input id="password" type="password" name="password" autocomplete="current-password" placeholder="Enter your password" required><button class="password-toggle" type="button" aria-label="Show password" onclick="togglePassword()">Show</button></div>
                <button class="btn btn-primary login-submit" type="submit"><span>Continue to workspace</span><b>→</b></button>
                <div class="login-note"><span class="lock-icon">▣</span><span>Your session is protected with secure authentication.</span></div>
                <p class="login-note" style="justify-content:center"><a href="register.php">New employee? Register here</a></p>
            </form>
        </section>
    </main>
    <script>function togglePassword(){const input=document.getElementById('password');const button=document.querySelector('.password-toggle');const visible=input.type==='text';input.type=visible?'password':'text';button.textContent=visible?'Show':'Hide';button.setAttribute('aria-label',visible?'Show password':'Hide password');}</script>
</body>

</html>