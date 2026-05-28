# ============================================================================
# Driver Manager Pro - Modern Dark Theme UI
# A professional driver detection and management application
# ============================================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================================
# Color Scheme - Modern Dark Theme
# ============================================================================
$Colors = @{
    Background = [System.Drawing.Color]::Black
    PanelBg = [System.Drawing.Color]::FromArgb(20, 20, 20)
    TextPrimary = [System.Drawing.Color]::FromArgb(230, 230, 230)
    TextSecondary = [System.Drawing.Color]::FromArgb(150, 150, 150)
    Accent = [System.Drawing.Color]::FromArgb(0, 120, 215)
    AccentHover = [System.Drawing.Color]::FromArgb(0, 150, 255)
    Border = [System.Drawing.Color]::FromArgb(45, 45, 45)
    Success = [System.Drawing.Color]::FromArgb(76, 175, 80)
    Danger = [System.Drawing.Color]::FromArgb(244, 67, 54)
}

# ============================================================================
# Data Storage
# ============================================================================
$AppData = @{
    SelectedDrivers = [System.Collections.ArrayList]@()
    DetectedDevices = @()
    Database = @()
    DBPath = "$env:APPDATA\DriverManager\drivers-db.json"
}

# Ensure database directory exists
$DBDir = Split-Path -Path $AppData.DBPath
if (-not (Test-Path $DBDir)) { New-Item -ItemType Directory -Path $DBDir -Force | Out-Null }

# ============================================================================
# Hardware Detection Functions
# ============================================================================
function Detect-Devices {
    $devices = [System.Collections.ArrayList]@()
    
    # GPUs
    Get-WmiObject Win32_VideoController | ForEach-Object {
        $name = $_.Name
        if ($name -match 'NVIDIA|GeForce|RTX|GTX') {
            $devices.Add([PSCustomObject]@{
                Type = 'GPU'
                Name = $name
                Category = 'NVIDIA'
                ID = $_.PNPDeviceID
            }) | Out-Null
        } elseif ($name -match 'AMD|Radeon') {
            $devices.Add([PSCustomObject]@{
                Type = 'GPU'
                Name = $name
                Category = 'AMD'
                ID = $_.PNPDeviceID
            }) | Out-Null
        } elseif ($name -match 'Intel') {
            $devices.Add([PSCustomObject]@{
                Type = 'GPU'
                Name = $name
                Category = 'Intel'
                ID = $_.PNPDeviceID
            }) | Out-Null
        }
    }
    
    # Network Adapters
    Get-WmiObject Win32_NetworkAdapter -Filter "PhysicalAdapter=TRUE" | ForEach-Object {
        $devices.Add([PSCustomObject]@{
            Type = 'Network'
            Name = $_.Name
            Category = 'Network'
            ID = $_.PNPDeviceID
        }) | Out-Null
    }
    
    # Audio Devices
    Get-WmiObject Win32_SoundDevice | ForEach-Object {
        $devices.Add([PSCustomObject]@{
            Type = 'Audio'
            Name = $_.Name
            Category = 'Audio'
            ID = $_.PNPDeviceID
        }) | Out-Null
    }
    
    return $devices
}

# ============================================================================
# Database Functions
# ============================================================================
function Load-Database {
    if (Test-Path $AppData.DBPath) {
        try {
            $AppData.Database = Get-Content -Path $AppData.DBPath -Raw | ConvertFrom-Json
        } catch {
            Initialize-Database
        }
    } else {
        Initialize-Database
    }
}

function Initialize-Database {
    $AppData.Database = @(
        @{ id = '1'; name = 'NVIDIA GeForce Driver'; pattern = 'NVIDIA|GeForce'; url = 'https://www.nvidia.com/Download/driverDetails.aspx/'; category = 'GPU' },
        @{ id = '2'; name = 'AMD Radeon Driver'; pattern = 'AMD|Radeon'; url = 'https://www.amd.com/en/support'; category = 'GPU' },
        @{ id = '3'; name = 'Intel Graphics Driver'; pattern = 'Intel'; url = 'https://www.intel.com/content/www/en/en/download/726609'; category = 'GPU' },
        @{ id = '4'; name = 'Generic Network Driver'; pattern = 'Ethernet|Network'; url = 'https://support.microsoft.com'; category = 'Network' },
        @{ id = '5'; name = 'Generic Audio Driver'; pattern = 'Audio|Sound'; url = 'https://support.microsoft.com'; category = 'Audio' }
    )
    Save-Database
}

