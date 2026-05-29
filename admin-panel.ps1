# ============================================================================
# Driver Manager Pro - Admin Panel (Password Protected)
# Secure driver database management interface
# ============================================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================================
# Password & Security
# ============================================================================
$ConfigPath = "$env:APPDATA\.drvmgr\config.dat"
$ConfigDir = Split-Path -Path $ConfigPath

if (-not (Test-Path $ConfigDir)) { 
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null 
}

# Hash the password and store it
function Get-PasswordHash {
    param([string]$Password)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Password)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return [Convert]::ToBase64String($hash)
}

function Verify-AdminPassword {
    param([string]$InputPassword)
    $correctHash = "YAosVJOCA6dgm5kFVJtwnLMRj3uKbNF3/p7++tX/DB4=" # pluisje hashed
    $inputHash = Get-PasswordHash $InputPassword
    return $inputHash -eq $correctHash
}

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
    Warning = [System.Drawing.Color]::FromArgb(255, 193, 7)
}

# ============================================================================
# Data Storage
# ============================================================================
$AppData = @{
    Database = @()
    DBPath = "$env:APPDATA\DriverManager\drivers-db.json"
    SelectedDriver = $null
}

# ============================================================================
# Database Functions
# ============================================================================
function Load-Database {
    if (Test-Path $AppData.DBPath) {
        try {
            $AppData.Database = Get-Content -Path $AppData.DBPath -Raw | ConvertFrom-Json
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error loading database: $_", "Database Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}

function Save-Database {
    try {
        $DBDir = Split-Path -Path $AppData.DBPath
        if (-not (Test-Path $DBDir)) { New-Item -ItemType Directory -Path $DBDir -Force | Out-Null }
        $AppData.Database | ConvertTo-Json | Set-Content -Path $AppData.DBPath -Force
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error saving database: $_", "Save Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
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
    
    $button.Add_MouseEnter({ param($s,$e) if ($s -and $s.PSObject.Properties['BackColor']) { $s.BackColor = $Colors.AccentHover } })
    $button.Add_MouseLeave({ param($s,$e) if ($s -and $s.PSObject.Properties['BackColor']) { $s.BackColor = $BGColor } })
    
    return $button
}

# ============================================================================
# Login Screen
# ============================================================================
$loginForm = New-Object System.Windows.Forms.Form
$loginForm.Text = 'Driver Manager Pro - Admin Login'
$loginForm.Size = New-Object System.Drawing.Size(400, 300)
$loginForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$loginForm.BackColor = $Colors.Background
$loginForm.ForeColor = $Colors.TextPrimary
$loginForm.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$loginForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$loginForm.MaximizeBox = $false
$loginForm.MinimizeBox = $false

$loginTitle = New-Object System.Windows.Forms.Label
$loginTitle.Text = '🔐 Admin Panel Login'
$loginTitle.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$loginTitle.ForeColor = $Colors.Accent
$loginTitle.Location = New-Object System.Drawing.Point(30, 30)
$loginTitle.Size = New-Object System.Drawing.Size(340, 40)
$loginTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

$passLabel = New-Object System.Windows.Forms.Label
$passLabel.Text = 'Password:'
$passLabel.ForeColor = $Colors.TextPrimary
$passLabel.Location = New-Object System.Drawing.Point(30, 90)
$passLabel.Size = New-Object System.Drawing.Size(340, 20)

$passBox = New-Object System.Windows.Forms.TextBox
$passBox.Location = New-Object System.Drawing.Point(30, 115)
$passBox.Size = New-Object System.Drawing.Size(340, 30)
$passBox.BackColor = $Colors.PanelBg
$passBox.ForeColor = $Colors.TextPrimary
$passBox.UseSystemPasswordChar = $true
$passBox.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$passBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$btnLogin = New-CustomButton -Text 'Login' -X 30 -Y 170 -Width 340 -Height 40
$btnLogin.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)

$loginForm.Controls.Add($loginTitle)
$loginForm.Controls.Add($passLabel)
$loginForm.Controls.Add($passBox)
$loginForm.Controls.Add($btnLogin)

# ============================================================================
# Main Admin Panel
# ============================================================================
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = 'Driver Manager Pro - Admin Panel'
$mainForm.Size = New-Object System.Drawing.Size(1000, 700)
$mainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$mainForm.BackColor = $Colors.Background
$mainForm.ForeColor = $Colors.TextPrimary
$mainForm.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$mainForm.Visible = $false

# Left Panel - Driver List
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Location = New-Object System.Drawing.Point(0, 0)
$leftPanel.Size = New-Object System.Drawing.Size(500, 700)
$leftPanel.BackColor = $Colors.PanelBg
$leftPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$leftTitle = New-Object System.Windows.Forms.Label
$leftTitle.Text = '📋 Drivers in Database'
$leftTitle.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$leftTitle.ForeColor = $Colors.TextPrimary
$leftTitle.Location = New-Object System.Drawing.Point(10, 10)
$leftTitle.Size = New-Object System.Drawing.Size(480, 25)

$lbDrivers = New-Object System.Windows.Forms.ListBox
$lbDrivers.Location = New-Object System.Drawing.Point(10, 45)
$lbDrivers.Size = New-Object System.Windows.Forms.Size(480, 530)
$lbDrivers.BackColor = $Colors.Background
$lbDrivers.ForeColor = $Colors.TextPrimary
$lbDrivers.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$lbDrivers.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$btnEditDriver = New-CustomButton -Text 'Edit' -X 10 -Y 590 -Width 110 -Height 35
$btnDeleteDriver = New-CustomButton -Text 'Delete' -X 130 -Y 590 -Width 110 -Height 35 -BGColor $Colors.Danger
$btnAddDriver = New-CustomButton -Text 'Add New' -X 250 -Y 590 -Width 110 -Height 35 -BGColor $Colors.Success
$btnRefresh = New-CustomButton -Text 'Refresh' -X 370 -Y 590 -Width 110 -Height 35

$leftPanel.Controls.Add($leftTitle)
$leftPanel.Controls.Add($lbDrivers)
$leftPanel.Controls.Add($btnEditDriver)
$leftPanel.Controls.Add($btnDeleteDriver)
$leftPanel.Controls.Add($btnAddDriver)
$leftPanel.Controls.Add($btnRefresh)

# (truncated for brevity in upload)