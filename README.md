# Driver Manager Pro

🚀 **One-Line Installation:**
```powershell
iex (irm 'https://raw.githubusercontent.com/pluizigegamer/drivers/main/driver-manager.ps1')
```

## About

A modern, professional driver detection and management system for Windows with an elegant dark-themed UI.

**Features:**
- 🎨 Professional dark theme UI
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

### User Application

**From PowerShell (as Administrator):**
```powershell
iex (irm 'https://raw.githubusercontent.com/pluizigegamer/drivers/main/driver-manager.ps1')
```

**Or download and run locally:**
```powershell
C:\path\to\driver-manager.ps1
```

### Admin Panel (Password Protected)

**Access the admin panel to manage drivers:**
```powershell
# Run as Administrator
iex (irm 'https://raw.githubusercontent.com/pluizigegamer/drivers/main/admin-panel.ps1')
```

**Admin Features:**
- ✏️ Add new drivers
- 🔧 Edit existing drivers
- 🗑️ Delete drivers
- 🔗 Test download URLs
- 🔒 Password protected access

## How It Works

### User Mode
1. **Welcome Screen** → Click "Scan System"
2. **Hardware Detection** → Finds GPUs, network adapters, audio devices
3. **Main Interface** → Three panels:
   - Left: Selected drivers
   - Middle: Driver database with search
   - Right: Detected devices
4. **Download** → Select drivers and install

### Admin Mode
1. **Login** → Enter admin password
2. **Manage Database** → Add/Edit/Delete drivers
3. **Test URLs** → Verify download links work
4. **Save Changes** → Updates stored automatically

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

**Pre-loaded drivers:**
- NVIDIA GeForce
- AMD Radeon
- Intel Graphics
- Realtek Audio
- Intel Ethernet
- Realtek Ethernet

## Customization

Use the admin panel to:
- Add custom drivers
- Edit driver information
- Update download links
- Change detection patterns
- Organize by category

## Storage

The database is stored at: `%APPDATA%\DriverManager\drivers-db.json`

## Security

- Admin panel uses SHA256 password hashing
- Password verification is secure
- Configuration stored in hidden directory
- No plaintext passwords in files

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
- Update patterns in admin panel for your specific model

**Admin login fails?**
- Ensure password is correct
- Check for caps lock
- Verify no extra spaces

## Technical Stack

- **Language**: PowerShell 5.0+
- **UI**: Windows Forms
- **Database**: JSON
- **Detection**: WMI (Windows Management Instrumentation)
- **Security**: SHA256 password hashing

## Files

- `driver-manager.ps1` - Main user application
- `admin-panel.ps1` - Password-protected admin interface
- `drivers-db.json` - Driver database
- `README.md` - This file

## Documentation

- **README.md** - Overview and quick start
- **ADMIN-GUIDE.md** - Admin panel documentation

## License

MIT License - Free to use and modify

---

**Ready to use!** Just copy and paste the one-liner above in PowerShell (as Administrator).