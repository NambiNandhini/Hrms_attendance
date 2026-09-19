<?php
require __DIR__.'/config.php';
$user = require_login();
$pdo = db();
$month = preg_match('/^\d{4}-\d{2}$/', $_GET['month'] ?? '') ? $_GET['month'] : date('Y-m');
$employeeId = $user['role'] === 'employee' ? $user['emp_id'] : trim($_GET['emp'] ?? '');
$sql = 'SELECT a.attendance_date,e.emp_code,e.name,e.department,a.status,a.punch_in,a.punch_out,a.working_minutes,a.late_minutes,a.early_out_minutes,a.overtime_minutes,a.approval_status FROM attendance_records a JOIN employees e ON e.id=a.emp_id WHERE DATE_FORMAT(a.attendance_date, "%Y-%m")=?';
$params = [$month];
if ($employeeId !== '') { $sql .= ' AND a.emp_id=?'; $params[] = $employeeId; }
$sql .= ' ORDER BY a.attendance_date DESC,e.emp_code';
$statement = $pdo->prepare($sql);
$statement->execute($params);
$xml = static fn(string $value): string => htmlspecialchars($value, ENT_XML1 | ENT_QUOTES, 'UTF-8');
$rows = '<row><c r="A1" t="inlineStr"><is><t>HRMS Attendance Report</t></is></c></row><row><c r="A2" t="inlineStr"><is><t>Month: '.$xml($month).' | Employee: '.$xml($employeeId ?: 'All employees').'</t></is></c></row>';
$headers = ['Date','Employee ID','Employee Name','Department','Status','In Time','Out Time','Working Minutes','Late Minutes','Early Out Minutes','Overtime Minutes','Approval'];
$rows .= '<row>'; foreach ($headers as $column => $header) { $rows .= '<c r="'.chr(65 + $column).'3" s="1" t="inlineStr"><is><t>'.$xml($header).'</t></is></c>'; } $rows .= '</row>';
foreach ($statement->fetchAll(PDO::FETCH_ASSOC) as $rowNumber => $row) {
    $excelRow = $rowNumber + 4;
    $values = [$row['attendance_date'], $row['emp_code'], $row['name'], $row['department'], $row['status'], $row['punch_in'] ?: '-', $row['punch_out'] ?: '-', (string)(int)$row['working_minutes'], (string)(int)$row['late_minutes'], (string)(int)$row['early_out_minutes'], (string)(int)$row['overtime_minutes'], $row['approval_status']];
    $rows .= '<row>'; foreach ($values as $column => $value) { $rows .= '<c r="'.chr(65 + $column).$excelRow.'" t="inlineStr"><is><t>'.$xml((string)$value).'</t></is></c>'; } $rows .= '</row>';
}
$files = [
    '[Content_Types].xml' => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>',
    '_rels/.rels' => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    'xl/workbook.xml' => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Attendance" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels' => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>',
    'xl/styles.xml' => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="1"><fill><patternFill patternType="none"/></fill></fills><borders count="1"><border/></borders><cellXfs count="2"><xf/><xf fontId="1"/></cellXfs></styleSheet>',
    'xl/worksheets/sheet1.xml' => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><cols><col min="1" max="12" width="18" customWidth="1"/></cols><sheetData>'.$rows.'</sheetData></worksheet>',
];
$temp = tempnam(sys_get_temp_dir(), 'hrms-xlsx-'); $archive = new ZipArchive(); $archive->open($temp, ZipArchive::CREATE | ZipArchive::OVERWRITE); foreach ($files as $path => $content) { $archive->addFromString($path, $content); } $archive->close();
header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
header('Content-Disposition: attachment; filename="attendance-'.($employeeId ?: 'all').'-'.$month.'.xlsx"');
readfile($temp); unlink($temp); exit;
