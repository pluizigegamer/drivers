# Driver Manager Pro - UI Guide

## Welcome Screen
```
╔════════════════════════════════════════════════╗
║                                                ║
║          🔷 Driver Manager Pro 🔷             ║
║                                                ║
║   Scan your system for drivers and manage     ║
║   them from a centralized database            ║
║                                                ║
║        ┌─────────────────────────────┐        ║
║        │   📊 Scan System            │        ║
║        └─────────────────────────────┘        ║
║                                                ║
║        ┌─────────────────────────────┐        ║
║        │   Exit                      │        ║
║        └─────────────────────────────┘        ║
║                                                ║
╚════════════════════════════════════════════════╝
```

## Main Interface (After Scan)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                               │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐   │
│  │ Selected Drivers │  │ Driver Database  │  │ Detected Devices         │   │
│  ├──────────────────┤  ├──────────────────┤  ├──────────────────────────┤   │
│  │                  │  │ 🔍 Search...     │  │                          │   │
│  │                  │  │                  │  │ [GPU] NVIDIA GeForce     │   │
│  │ NVIDIA Driver    │  │ • NVIDIA Driver  │  │ [GPU] Intel Graphics     │   │
│  │ Intel Driver     │  │ • AMD Driver     │  │ [Network] Realtek Eth    │   │
│  │                  │  │ • Intel Driver   │  │ [Audio] Realtek Audio    │   │
│  │                  │  │ • Audio Driver   │  │                          │   │
│  │                  │  │ • Network Driver │  │                          │   │
│  │                  │  │                  │  │                          │   │
│  ├──────────────────┤  ├──────────────────┤  ├──────────────────────────┤   │
│  │ ⚠️ Remove        │  │ ✏️ Add           │  │ ✅ Download & Install    │   │
│  │ 🗑️  Clear All   │  │ ✏️ Edit          │  │ ⬅️ Back                  │   │
│  │                  │  │ 🗑️ Delete        │  │                          │   │
│  │                  │  │ 🔄 Refresh       │  │                          │   │
│  └──────────────────┘  └──────────────────┘  └──────────────────────────┘   │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Color Scheme

### Backgrounds
```
┌─ Main Window ──────────────────────────┐
│ Background: #0c0c0c (Deep Black)       │
│ Panel BG: #181818 (Dark Gray)          │
│ Border: #2d2d2d (Subtle Gray)          │
└────────────────────────────────────────┘
```

### Text
```
┌─ Typography ──────────────────────────┐
│ Primary: #e6e6e6 (Light Gray)         │
│ Secondary: #969696 (Medium Gray)      │
│ Font: Segoe UI                        │
└───────────────────────────────────────┘
```

### Actions
```
┌─ Button Colors ───────────────────────┐
│ Default: #0078d7 (Accent Blue)        │
│ Hover: #0096ff (Brighter Blue)        │
│ Success: #4caf50 (Green)              │
│ Danger: #f44336 (Red)                 │
└───────────────────────────────────────┘
```

## Interaction Flow

```
START
  │
  ├─→ Welcome Screen
  │     │
  │     └─→ [Scan System Button]
  │           │
  │           └─→ Hardware Detection (WMI)
  │                 │
  │                 ├─→ GPUs (NVIDIA, AMD, Intel)
  │                 ├─→ Network Adapters
  │                 └─→ Audio Devices
  │
  └─→ Main Interface Shows 3 Panels
      │
      ├─ Right Panel (Detected)
      │   └─→ Shows what was found on your PC
      │
      ├─ Middle Panel (Database)
      │   ├─→ Search functionality
      │   └─→ Click to add drivers
      │
      └─ Left Panel (Selected)
          └─→ Drivers queued for download
              │
              └─→ [Download & Install]
                  └─→ Opens driver pages
```

## Database Entry Example

```json
{
  "id": "1",
  "name": "NVIDIA GeForce Driver",
  "pattern": "NVIDIA|GeForce|RTX|GTX",
  "url": "https://www.nvidia.com/Download/driverDetails.aspx/",
  "category": "GPU"
}
```

### Fields Explained
- **id**: Unique identifier (string or number)
- **name**: What shows in the UI
- **pattern**: Regex to match hardware names (pipe = OR)
- **url**: Where to download the driver
- **category**: GPU, Audio, Network, etc.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Alt+S | Focus on search box |
| Tab | Navigate between panels |
| Enter | Select/Activate |
| Delete | Remove from selected |
| Esc | Cancel/Go back |

## Responsive Design

The UI automatically adjusts to your screen resolution:
- Minimum: 1000x600px (recommended)
- Tested: 1200x700px (default)
- Scales: Works on ultrawide monitors too

## Dark Mode (Always On)

The application is designed exclusively for dark theme to:
- Reduce eye strain during long usage
- Look modern and professional
- Improve visibility of important elements
- Match modern Windows 11 design language

## Tips & Tricks

1. **Search is Live**: Type in search box to filter database in real-time
2. **Multi-Select**: You can add multiple drivers before downloading
3. **Persistent DB**: Database saves automatically to `%APPDATA%\DriverManager\`
4. **Custom DB**: Edit `drivers-db.json` to add your own drivers
5. **Pattern Matching**: Use regex in patterns for advanced matching
6. **Recommend**: Right panel shows devices that match database entries