function Save-Database {
    $AppData.Database | ConvertTo-Json | Set-Content -Path $AppData.DBPath -Force
}

function Recommend-Drivers {
    $recommended = [System.Collections.ArrayList]@()
    
    foreach ($device in $AppData.DetectedDevices) {
        foreach ($driver in $AppData.Database) {
            if ($device.Name -match $driver.pattern) {
                if ($recommended.id -notcontains $driver.id) {
                    $recommended.Add($driver) | Out-Null
                }
                break
            }
        }
    }
    
    return $recommended
}

# ============================================================================
# UI Component Creation
# ============================================================================
function New-CustomButton {
    param(
        [string]$Text,
        [int]$X, [int]$Y,
        [int]$Width = 120, [int]$Height = 36,
        [System.Drawing.Color]$BGColor = $Colors.Accent,
        [System.Drawing.Color]$TextColor = $Colors.TextPrimary
    )
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.BackColor = $BGColor
    $button.ForeColor = $TextColor
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderColor = $Colors.Border
    $button.FlatAppearance.BorderSize = 1
    $button.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Regular)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    # Use sender param in event handlers to avoid property resolution issues
    $button.Add_MouseEnter( { param($s,$e) $s.BackColor = $Colors.AccentHover } )
    $button.Add_MouseLeave( { param($s,$e) $s.BackColor = $BGColor } )
    
    return $button
}

function New-CustomListBox {
    param(
        [int]$X, [int]$Y,
        [int]$Width, [int]$Height
    )
    
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point($X, $Y)
    $listBox.Size = New-Object System.Drawing.Size($Width, $Height)
    $listBox.BackColor = $Colors.PanelBg
    $listBox.ForeColor = $Colors.TextPrimary
    $listBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $listBox.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    
    return $listBox
}

# ============================================================================
# Main Window Creation
# ============================================================================
$main = New-Object System.Windows.Forms.Form
$main.Text = 'Driver Manager Pro'
$main.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$main.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$main.BackColor = $Colors.Background
$main.ForeColor = $Colors.TextPrimary
$main.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$main.AutoScaleMode = 'Dpi'
$main.MaximizeBox = $true

# ============================================================================
# Welcome Screen
# ============================================================================
$welcomePanel = New-Object System.Windows.Forms.Panel
$welcomePanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$welcomePanel.BackColor = $Colors.Background

$welcomeTitle = New-Object System.Windows.Forms.Label
$welcomeTitle.Text = 'Driver Manager Pro'
$welcomeTitle.Font = New-Object System.Drawing.Font('Segoe UI', 28, [System.Drawing.FontStyle]::Bold)
$welcomeTitle.ForeColor = $Colors.Accent
$welcomeTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$welcomeTitle.Location = New-Object System.Drawing.Point(0, 150)
$welcomeTitle.Size = New-Object System.Drawing.Size(1200, 60)

$welcomeDesc = New-Object System.Windows.Forms.Label
$welcomeDesc.Text = 'Scan your system for drivers and manage them from a centralized database'
$welcomeDesc.Font = New-Object System.Drawing.Font('Segoe UI', 12)
$welcomeDesc.ForeColor = $Colors.TextSecondary
$welcomeDesc.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$welcomeDesc.Location = New-Object System.Drawing.Point(0, 220)
$welcomeDesc.Size = New-Object System.Drawing.Size(1200, 40)

$btnScan = New-CustomButton -Text 'Scan System' -X 450 -Y 320 -Width 300 -Height 50
$btnScan.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)

$btnExit = New-CustomButton -Text 'Exit' -X 450 -Y 600 -Width 300 -Height 40 -BGColor $Colors.Danger
$btnExit.Font = New-Object System.Drawing.Font('Segoe UI', 11)

$welcomePanel.Controls.Add($welcomeTitle)
$welcomePanel.Controls.Add($welcomeDesc)
$welcomePanel.Controls.Add($btnScan)
$welcomePanel.Controls.Add($btnExit)

# ============================================================================
# Main Content Panel
# ============================================================================
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$contentPanel.BackColor = $Colors.Background
$contentPanel.Visible = $false

# Left Panel - Selected Drivers
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Location = New-Object System.Drawing.Point(0, 0)
$leftPanel.Size = New-Object System.Drawing.Size(300, 700)
$leftPanel.BackColor = $Colors.PanelBg
$leftPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# (rest of driver-manager.ps1 content continued...)
