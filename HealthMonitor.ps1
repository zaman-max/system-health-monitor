# ============================================
# System Health Monitor
# Author: Your Name
# Description: Monitors CPU, RAM, Disk, 
#              Processes and generates HTML report
# ============================================

# --- Collect Data ---

# CPU Usage
$CPU = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average

# RAM Usage
$OS = Get-WmiObject Win32_OperatingSystem
$TotalRAM = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
$FreeRAM = [math]::Round($OS.FreePhysicalMemory / 1MB, 2)
$UsedRAM = [math]::Round($TotalRAM - $FreeRAM, 2)
$RAMPercent = [math]::Round(($UsedRAM / $TotalRAM) * 100, 1)

# Disk Usage
$Disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $Free = [math]::Round($_.FreeSpace / 1GB, 2)
    $Total = [math]::Round($_.Size / 1GB, 2)
    $Used = [math]::Round($Total - $Free, 2)
    $Percent = [math]::Round(($Used / $Total) * 100, 1)
    [PSCustomObject]@{
        Drive   = $_.DeviceID
        Total   = $Total
        Used    = $Used
        Free    = $Free
        Percent = $Percent
    }
}

# Top 5 Processes by CPU
$TopProcesses = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU, WorkingSet

# Critical Services Check
$Services = @("wuauserv", "Spooler", "windefend", "BITS")
$ServiceStatus = $Services | ForEach-Object {
    $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Name   = $svc.DisplayName
        Status = $svc.Status
    }
}

# --- Color Logic ---
function Get-Color($value, $warn, $danger) {
    if ($value -ge $danger) { return "red" }
    elseif ($value -ge $warn) { return "orange" }
    else { return "green" }
}

$CPUColor = Get-Color $CPU 70 90
$RAMColor = Get-Color $RAMPercent 70 90

# --- Generate HTML Report ---
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ReportPath = "$PSScriptRoot\HealthReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

$DiskRows = ""
foreach ($d in $Disks) {
    $color = Get-Color $d.Percent 70 90
    $DiskRows += "<tr><td>$($d.Drive)</td><td>$($d.Total) GB</td><td>$($d.Used) GB</td><td>$($d.Free) GB</td><td style='color:$color;font-weight:bold'>$($d.Percent)%</td></tr>"
}

$ProcessRows = ""
foreach ($p in $TopProcesses) {
    $mem = [math]::Round($p.WorkingSet / 1MB, 2)
    $ProcessRows += "<tr><td>$($p.Name)</td><td>$([math]::Round($p.CPU,2))</td><td>$mem MB</td></tr>"
}

$ServiceRows = ""
foreach ($s in $ServiceStatus) {
    $color = if ($s.Status -eq "Running") { "green" } else { "red" }
    $ServiceRows += "<tr><td>$($s.Name)</td><td style='color:$color;font-weight:bold'>$($s.Status)</td></tr>"
}

$HTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px; }
        h1 { color: #333; }
        h2 { color: #555; border-bottom: 1px solid #ccc; padding-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 30px; background: white; }
        th { background: #333; color: white; padding: 10px; text-align: left; }
        td { padding: 8px 10px; border-bottom: 1px solid #ddd; }
        .metric { font-size: 2em; font-weight: bold; }
        .card { background: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; display: inline-block; width: 200px; text-align: center; margin-right: 20px; }
    </style>
</head>
<body>
    <h1>🖥️ System Health Report</h1>
    <p>Generated: $Date</p>
    <p>Computer: $env:COMPUTERNAME | User: $env:USERNAME</p>

    <h2>CPU & RAM</h2>
    <div class="card">
        <div>CPU Usage</div>
        <div class="metric" style="color:$CPUColor">$CPU%</div>
    </div>
    <div class="card">
        <div>RAM Usage</div>
        <div class="metric" style="color:$RAMColor">$RAMPercent%</div>
        <div>$UsedRAM GB / $TotalRAM GB</div>
    </div>

    <h2>Disk Usage</h2>
    <table>
        <tr><th>Drive</th><th>Total</th><th>Used</th><th>Free</th><th>Usage %</th></tr>
        $DiskRows
    </table>

    <h2>Top 5 Processes (by CPU)</h2>
    <table>
        <tr><th>Process</th><th>CPU (s)</th><th>Memory</th></tr>
        $ProcessRows
    </table>

    <h2>Critical Services</h2>
    <table>
        <tr><th>Service</th><th>Status</th></tr>
        $ServiceRows
    </table>
</body>
</html>
"@

$HTML | Out-File -FilePath $ReportPath -Encoding UTF8
Write-Host "Report generated: $ReportPath" -ForegroundColor Green
Start-Process $ReportPath