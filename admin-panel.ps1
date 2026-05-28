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
    Background = [System.Drawing.Color]::FromArgb(12, 12, 12)
    PanelBg = [System.Drawing.Color]::FromArgb(24, 24, 24)
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
    
    $button.Add_MouseEnter({ $button.BackColor = $Colors.AccentHover })
    $button.Add_MouseLeave({ $button.BackColor = $BGColor })
    
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
$lbDrivers.Size = New-Object System.Drawing.Size(480, 530)
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

# Right Panel - Edit Driver
$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Location = New-Object System.Drawing.Point(500, 0)
$rightPanel.Size = New-Object System.Drawing.Size(500, 700)
$rightPanel.BackColor = $Colors.PanelBg
$rightPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$rightTitle = New-Object System.Windows.Forms.Label
$rightTitle.Text = '✏️ Edit Driver'
$rightTitle.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$rightTitle.ForeColor = $Colors.TextPrimary
$rightTitle.Location = New-Object System.Drawing.Point(10, 10)
$rightTitle.Size = New-Object System.Drawing.Size(480, 25)

# Driver Name
$lblName = New-Object System.Windows.Forms.Label
$lblName.Text = 'Driver Name:'
$lblName.ForeColor = $Colors.TextPrimary
$lblName.Location = New-Object System.Drawing.Point(10, 50)
$lblName.Size = New-Object System.Drawing.Size(480, 18)

$txtName = New-Object System.Windows.Forms.TextBox
$txtName.Location = New-Object System.Drawing.Point(10, 70)
$txtName.Size = New-Object System.Drawing.Size(480, 25)
$txtName.BackColor = $Colors.Background
$txtName.ForeColor = $Colors.TextPrimary
$txtName.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Pattern
$lblPattern = New-Object System.Windows.Forms.Label
$lblPattern.Text = 'Pattern (Regex):'
$lblPattern.ForeColor = $Colors.TextPrimary
$lblPattern.Location = New-Object System.Drawing.Point(10, 105)
$lblPattern.Size = New-Object System.Drawing.Size(480, 18)

$txtPattern = New-Object System.Windows.Forms.TextBox
$txtPattern.Location = New-Object System.Drawing.Point(10, 125)
$txtPattern.Size = New-Object System.Drawing.Size(480, 25)
$txtPattern.BackColor = $Colors.Background
$txtPattern.ForeColor = $Colors.TextPrimary
$txtPattern.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# URL
$lblUrl = New-Object System.Windows.Forms.Label
$lblUrl.Text = 'Download URL or PowerShell Command:'
$lblUrl.ForeColor = $Colors.TextPrimary
$lblUrl.Location = New-Object System.Drawing.Point(10, 160)
$lblUrl.Size = New-Object System.Drawing.Size(480, 18)

$txtUrl = New-Object System.Windows.Forms.TextBox
$txtUrl.Location = New-Object System.Drawing.Point(10, 180)
$txtUrl.Size = New-Object System.Drawing.Size(480, 60)
$txtUrl.BackColor = $Colors.Background
$txtUrl.ForeColor = $Colors.TextPrimary
$txtUrl.Multiline = $true
$txtUrl.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtUrl.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical

# Category
$lblCategory = New-Object System.Windows.Forms.Label
$lblCategory.Text = 'Category:'
$lblCategory.ForeColor = $Colors.TextPrimary
$lblCategory.Location = New-Object System.Drawing.Point(10, 255)
$lblCategory.Size = New-Object System.Drawing.Size(480, 18)

$cbCategory = New-Object System.Windows.Forms.ComboBox
$cbCategory.Location = New-Object System.Drawing.Point(10, 275)
$cbCategory.Size = New-Object System.Drawing.Size(480, 25)
$cbCategory.BackColor = $Colors.Background
$cbCategory.ForeColor = $Colors.TextPrimary
$cbCategory.Items.AddRange(@('GPU', 'Audio', 'Network', 'Chipset', 'Other'))
$cbCategory.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

# Buttons
$btnSave = New-CustomButton -Text 'Save' -X 10 -Y 620 -Width 110 -Height 35 -BGColor $Colors.Success
$btnCancel = New-CustomButton -Text 'Cancel' -X 130 -Y 620 -Width 110 -Height 35
$btnTest = New-CustomButton -Text 'Test URL' -X 250 -Y 620 -Width 110 -Height 35 -BGColor $Colors.Warning
$btnLogout = New-CustomButton -Text 'Logout' -X 370 -Y 620 -Width 110 -Height 35 -BGColor $Colors.Danger

