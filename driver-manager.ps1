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
    Background = [System.Drawing.Color]::FromArgb(12, 12, 12)
    PanelBg = [System.Drawing.Color]::FromArgb(24, 24, 24)
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
    
    $button.Add_MouseEnter({
        $button.BackColor = $Colors.AccentHover
    })
    $button.Add_MouseLeave({
        $button.BackColor = $BGColor
    })
    
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
$main.Size = New-Object System.Drawing.Size(1200, 700)
$main.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$main.BackColor = $Colors.Background
$main.ForeColor = $Colors.TextPrimary
$main.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$main.MaximizeBox = $false

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

$leftLabel = New-Object System.Windows.Forms.Label
$leftLabel.Text = 'Selected Drivers'
$leftLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$leftLabel.ForeColor = $Colors.TextPrimary
$leftLabel.Location = New-Object System.Drawing.Point(10, 10)
$leftLabel.Size = New-Object System.Drawing.Size(280, 25)

$lbSelected = New-CustomListBox -X 10 -Y 45 -Width 280 -Height 530

$btnRemoveSelected = New-CustomButton -Text 'Remove' -X 10 -Y 585 -Width 130 -Height 35 -BGColor $Colors.Danger
$btnClearSelected = New-CustomButton -Text 'Clear All' -X 150 -Y 585 -Width 140 -Height 35 -BGColor $Colors.Danger

$leftPanel.Controls.Add($leftLabel)
$leftPanel.Controls.Add($lbSelected)
$leftPanel.Controls.Add($btnRemoveSelected)
$leftPanel.Controls.Add($btnClearSelected)

# Middle Panel - Database
$middlePanel = New-Object System.Windows.Forms.Panel
$middlePanel.Location = New-Object System.Drawing.Point(300, 0)
$middlePanel.Size = New-Object System.Drawing.Size(450, 700)
$middlePanel.BackColor = $Colors.PanelBg
$middlePanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$middleLabel = New-Object System.Windows.Forms.Label
$middleLabel.Text = 'Driver Database'
$middleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$middleLabel.ForeColor = $Colors.TextPrimary
$middleLabel.Location = New-Object System.Drawing.Point(10, 10)
$middleLabel.Size = New-Object System.Drawing.Size(430, 25)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(10, 45)
$txtSearch.Size = New-Object System.Drawing.Size(430, 30)
$txtSearch.BackColor = $Colors.Background
$txtSearch.ForeColor = $Colors.TextPrimary
$txtSearch.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$txtSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtSearch.Text = 'Search drivers...'
$txtSearch.ForeColor = $Colors.TextSecondary

$lbDatabase = New-CustomListBox -X 10 -Y 85 -Width 430 -Height 530

$btnRefreshDB = New-CustomButton -Text 'Refresh' -X 10 -Y 625 -Width 430 -Height 35

$middlePanel.Controls.Add($middleLabel)
$middlePanel.Controls.Add($txtSearch)
$middlePanel.Controls.Add($lbDatabase)
$middlePanel.Controls.Add($btnRefreshDB)

# Right Panel - Detected Devices
$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Location = New-Object System.Drawing.Point(750, 0)
$rightPanel.Size = New-Object System.Drawing.Size(450, 700)
$rightPanel.BackColor = $Colors.PanelBg
$rightPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$rightLabel = New-Object System.Windows.Forms.Label
$rightLabel.Text = 'Detected Devices'
$rightLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$rightLabel.ForeColor = $Colors.TextPrimary
$rightLabel.Location = New-Object System.Drawing.Point(10, 10)
$rightLabel.Size = New-Object System.Drawing.Size(430, 25)

$lbDevices = New-CustomListBox -X 10 -Y 45 -Width 430 -Height 535

$btnDownload = New-CustomButton -Text 'Download & Install' -X 10 -Y 590 -Width 210 -Height 40 -BGColor $Colors.Success
$btnDownload.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)

$btnBack = New-CustomButton -Text 'Back' -X 230 -Y 590 -Width 210 -Height 40 -BGColor $Colors.Danger

