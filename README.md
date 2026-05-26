# Driver Manager Pro

A modern, professional driver detection and management system for Windows with a dark-themed UI.

## Features

- **Hardware Detection**: Automatically scans your system for GPUs, network adapters, audio devices, and more
- **Modern UI**: Dark theme with intuitive three-panel layout
- **Database Management**: Manage a centralized driver database in JSON format
- **Smart Recommendations**: Recommends matching drivers based on detected hardware
- **Search & Filter**: Quickly find drivers by name or pattern
- **Direct Downloads**: One-click access to official driver download pages

## Installation & Usage

### Option 1: Direct Execution (Recommended)

```powershell
# Run directly from PowerShell (requires administrator)
iex (irm 'https://raw.githubusercontent.com/pluizigegamer/drivers/main/driver-manager.ps1')
```

### Option 2: Local Execution

```powershell
# Download and run locally
$content = Get-Content 'C:\path\to\driver-manager.ps1' -Raw
$content | iex
```

Or simply run the `.ps1` file directly:
```powershell
C:\Users\YourUser\Downloads\driver-manager.ps1
```

## Requirements

- Windows 10 or later
- PowerShell 5.0 or later
- Administrator privileges
- .NET Framework 4.5+

## How It Works

1. **Welcome Screen**: Click "Scan System" to begin
2. **Hardware Detection**: The app scans your PC for drivers (GPUs, network, audio)
3. **Main Interface**:
   - **Left Panel**: Shows selected drivers ready for download
   - **Middle Panel**: Browse the driver database, search and add drivers
   - **Right Panel**: Shows detected devices with matching recommendations
4. **Download**: Select drivers and click "Download & Install"

## Database Format

The `drivers-db.json` file contains driver entries:

```json
{
  "id": "1",
  "name": "NVIDIA GeForce Driver",
  "pattern": "NVIDIA|GeForce|RTX",
  "url": "https://www.nvidia.com/Download/driverDetails.aspx/",
  "category": "GPU"
}
```

- **id**: Unique identifier
- **name**: Display name in the UI
- **pattern**: Regex pattern to match against detected device names
- **url**: Link to driver download page
- **category**: Driver category (GPU, Audio, Network, etc.)

## Color Scheme

- **Background**: Dark (#0c0c0c)
- **Panels**: Dark Gray (#181818)
- **Text**: Light Gray (#e6e6e6)
- **Accent**: Blue (#0078d7)
- **Success**: Green (#4caf50)
- **Danger**: Red (#f44336)

## Notes

- The database is stored in `%APPDATA%\DriverManager\drivers-db.json`
- Admin privileges are required for system scanning
- Opening driver links in browser is the default behavior (direct downloads coming soon)
- Works with Windows WMI for accurate hardware detection

## Contributing

To add new drivers to the database, edit `drivers-db.json` with proper regex patterns for device matching.

## License

MIT License - Feel free to modify and distribute