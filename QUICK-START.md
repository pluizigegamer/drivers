# Quick Start Guide

## One-Line Installation (From PowerShell as Administrator)

```powershell
iex (irm 'https://raw.githubusercontent.com/pluizigegamer/drivers/main/driver-manager.ps1')
```

## Or Download and Run Locally

1. Save `driver-manager.ps1` to your desired location
2. Open PowerShell as Administrator
3. Run: `C:\path\to\driver-manager.ps1`

## What It Does

1. **Welcome Screen**: Shows "Scan System" button - click to start
2. **Hardware Detection**: Scans for GPUs (NVIDIA, AMD, Intel), Network adapters, Audio devices
3. **Three-Panel Interface**:
   - **Left**: Selected drivers (ready to download)
   - **Middle**: Driver database with search functionality
   - **Right**: Detected devices on your system
4. **Download**: Select drivers and click "Download & Install" to open their official pages

## System Requirements

- Windows 10 or later
- PowerShell 5.0+ (usually pre-installed)
- Administrator privileges
- Internet connection for driver links

## Features

✓ Dark professional UI with modern styling  
✓ Real-time hardware detection via WMI  
✓ Searchable driver database  
✓ Multi-select drivers for batch operations  
✓ JSON-based database for easy customization  
✓ Persistent database storage in `%APPDATA%\DriverManager\`  

## Need admin?

If you get a prompt asking for admin, approve it. The script needs admin to scan hardware.

## Troubleshooting

**Script won't run?**
- Make sure PowerShell is running as Administrator
- Check: `Get-ExecutionPolicy` - may need to set to `RemoteSigned` or `Bypass`

**Set execution policy temporarily:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

**Drivers not showing up?**
- Click "Refresh" in the database panel
- Make sure `drivers-db.json` is properly formatted

**Can't detect GPU?**
- Your GPU may need to be updated in the patterns
- Edit `drivers-db.json` to add your specific GPU model