$rightPanel.Controls.Add($rightLabel)
$rightPanel.Controls.Add($lbDevices)
$rightPanel.Controls.Add($btnDownload)
$rightPanel.Controls.Add($btnBack)

$contentPanel.Controls.Add($leftPanel)
$contentPanel.Controls.Add($middlePanel)
$contentPanel.Controls.Add($rightPanel)

# ============================================================================
# UI Refresh Functions
# ============================================================================
function Refresh-Lists {
    $lbDatabase.Items.Clear()
    $AppData.Database | ForEach-Object {
        $lbDatabase.Items.Add($_.name) | Out-Null
    }
    
    $lbSelected.Items.Clear()
    $AppData.SelectedDrivers | ForEach-Object {
        $lbSelected.Items.Add($_) | Out-Null
    }
    
    $lbDevices.Items.Clear()
    $AppData.DetectedDevices | ForEach-Object {
        $lbDevices.Items.Add("[$($_.Category)] $($_.Name)") | Out-Null
    }
}

# ============================================================================
# Event Handlers
# ============================================================================
$btnScan.Add_Click({
    $AppData.DetectedDevices = Detect-Devices
    Load-Database
    Refresh-Lists
    
    $welcomePanel.Visible = $false
    $contentPanel.Visible = $true
    $main.Controls.Add($contentPanel)
})

$btnExit.Add_Click({
    $main.Close()
})

$btnBack.Add_Click({
    $contentPanel.Visible = $false
    $welcomePanel.Visible = $true
})

$txtSearch.Add_Click({
    if ($txtSearch.Text -eq 'Search drivers...') {
        $txtSearch.Text = ''
        $txtSearch.ForeColor = $Colors.TextPrimary
    }
})

$txtSearch.Add_Leave({
    if ($txtSearch.Text -eq '') {
        $txtSearch.Text = 'Search drivers...'
        $txtSearch.ForeColor = $Colors.TextSecondary
    }
})

$txtSearch.Add_TextChanged({
    if ($txtSearch.Text -ne 'Search drivers...') {
        $lbDatabase.Items.Clear()
        $AppData.Database | Where-Object { $_.name -like "*$($txtSearch.Text)*" } | ForEach-Object {
            $lbDatabase.Items.Add($_.name) | Out-Null
        }
    }
})

$lbDatabase.Add_SelectedIndexChanged({
    if ($lbDatabase.SelectedIndex -ge 0) {
        $selected = $AppData.Database | Where-Object { $_.name -eq $lbDatabase.SelectedItem }
        if ($AppData.SelectedDrivers -notcontains $selected.name) {
            $AppData.SelectedDrivers.Add($selected.name) | Out-Null
            Refresh-Lists
        }
    }
})

$btnRemoveSelected.Add_Click({
    if ($lbSelected.SelectedIndex -ge 0) {
        $AppData.SelectedDrivers.RemoveAt($lbSelected.SelectedIndex)
        Refresh-Lists
    }
})

$btnClearSelected.Add_Click({
    $AppData.SelectedDrivers.Clear()
    Refresh-Lists
})

$btnDownload.Add_Click({
    if ($AppData.SelectedDrivers.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('Please select drivers first!', 'No Drivers Selected', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    foreach ($driverName in $AppData.SelectedDrivers) {
        $driver = $AppData.Database | Where-Object { $_.name -eq $driverName }
        if ($driver) {
            # Check if URL is a PowerShell command
            if ($driver.url -match '^powershell\s+-Command') {
                # Execute PowerShell command
                $cmdString = $driver.url -replace '^powershell\s+-Command\s+"?', '' -replace '"?$', ''
                Invoke-Expression $cmdString
            } else {
                # Open URL in default browser
                Start-Process -FilePath $driver.url
            }
        }
    }
})

$btnRefreshDB.Add_Click({
    Load-Database
    Refresh-Lists
})

# ============================================================================
# Main Form Setup
# ============================================================================
$main.Controls.Add($welcomePanel)

$main.ShowDialog()