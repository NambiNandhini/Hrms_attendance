<?php
// XAMPP/WAMP default MySQL configuration. Update these values if needed.
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

const DB_HOST = '127.0.0.1';
const DB_NAME = 'hrms_attendance';
const DB_USER = 'root';
const DB_PASS = '';

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO('mysql:host='.DB_HOST.';dbname='.DB_NAME.';charset=utf8mb4', DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
        $pdo->exec("CREATE TABLE IF NOT EXISTS leave_types (code VARCHAR(10) PRIMARY KEY, name VARCHAR(100) NOT NULL, priority_no INT NOT NULL, annual_days DECIMAL(5,1) NOT NULL DEFAULT 0, active TINYINT(1) NOT NULL DEFAULT 1)");
        $pdo->exec("CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(80) UNIQUE NOT NULL, password_hash VARCHAR(255) NOT NULL, role ENUM('admin','employee') NOT NULL, emp_id VARCHAR(20) NULL, active TINYINT(1) NOT NULL DEFAULT 1, FOREIGN KEY (emp_id) REFERENCES employees(id) ON DELETE SET NULL)");
        $pdo->exec("INSERT IGNORE INTO leave_types(code,name,priority_no,annual_days) VALUES ('EL','Earned Leave',1,18),('FL','Flexi Leave',2,4),('CPL','Compensatory Leave',3,2),('CL','Casual Leave',4,3)");
        $adminHash = password_hash('admin123', PASSWORD_DEFAULT);
        $pdo->prepare("INSERT INTO users(username,password_hash,role,emp_id) VALUES ('admin',?,'admin',NULL) ON DUPLICATE KEY UPDATE password_hash=VALUES(password_hash)")->execute([$adminHash]);
        $employeeHash = password_hash('employee123', PASSWORD_DEFAULT);
        $pdo->exec("DELETE FROM users WHERE username='employee'");
        $employeeUsers = $pdo->query("SELECT id FROM employees WHERE active=1")->fetchAll(PDO::FETCH_COLUMN);
        $employeeStatement = $pdo->prepare("INSERT INTO users(username,password_hash,role,emp_id) VALUES (?,?,'employee',?) ON DUPLICATE KEY UPDATE password_hash=VALUES(password_hash),role='employee',emp_id=VALUES(emp_id),active=1");
        foreach ($employeeUsers as $employeeId) {
            $employeeStatement->execute([$employeeId, $employeeHash, $employeeId]);
        }
    }
    return $pdo;
}
function e($v): string { return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8'); }
function redirect($page='dashboard', $msg=''): never { $url='index.php?page='.rawurlencode($page); if($msg!=='') $url.='&msg='.rawurlencode($msg); header('Location: '.$url); exit; }
function flash(): void { if(isset($_GET['msg'])) echo '<div class="flash">'.e($_GET['msg']).'</div>'; }

function current_user(): ?array { return $_SESSION['hrms_user'] ?? null; }
function login_user(array $user): void { $_SESSION['hrms_user'] = ['id' => $user['id'], 'username' => $user['username'], 'role' => $user['role'], 'emp_id' => $user['emp_id']]; }
function logout_user(): void { unset($_SESSION['hrms_user']); }
function require_login(): array { $user = current_user(); if (!$user) { header('Location: login.php'); exit; } return $user; }
function require_role(string $role): array { $user = require_login(); if ($user['role'] !== $role) { redirect($user['role'] === 'employee' ? 'employee-dashboard' : 'dashboard', 'Access denied'); } return $user; }
