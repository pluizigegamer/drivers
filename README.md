# Driver Manager Pro

🚀 **One-Line Installation:**
```powershell
iex (irm 'https://raw.githubusercontent.com/pluizigegamer/drivers/main/driver-manager.ps1')
```

## About

A modern, professional driver detection and management system for Windows with an elegant dark-themed UI.

**Features:**
- 🖥️ Professional dark theme UI
- 🔍 Real hardware detection (GPUs, Network, Audio)
- 📚 Searchable driver database
- ⚡ One-click driver downloads
- 💾 Persistent database storage
- 🎯 Smart driver recommendations

## Quick Start

### Requirements
- Windows 10 or later
- PowerShell 5.0+
- Administrator privileges

### Run It

**From PowerShell (as Administrator):**
```powershell
iex (irm 'https://raw.githubusercontent.com/pluizigegamer/drivers/main/driver-manager.ps1')
```

**Or download and run locally:**
```powershell
C:\path\to\driver-manager.ps1
```

## How It Works

1. **Welcome Screen** → Click "Scan System"
2. **Hardware Detection** → Finds GPUs, network adapters, audio devices
3. **Main Interface** → Three panels:
   - Left: Selected drivers
   - Middle: Driver database with search
   - Right: Detected devices
4. **Download** → Select drivers and install

## UI Design

- **Dark Theme**: Professional #0c0c0c background
- **Modern Colors**: Blues for actions, greens for success, reds for danger
- **Responsive**: Adapts to your screen resolution
- **Smooth**: Hover effects and polished interactions

## Database

The `drivers-db.json` contains entries like:
```json
{
  "id": "1",
  "name": "NVIDIA GeForce Driver",
  "pattern": "NVIDIA|GeForce|RTX|GTX",
  "url": "https://www.nvidia.com/Download/driverDetails.aspx/",
  "category": "GPU"
}
```

**Included drivers:**
- NVIDIA GeForce
- AMD Radeon
- Intel Graphics
- Realtek Audio
- Intel Ethernet
- Realtek Ethernet

## Customization

Edit `drivers-db.json` to add your own drivers. The `pattern` field uses regex to match hardware names.

## Storage

The database is stored at: `%APPDATA%\DriverManager\drivers-db.json`

## Troubleshooting

**Script won't run?**
```powershell
# Set execution policy temporarily
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

**Drivers not showing?**
- Click "Refresh" in the database panel
- Ensure `drivers-db.json` is valid JSON

**GPU not detected?**
- Update patterns in `drivers-db.json` for your specific model

## Technical Stack

- **Language**: PowerShell 5.0+
- **UI**: Windows Forms
- **Database**: JSON
- **Detection**: WMI (Windows Management Instrumentation)

## License

MIT License - Free to use and modify

---

**Ready to use!** Just copy and paste the one-liner above in PowerShell (as Administrator).