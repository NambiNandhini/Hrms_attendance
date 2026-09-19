<?php

function hrms_next_id(PDO $pdo, string $table, string $prefix): string
{
    $allowed = [
        'attendance_records' => 'attendance_records',
        'leave_transactions' => 'leave_transactions',
        'monthly_processing' => 'monthly_processing',
    ];
    if (!isset($allowed[$table])) {
        throw new InvalidArgumentException('Invalid ID table.');
    }
    $length = strlen($prefix) + 1;
    $sql = "SELECT COALESCE(MAX(CAST(SUBSTRING(id, {$length}) AS UNSIGNED)), 0) + 1 FROM {$allowed[$table]}";
    $number = (int)$pdo->query($sql)->fetchColumn();
    return $prefix.str_pad((string)$number, 3, '0', STR_PAD_LEFT);
}

function hrms_shift_datetime(string $date, string $time, bool $nextDay = false): DateTimeImmutable
{
    $value = new DateTimeImmutable($date.' '.$time);
    return $nextDay ? $value->modify('+1 day') : $value;
}

function hrms_calculate_attendance(PDO $pdo, array $employee, array $shift, string $date): array
{
    $nextDate = (new DateTimeImmutable($date))->modify('+1 day')->format('Y-m-d');
    $endDate = (int)$shift['overnight_shift'] ? $nextDate : $date;
    $statement = $pdo->prepare(
        'SELECT punch_date, punch_time, punch_type FROM punch_records
         WHERE emp_id=? AND punch_date BETWEEN ? AND ? ORDER BY punch_date, punch_time'
    );
    $statement->execute([$employee['id'], $date, $endDate]);
    $punches = $statement->fetchAll();
    $in = null;
    $out = null;
    foreach ($punches as $punch) {
        if ($punch['punch_type'] === 'IN' && $in === null) {
            $in = $punch;
        } elseif ($punch['punch_type'] === 'OUT' && $in !== null && $out === null) {
            $out = $punch;
        }
    }

    $weekOffDays = array_map('intval', explode(',', (string)$employee['week_off_days']));
    $dayOfWeek = (int)(new DateTimeImmutable($date))->format('w');
    $holiday = $pdo->prepare('SELECT 1 FROM holidays WHERE holiday_date=? LIMIT 1');
    $holiday->execute([$date]);
    $isHoliday = (bool)$holiday->fetchColumn();
    $status = in_array($dayOfWeek, $weekOffDays, true) && $in === null ? 'WO' : ($isHoliday && $in === null ? 'H' : 'A');
    $workingMinutes = 0;
    $lateMinutes = 0;
    $earlyOutMinutes = 0;
    $overtimeMinutes = 0;

    if ($in !== null) {
        $start = hrms_shift_datetime($date, $shift['start_time']);
        $end = hrms_shift_datetime($date, $shift['end_time'], (bool)$shift['overnight_shift']);
        $inAt = hrms_shift_datetime($in['punch_date'], $in['punch_time']);
        $lateMinutes = max(0, (int)(($inAt->getTimestamp() - $start->getTimestamp()) / 60) - (int)$shift['grace_minutes']);
        if ($out !== null) {
            $outAt = hrms_shift_datetime($out['punch_date'], $out['punch_time']);
            $workingMinutes = max(0, (int)(($outAt->getTimestamp() - $inAt->getTimestamp()) / 60));
            $earlyOutMinutes = max(0, (int)(($end->getTimestamp() - $outAt->getTimestamp()) / 60));
            $overtimeMinutes = max(0, (int)(($outAt->getTimestamp() - $end->getTimestamp()) / 60));
            if ($workingMinutes < (int)$shift['half_day_threshold_minutes']) {
                $status = 'HD';
            } elseif ($lateMinutes > 0) {
                $status = 'L';
            } elseif ($earlyOutMinutes > 0) {
                $status = 'EO';
            } else {
                $status = 'P';
            }
        } else {
            $status = 'MP';
        }
    }

    return [
        'status' => $status,
        'punch_in' => $in['punch_time'] ?? null,
        'punch_out' => $out['punch_time'] ?? null,
        'working_minutes' => $workingMinutes,
        'late_minutes' => $lateMinutes,
        'early_out_minutes' => $earlyOutMinutes,
        'overtime_minutes' => $overtimeMinutes,
    ];
}

