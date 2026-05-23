# 🖥️ Universal Driver Installer

Automatically detect and install drivers for NVIDIA, AMD, and Intel GPUs plus all motherboard devices (network, audio, storage, USB, chipset).

## 🚀 Quick Start

**Open PowerShell as Administrator** and run one of these:

### 🎨 Graphical Interface (NEW!)
```powershell
irm https://raw.githubusercontent.com/pluizigegamer/drivers/main/driver-gui.ps1 | iex
```
**Features:** Visual hardware list, clickable driver buttons, copy URL to clipboard

### 📋 Console Mode
```powershell
irm https://raw.githubusercontent.com/pluizigegamer/drivers/main/detect-drivers.ps1 | iex
```
**Features:** Text-based hardware detection with detailed logging

## ✨ Features

- 🎮 **GPU Detection:** NVIDIA, AMD, Intel (Arc)
- 🖧 **Network Adapters:** All network devices
- 🔊 **Audio:** Sound cards and controllers
- 💾 **Storage:** SATA, NVMe, IDE controllers
- 🔌 **USB:** USB hubs and controllers
- 🖲️ **Motherboard:** Chipset and platform info
- 📋 **Logging:** Detailed audit trail
- 🎨 **GUI & Console:** Two deployment options

## 📊 What It Shows

### GUI Version
- **Left pane:** All detected hardware organized by type
- **Right pane:** Available driver download links
- **Buttons:** Download (opens browser) and Copy URL (to clipboard)
- **Log box:** Action history with timestamps

### Console Version
```
========== DETECTED HARDWARE ==========
GPUs detected: 1
  - NVIDIA: GeForce RTX 3080

System devices detected: 12
  - Motherboard: ASUS ROG STRIX Z790
  - Network Adapters: Realtek GbE Controller
  - Audio: Realtek High Definition Audio
  ... and 9 more devices

========== NEXT STEPS ==========
1. Download the drivers from the URLs shown
2. Run the installer executables
3. Restart your computer
4. Log file: C:\Users\...\AppData\Local\Temp\driver-install-*.log
```

## 📋 System Requirements

- Windows 10 or later
- Windows 11 (fully supported)
- PowerShell 5.0+ (included with Windows 10+)
- Administrator privileges
- Internet connection

## 🔐 Safety & Security

✅ **Open Source** - Review the code on GitHub
✅ **No Telemetry** - Doesn't collect or send any data
✅ **No Installation** - Only provides download links
✅ **Local Execution** - Runs entirely on your PC
✅ **Safe Links** - Only official manufacturer URLs

## 📚 File Descriptions

| File | Purpose | Best For |
|------|---------|----------|
| `driver-gui.ps1` | Graphical interface | Visual users, easy clicking |
| `driver-gui-readable.ps1` | GUI version (readable) | Code review, customization |
| `detect-drivers.ps1` | Console mode | Automation, scripting |
| `install-drivers.ps1` | Full version (readable) | Learning, reference |

## 🔗 Share This Script

The one-liners are easy to share:

**GUI version:**
```
irm https://raw.githubusercontent.com/pluizigegamer/drivers/main/driver-gui.ps1 | iex
```

**Console version:**
```
irm https://raw.githubusercontent.com/pluizigegamer/drivers/main/detect-drivers.ps1 | iex
```

Perfect for Discord, Reddit, forums, or messaging apps!

## ⚠️ Important Notes

- **Run as Administrator:** Right-click PowerShell → "Run as Administrator"
- **Execution Policy:** You may need to allow script execution (the one-liner handles this)
- **Manual Installation:** Downloads provide links; you install drivers manually
- **Restart Required:** Restart PC after installing drivers for full effect

## 📥 Manual Installation Steps

1. Run the script (see Quick Start above)
2. Visit the driver download links provided
3. Download drivers from manufacturers:
   - **NVIDIA:** https://www.nvidia.com/Download/index.aspx
   - **AMD:** https://www.amd.com/en/technologies/radeon-software
   - **Intel Arc:** https://www.intel.com/content/www/us/en/download/785597/
   - **Chipsets:** Check motherboard manufacturer (Intel/AMD)
4. Run installer executables
5. Restart your computer

## ❓ FAQ

**Q: Is this safe?**
A: Yes! It's open-source and only detects hardware + provides official manufacturer links.

**Q: Does it install drivers automatically?**
A: No, it detects hardware and provides download links. You download and install manually.

**Q: Works on Windows 11?**
A: Yes, Windows 10, 11, and Server editions all supported.

**Q: Where are logs saved?**
A: Console version saves to `C:\Users\YourName\AppData\Local\Temp\driver-install-YYYYMMDD-HHMMSS.log`

**Q: Can I use the GUI version remotely?**
A: The GUI needs a local system with display. For remote use, stick with the console version.

## 🛠️ Troubleshooting

**"Admin required" error**
→ Right-click PowerShell, select "Run as Administrator"

**"Scripts disabled" error**
→ Run in PowerShell: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`

**No devices detected**
→ Check Device Manager, restart PC, or run Windows Update

**One-liner not working**
→ Ensure you're using PowerShell (not Command Prompt) as Administrator

**GUI won't open**
→ Try the console version instead; some restricted environments block GUI

## 📝 License

Open Source - Use freely!

---

**Created:** May 2024
**Status:** Production Ready ✅
**Latest:** Added GUI with Windows Forms interface
**Author:** pluizigegamer

Got questions? Open an issue on GitHub!
