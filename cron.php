<?php
require __DIR__.'/config.php';
require __DIR__.'/includes/hrms.php';
if (PHP_SAPI !== 'cli' && ($_GET['key'] ?? '') !== (getenv('HRMS_CRON_KEY') ?: '')) { http_response_code(403); exit('Forbidden'); }
$pdo = db();
$date = new DateTimeImmutable('yesterday');
$pdo->beginTransaction();
try { $count = hrms_process_month($pdo, (int)$date->format('Y'), (int)$date->format('m'), 'CRON', $date); $pdo->commit(); echo "Processed {$count} employee record(s).\n"; }
catch (Throwable $exception) { $pdo->rollBack(); http_response_code(500); echo $exception->getMessage()."\n"; exit(1); }