function hrms_upsert_attendance(PDO $pdo, array $employee, string $date, array $attendance): void
{
    $id = hrms_next_id($pdo, 'attendance_records', 'A');
    $statement = $pdo->prepare(
        'INSERT INTO attendance_records
         (id, emp_id, attendance_date, status, punch_in, punch_out, working_minutes, late_minutes, early_out_minutes, overtime_minutes, approval_status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
         status=VALUES(status), punch_in=VALUES(punch_in), punch_out=VALUES(punch_out),
         working_minutes=VALUES(working_minutes), late_minutes=VALUES(late_minutes),
         early_out_minutes=VALUES(early_out_minutes), overtime_minutes=VALUES(overtime_minutes)'
    );
    $statement->execute([
        $id,
        $employee['id'],
        $date,
        $attendance['status'],
        $attendance['punch_in'],
        $attendance['punch_out'],
        $attendance['working_minutes'],
        $attendance['late_minutes'],
        $attendance['early_out_minutes'],
        $attendance['overtime_minutes'],
        'PENDING',
    ]);
}

function hrms_deduct_leave(PDO $pdo, string $employeeId, int $year, int $month, float $days, string $reference, string $transactionDate): array
{
    if ($days <= 0) {
        return [];
    }
    $balance = $pdo->prepare('SELECT * FROM leave_balances WHERE emp_id=? FOR UPDATE');
    $balance->execute([$employeeId]);
    $row = $balance->fetch();
    if (!$row) {
        throw new RuntimeException('Leave balance is missing for employee '.$employeeId.'.');
    }
    $remaining = $days;
    $deductions = [];
    $types = $pdo->query('SELECT code FROM leave_types WHERE active=1 ORDER BY priority_no, code')->fetchAll(PDO::FETCH_COLUMN);
    if (!$types) { $types = ['EL', 'FL', 'CPL', 'CL']; }
    foreach ($types as $configuredType) {
        $type = strtolower($configuredType);
        if (!in_array($type, ['el', 'fl', 'cpl', 'cl'], true)) { continue; }
        $available = max(0, (float)$row[$type]);
        $used = min($available, $remaining);
        if ($used > 0) {
            $newBalance = $available - $used;
            $update = $pdo->prepare("UPDATE leave_balances SET {$type}=? WHERE emp_id=?");
            $update->execute([$newBalance, $employeeId]);
            $transaction = $pdo->prepare(
                'INSERT INTO leave_transactions
                 (id, emp_id, leave_type, transaction_date, days, balance, txn_type, reference_id, remarks)
                 VALUES (?, ?, ?, ?, ?, ?, "DEBIT", ?, ?)'
            );
            $transaction->execute([
                hrms_next_id($pdo, 'leave_transactions', 'LT'),
                $employeeId,
                strtoupper($type),
                $transactionDate,
                -$used,
                $newBalance,
                $reference,
                'Automatic monthly attendance deduction',
            ]);
            $deductions[] = ['type' => strtoupper($type), 'days' => $used];
            $remaining -= $used;
            if ($remaining <= 0) {
                break;
            }
        }
    }
    if ($remaining > 0) {
        $deductions[] = ['type' => 'LOP', 'days' => $remaining];
    }
    return $deductions;
}

function hrms_process_month(PDO $pdo, int $year, int $month, string $processedBy, ?DateTimeImmutable $throughDay = null): int
{
    $firstDay = new DateTimeImmutable(sprintf('%04d-%02d-01', $year, $month));
    $lastDay = $firstDay->modify('last day of this month');
    $processLastDay = $throughDay && $throughDay < $lastDay ? $throughDay : $lastDay;
    $employees = $pdo->query('SELECT e.*, s.start_time, s.end_time, s.grace_minutes, s.half_day_threshold_minutes, s.overnight_shift, s.working_hours FROM employees e JOIN shifts s ON s.id=e.shift_id WHERE e.active=1 ORDER BY e.id')->fetchAll();
    $summaryCount = 0;
    foreach ($employees as $employee) {
        $summary = ['total_days' => (int)$lastDay->format('d'), 'working_days' => 0, 'present_days' => 0, 'absent_days' => 0, 'half_days' => 0, 'late_days' => 0, 'early_out_days' => 0, 'week_off_days' => 0, 'holidays' => 0, 'el' => 0, 'fl' => 0, 'cpl' => 0, 'cl' => 0, 'lop' => 0, 'overtime_hours' => 0];
        for ($day = $firstDay; $day <= $processLastDay; $day = $day->modify('+1 day')) {
            $date = $day->format('Y-m-d');
            $attendance = hrms_calculate_attendance($pdo, $employee, $employee, $date);
            hrms_upsert_attendance($pdo, $employee, $date, $attendance);
            $status = $attendance['status'];
            if ($status === 'A') {
                $reference = 'AUTO-'.$employee['id'].'-'.$date;
                $alreadyDeducted = $pdo->prepare('SELECT 1 FROM leave_transactions WHERE reference_id=? LIMIT 1');
                $alreadyDeducted->execute([$reference]);
                $deductions = $alreadyDeducted->fetchColumn() ? [] : hrms_deduct_leave($pdo, $employee['id'], $year, $month, 1, $reference, $date);
                if ($deductions && $deductions[0]['type'] !== 'LOP') {
                    $status = $deductions[0]['type'];
                    $updateAttendance = $pdo->prepare('UPDATE attendance_records SET status=? WHERE emp_id=? AND attendance_date=? AND is_manually_edited=0');
                    $updateAttendance->execute([$status, $employee['id'], $date]);
                    foreach ($deductions as $deduction) {
                        if ($deduction['type'] === 'LOP') { $summary['lop'] += $deduction['days']; }
                        elseif (array_key_exists(strtolower($deduction['type']), $summary)) { $summary[strtolower($deduction['type'])] += $deduction['days']; }
                    }
                } else {
                    $summary['lop'] += 1;
                }
            }
            if ($status === 'WO') { $summary['week_off_days']++; continue; }
            if ($status === 'H') { $summary['holidays']++; continue; }
            $summary['working_days']++;
            if (in_array($status, ['P', 'L', 'EO'], true)) { $summary['present_days']++; }
            if ($status === 'A' || $status === 'MP') { $summary['absent_days']++; }
            if ($status === 'HD') { $summary['half_days']++; }
            if ($status === 'L') { $summary['late_days']++; }
            if ($status === 'EO') { $summary['early_out_days']++; }
            $summary['overtime_hours'] += $attendance['overtime_minutes'] / 60;
        }
        $id = hrms_next_id($pdo, 'monthly_processing', 'MP');
        $statement = $pdo->prepare(
            'INSERT INTO monthly_processing
             (id, emp_id, year_no, month_no, total_days, working_days, present_days, absent_days, half_days, late_days, early_out_days, week_off_days, holidays, el, fl, cpl, cl, lop, overtime_hours, processed_on, processed_by, approval_status)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURDATE(), ?, "DRAFT")
             ON DUPLICATE KEY UPDATE total_days=VALUES(total_days), working_days=VALUES(working_days), present_days=VALUES(present_days), absent_days=VALUES(absent_days), half_days=VALUES(half_days), late_days=VALUES(late_days), early_out_days=VALUES(early_out_days), week_off_days=VALUES(week_off_days), holidays=VALUES(holidays), overtime_hours=VALUES(overtime_hours), processed_on=CURDATE(), processed_by=VALUES(processed_by)'
        );
        $statement->execute([$id, $employee['id'], $year, $month, $summary['total_days'], $summary['working_days'], $summary['present_days'], $summary['absent_days'], $summary['half_days'], $summary['late_days'], $summary['early_out_days'], $summary['week_off_days'], $summary['holidays'], $summary['el'], $summary['fl'], $summary['cpl'], $summary['cl'], $summary['lop'], $summary['overtime_hours'], $processedBy]);
        $summaryCount++;
    }
    return $summaryCount;
}