$rightPanel.Controls.Add($rightTitle)
$rightPanel.Controls.Add($lblName)
$rightPanel.Controls.Add($txtName)
$rightPanel.Controls.Add($lblPattern)
$rightPanel.Controls.Add($txtPattern)
$rightPanel.Controls.Add($lblUrl)
$rightPanel.Controls.Add($txtUrl)
$rightPanel.Controls.Add($lblCategory)
$rightPanel.Controls.Add($cbCategory)
$rightPanel.Controls.Add($btnSave)
$rightPanel.Controls.Add($btnCancel)
$rightPanel.Controls.Add($btnTest)
$rightPanel.Controls.Add($btnLogout)

$mainForm.Controls.Add($leftPanel)
$mainForm.Controls.Add($rightPanel)

# ============================================================================
# UI Functions
# ============================================================================
function Refresh-DriverList {
    $lbDrivers.Items.Clear()
    $AppData.Database | ForEach-Object {
        $lbDrivers.Items.Add($_.name) | Out-Null
    }
}

function Clear-EditForm {
    $txtName.Text = ''
    $txtPattern.Text = ''
    $txtUrl.Text = ''
    $cbCategory.SelectedIndex = -1
    $AppData.SelectedDriver = $null
}

function Load-DriverToForm {
    if ($lbDrivers.SelectedIndex -ge 0) {
        $driver = $AppData.Database[$lbDrivers.SelectedIndex]
        $AppData.SelectedDriver = $driver
        
        $txtName.Text = $driver.name
        $txtPattern.Text = $driver.pattern
        $txtUrl.Text = $driver.url
        $cbCategory.SelectedItem = $driver.category
    }
}

# ============================================================================
# Event Handlers - Login
# ============================================================================
$btnLogin.Add_Click({
    if (Verify-AdminPassword $passBox.Text) {
        $loginForm.Hide()
        Load-Database
        Refresh-DriverList
        $mainForm.Visible = $true
    } else {
        [System.Windows.Forms.MessageBox]::Show('Invalid password!', 'Authentication Failed', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        $passBox.Text = ''
        $passBox.Focus()
    }
})

# Allow Enter key to login
$passBox.Add_KeyDown({
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Return) {
        $btnLogin.PerformClick()
    }
})

# ============================================================================
# Event Handlers - Main Panel
# ============================================================================
$lbDrivers.Add_SelectedIndexChanged({
    Load-DriverToForm
})

$btnAddDriver.Add_Click({
    Clear-EditForm
    $newDriver = @{
        id = ([Guid]::NewGuid().ToString().Substring(0, 8))
        name = ''
        pattern = ''
        url = ''
        category = 'GPU'
    }
    $AppData.Database += $newDriver
    Refresh-DriverList
    $lbDrivers.SelectedIndex = $AppData.Database.Count - 1
})

$btnEditDriver.Add_Click({
    if ($lbDrivers.SelectedIndex -ge 0) {
        # Updates happen as you type
    }
})

$btnSave.Add_Click({
    if ($lbDrivers.SelectedIndex -ge 0 -and $AppData.SelectedDriver) {
        $AppData.SelectedDriver.name = $txtName.Text
        $AppData.SelectedDriver.pattern = $txtPattern.Text
        $AppData.SelectedDriver.url = $txtUrl.Text
        $AppData.SelectedDriver.category = if ($cbCategory.SelectedIndex -ge 0) { $cbCategory.SelectedItem } else { 'GPU' }
        
        if (Save-Database) {
            [System.Windows.Forms.MessageBox]::Show('Driver saved successfully!', 'Success', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Refresh-DriverList
            Clear-EditForm
        }
    }
})

$btnCancel.Add_Click({
    Clear-EditForm
    $lbDrivers.SelectedIndex = -1
})

$btnDeleteDriver.Add_Click({
    if ($lbDrivers.SelectedIndex -ge 0) {
        $result = [System.Windows.Forms.MessageBox]::Show('Delete this driver?', 'Confirm Delete', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            $AppData.Database = $AppData.Database | Where-Object { $_.id -ne $AppData.SelectedDriver.id }
            if (Save-Database) {
                Refresh-DriverList
                Clear-EditForm
            }
        }
    }
})

$btnRefresh.Add_Click({
    Load-Database
    Refresh-DriverList
    Clear-EditForm
})

$btnTest.Add_Click({
    if ($txtUrl.Text) {
        try {
            $response = Invoke-WebRequest -Uri $txtUrl.Text -UseBasicParsing -TimeoutSec 5 -Method Head
            [System.Windows.Forms.MessageBox]::Show("✓ URL is valid (Status: $($response.StatusCode))", 'URL Test', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("✗ URL test failed: $($_.Exception.Message)", 'URL Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
})

$btnLogout.Add_Click({
    $mainForm.Visible = $false
    Clear-EditForm
    $passBox.Text = ''
    $loginForm.Show()
    $passBox.Focus()
})

# ============================================================================
# Run Application
# ============================================================================
$loginForm.ShowDialog()