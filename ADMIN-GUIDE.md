# Driver Manager Pro - Admin Panel

## 🔐 Secure Admin Control

The admin panel provides secure management of the driver database with password protection.

### Launch Admin Panel

```powershell
# Run as Administrator
iex (irm 'https://raw.githubusercontent.com/pluizigegamer/drivers/main/admin-panel.ps1')
```

### Login

- **Password**: Hidden in secure hash verification
- **Security**: SHA256 password hash
- **Access**: Admin-only features after authentication

## Features

### 📋 Driver Management

**Left Panel** - Driver List:
- View all drivers in the database
- Click to select and edit
- Real-time list updates

**Right Panel** - Edit Driver:
- **Name**: Driver display name
- **Pattern**: Regex pattern for hardware detection
- **URL**: Download link (tested for validity)
- **Category**: GPU, Audio, Network, Chipset, Other

### ✏️ Operations

#### Add Driver
1. Click "Add New" button
2. Fill in all fields
3. Click "Save" to add to database

#### Edit Driver
1. Click driver name in the list
2. Modify fields on the right
3. Click "Save" to apply changes

#### Delete Driver
1. Select driver from list
2. Click "Delete" button
3. Confirm deletion

#### Test URL
- Click "Test URL" to verify download link works
- Shows HTTP status code if valid
- Warns if URL is unreachable

#### Refresh
- Click "Refresh" to reload database from file
- Useful after external changes

### 🔒 Security

- **Password Protected**: All changes require admin login
- **Hashed Verification**: Password stored as SHA256 hash
- **Secure Storage**: Sensitive data in hidden config directory
- **Session Management**: Logout to return to login screen

## Data Storage

- **Database**: `%APPDATA%\DriverManager\drivers-db.json`
- **Config**: `%APPDATA%\.drvmgr\config.dat`

## Regex Patterns

Pattern field uses regex to match hardware names:

```
NVIDIA|GeForce|RTX|GTX         # Matches NVIDIA, GeForce, RTX, GTX
AMD|Radeon                      # Matches AMD or Radeon
Intel.*Graphics                 # Matches Intel followed by Graphics
Realtek.*Ethernet              # Matches Realtek followed by Ethernet
```

## Categories

- **GPU**: Graphics cards
- **Audio**: Sound devices
- **Network**: Ethernet/WiFi adapters
- **Chipset**: Motherboard chipsets
- **Other**: Miscellaneous

## Example Workflow

1. Launch admin panel
2. Enter password
3. Click "Add New"
4. Fill in driver info:
   - Name: "My Custom GPU Driver"
   - Pattern: "MyGPU|CustomChip"
   - URL: "https://mydomain.com/driver.exe"
   - Category: "GPU"
5. Click "Test URL" to verify
6. Click "Save"
7. Driver is now available in main app

## Tips

- Use specific patterns for better matching
- Test URLs before saving
- Backup `drivers-db.json` before major changes
- Use "Refresh" if database changes externally

## Troubleshooting

**"Invalid password"?**
- Ensure caps lock is off
- Password is case-sensitive
- Check for extra spaces

**Changes not saving?**
- Ensure %APPDATA%\DriverManager\ directory exists
- Verify write permissions to directory
- Check disk space availability

**URL test fails?**
- Check internet connection
- Verify URL is correct
- URL must be directly accessible

---

**Admin Panel** - Professional driver database management