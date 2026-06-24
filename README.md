# 🖥️ System Health Monitor

A PowerShell script that monitors Windows system health and generates a color-coded HTML report.

## 📋 Features

- CPU usage monitoring
- RAM usage (used / total / percentage)
- Disk space monitoring per drive
- Top 5 CPU-consuming processes
- Critical Windows services status check
- Auto-generates HTML report with color coding (Green / Orange / Red)

## 🚀 How to Use

1. Clone or download this repository
2. Right-click `HealthMonitor.ps1` → Run with PowerShell
3. HTML report will auto-open in your browser

## ⚙️ Requirements

- Windows OS
- PowerShell 5.0 or above
- Execution Policy set to RemoteSigned

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🎯 Use Case

Built for IT Support and Desktop Engineering environments to quickly assess system health without third-party tools.

## 👤 Author

Bazil Zaman — IT Support | Desktop Engineer
