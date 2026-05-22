# 🖥️ Universal Driver Installer

Automatically detect and install drivers for NVIDIA, AMD, and Intel GPUs plus all motherboard devices (network, audio, storage, USB, chipset).

## 🚀 Quick Start

**Open PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/pluizigegamer/drivers/main/install-drivers-inline.ps1 | iex
```

That's it! The script will:
1. ✅ Detect your GPU (NVIDIA, AMD, or Intel)
2. ✅ Find all motherboard devices
3. ✅ Display download links for drivers
4. ✅ Create a detailed log file

## ✨ Features

- 🎮 **GPU Detection:** NVIDIA, AMD, Intel (Arc)
- 🖧 **Network Adapters:** All network devices
- 🔊 **Audio:** Sound cards and controllers
- 💾 **Storage:** SATA, NVMe, IDE controllers
- 🔌 **USB:** USB hubs and controllers
- 🖲️ **Motherboard:** Chipset and platform info
- 📋 **Logging:** Detailed audit trail

## 📊 What It Shows

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

## 📚 Documentation

For detailed guides and examples, see:
- Local usage: Run the script with no parameters
- Silent mode: `-Silent` flag skips the final pause
- Log-only mode: `-LogOnly` shows detection without downloads

## 🔗 Share This Script

The one-liner is easy to share:
```
irm https://raw.githubusercontent.com/pluizigegamer/drivers/main/install-drivers-inline.ps1 | iex
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
A: `C:\Users\YourName\AppData\Local\Temp\driver-install-YYYYMMDD-HHMMSS.log`

## 🛠️ Troubleshooting

**"Admin required" error**
→ Right-click PowerShell, select "Run as Administrator"

**"Scripts disabled" error**
→ Run in PowerShell: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`

**No devices detected**
→ Check Device Manager, restart PC, or run Windows Update

**One-liner not working**
→ Ensure you're using PowerShell (not Command Prompt) as Administrator

## 📝 License

Open Source - Use freely!

---

**Created:** May 2024
**Status:** Production Ready
**Author:** pluizigegamer

Got questions? Open an issue on GitHub!
