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

### Option 1: Local Execution (Recommended for dev)

```powershell
# Install dependencies and run UI (requires Node/npm)
npm install
npm start
```

### Option 2: PowerShell integration

The UI can call a PowerShell backend for scanning and installing. This prototype does not perform installs by default.

## Requirements

- Windows 10 or later
- Node.js (for the Electron UI)
- Administrator privileges for scanning/installation

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

## Notes

- The database is stored in `%APPDATA%\DriverManager\drivers-db.json`
- Admin privileges are required for system scanning
- Opening driver links in browser is the default behavior (direct downloads coming soon)
- Works with Windows WMI for accurate hardware detection

## Contributing

To add new drivers to the database, edit `drivers-db.json` with proper regex patterns for device matching.

## License

MIT License - Feel free to modify and distribute
