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
function Get-PasswordHash {
    param([string]$Password)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Password)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return [Convert]::ToBase64String($hash)
}

function Verify-AdminPassword {
    param([string]$InputPassword)
    # SHA256 of 'pluisje'
    $correctHash = "YAosVJOCA6dgm5kFVJtwnLMRj3uKbNF3/p7++tX/DB4="
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
}

# Ensure DB directory exists
$DBDir = Split-Path -Path $AppData.DBPath
if (-not (Test-Path $DBDir)) { New-Item -ItemType Directory -Path $DBDir -Force | Out-Null }

# ============================================================================
# Database Functions
# ============================================================================
function Load-Database {
    if (Test-Path $AppData.DBPath) {
        try {
            $AppData.Database = Get-Content -Path $AppData.DBPath -Raw | ConvertFrom-Json
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error loading database: $_", "Database Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $AppData.Database = @()
        }
    } else {
        $AppData.Database = @()
    }
}

function Save-Database {
    try {
        $AppData.Database | ConvertTo-Json -Depth 4 | Set-Content -Path $AppData.DBPath -Force -Encoding UTF8
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error saving database: $_", "Save Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
}

# ============================================================================
# UI Helpers
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

function Refresh-DriverList {
    $lbDrivers.Items.Clear()
    foreach ($d in $AppData.Database) {
        $lbDrivers.Items.Add("$($d.id): $($d.name) [$($d.type -or 'url')]") | Out-Null
    }
}

# ============================================================================
# Login Form
# ============================================================================
$loginForm = New-Object System.Windows.Forms.Form
$loginForm.Text = 'Driver Manager Pro - Admin Login'
$loginForm.Size = New-Object System.Drawing.Size(420, 260)
$loginForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$loginForm.BackColor = $Colors.Background
$loginForm.ForeColor = $Colors.TextPrimary
$loginForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$loginForm.MaximizeBox = $false
$loginForm.MinimizeBox = $false

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = '🔐 Admin Login'
$lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $Colors.Accent
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(120, 20)

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = 'Password:'
$lblPass.ForeColor = $Colors.TextPrimary
$lblPass.Location = New-Object System.Drawing.Point(30, 80)
$lblPass.Size = New-Object System.Drawing.Size(360, 20)

$passBox = New-Object System.Windows.Forms.TextBox
$passBox.Location = New-Object System.Drawing.Point(30, 105)
$passBox.Size = New-Object System.Drawing.Size(360, 32)
$passBox.BackColor = $Colors.PanelBg
$passBox.ForeColor = $Colors.TextPrimary
$passBox.UseSystemPasswordChar = $true
$passBox.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$passBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$btnLogin = New-CustomButton -Text 'Login' -X 30 -Y 150 -Width 360 -Height 40
$btnLogin.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)

$loginForm.Controls.Add($lblTitle)
$loginForm.Controls.Add($lblPass)
$loginForm.Controls.Add($passBox)
$loginForm.Controls.Add($btnLogin)

# Login click handler
$btnLogin.Add_Click({
    if (Verify-AdminPassword($passBox.Text)) {
        $loginForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $loginForm.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show('Incorrect password.', 'Login Failed', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})

# ============================================================================
# Main Admin Form
# ============================================================================
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = 'Driver Manager Pro - Admin Panel'
$mainForm.Size = New-Object System.Drawing.Size(1000, 700)
$mainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$mainForm.BackColor = $Colors.Background
$mainForm.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Location = New-Object System.Drawing.Point(10,10)
$leftPanel.Size = New-Object System.Drawing.Size(620,620)
$leftPanel.BackColor = $Colors.PanelBg
$leftPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$lblDrivers = New-Object System.Windows.Forms.Label
$lblDrivers.Text = '📋 Drivers in Database'
$lblDrivers.ForeColor = $Colors.TextPrimary
$lblDrivers.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$lblDrivers.Location = New-Object System.Drawing.Point(10,10)
$lblDrivers.AutoSize = $true

$lbDrivers = New-Object System.Windows.Forms.ListBox
$lbDrivers.Location = New-Object System.Drawing.Point(10,40)
$lbDrivers.Size = New-Object System.Drawing.Size(600,480)
$lbDrivers.BackColor = $Colors.Background
$lbDrivers.ForeColor = $Colors.TextPrimary
$lbDrivers.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$lbDrivers.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$btnEditDriver = New-CustomButton -Text 'Edit' -X 10 -Y 540 -Width 110 -Height 36
$btnDeleteDriver = New-CustomButton -Text 'Delete' -X 130 -Y 540 -Width 110 -Height 36 -BGColor $Colors.Danger
$btnAddDriver = New-CustomButton -Text 'Add New' -X 250 -Y 540 -Width 110 -Height 36 -BGColor $Colors.Success
$btnRefresh = New-CustomButton -Text 'Refresh' -X 370 -Y 540 -Width 110 -Height 36
$btnSaveAll = New-CustomButton -Text 'Save DB' -X 490 -Y 540 -Width 120 -Height 36 -BGColor $Colors.Accent

$leftPanel.Controls.Add($lblDrivers)
$leftPanel.Controls.Add($lbDrivers)
$leftPanel.Controls.Add($btnEditDriver)
$leftPanel.Controls.Add($btnDeleteDriver)
$leftPanel.Controls.Add($btnAddDriver)
$leftPanel.Controls.Add($btnRefresh)
$leftPanel.Controls.Add($btnSaveAll)

$mainForm.Controls.Add($leftPanel)

# ============================================================================
# Add/Edit Driver Dialog
# ============================================================================
function Show-DriverEditor([Hashtable]$driver) {
    $isNew = $null -eq $driver
    if ($isNew) { $driver = @{ id = ''; name=''; pattern=''; url=''; type='url'; category=''} }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = if ($isNew) { 'Add New Driver' } else { "Edit Driver - $($driver.id)" }
    $dlg.Size = New-Object System.Drawing.Size(640,420)
    $dlg.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dlg.BackColor = $Colors.Background

    $lblId = New-Object System.Windows.Forms.Label; $lblId.Text='ID:'; $lblId.Location = New-Object System.Drawing.Point(20,20); $lblId.ForeColor = $Colors.TextPrimary
    $txtId = New-Object System.Windows.Forms.TextBox; $txtId.Location = New-Object System.Drawing.Point(120,18); $txtId.Size = New-Object System.Drawing.Size(480,28); $txtId.Text = $driver.id; $txtId.BackColor = $Colors.PanelBg; $txtId.ForeColor = $Colors.TextPrimary

    $lblName = New-Object System.Windows.Forms.Label; $lblName.Text='Name:'; $lblName.Location = New-Object System.Drawing.Point(20,60); $lblName.ForeColor = $Colors.TextPrimary
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.Location = New-Object System.Drawing.Point(120,58); $txtName.Size = New-Object System.Drawing.Size(480,28); $txtName.Text = $driver.name; $txtName.BackColor = $Colors.PanelBg; $txtName.ForeColor = $Colors.TextPrimary

    $lblPattern = New-Object System.Windows.Forms.Label; $lblPattern.Text='Pattern (regex):'; $lblPattern.Location = New-Object System.Drawing.Point(20,100); $lblPattern.ForeColor = $Colors.TextPrimary
    $txtPattern = New-Object System.Windows.Forms.TextBox; $txtPattern.Location = New-Object System.Drawing.Point(120,98); $txtPattern.Size = New-Object System.Drawing.Size(480,28); $txtPattern.Text = $driver.pattern; $txtPattern.BackColor = $Colors.PanelBg; $txtPattern.ForeColor = $Colors.TextPrimary

    $lblType = New-Object System.Windows.Forms.Label; $lblType.Text='Type:'; $lblType.Location = New-Object System.Drawing.Point(20,140); $lblType.ForeColor = $Colors.TextPrimary
    $cmbType = New-Object System.Windows.Forms.ComboBox; $cmbType.Location = New-Object System.Drawing.Point(120,138); $cmbType.Size = New-Object System.Drawing.Size(200,28); $cmbType.Items.AddRange(@('url','command')); $cmbType.DropDownStyle = 'DropDownList'; $cmbType.SelectedItem = $driver.type
    if (-not $cmbType.SelectedItem) { $cmbType.SelectedIndex = 0 }

    $lblUrl = New-Object System.Windows.Forms.Label; $lblUrl.Text='URL or Command:'; $lblUrl.Location = New-Object System.Drawing.Point(20,180); $lblUrl.ForeColor = $Colors.TextPrimary
    $txtUrl = New-Object System.Windows.Forms.TextBox; $txtUrl.Location = New-Object System.Drawing.Point(120,178); $txtUrl.Size = New-Object System.Drawing.Size(480,80); $txtUrl.Multiline = $true; $txtUrl.Text = $driver.url; $txtUrl.BackColor = $Colors.PanelBg; $txtUrl.ForeColor = $Colors.TextPrimary

    $lblCategory = New-Object System.Windows.Forms.Label; $lblCategory.Text='Category:'; $lblCategory.Location = New-Object System.Drawing.Point(20,270); $lblCategory.ForeColor = $Colors.TextPrimary
    $txtCategory = New-Object System.Windows.Forms.TextBox; $txtCategory.Location = New-Object System.Drawing.Point(120,268); $txtCategory.Size = New-Object System.Drawing.Size(480,28); $txtCategory.Text = $driver.category; $txtCategory.BackColor = $Colors.PanelBg; $txtCategory.ForeColor = $Colors.TextPrimary

    $btnOK = New-CustomButton -Text 'Save' -X 120 -Y 310 -Width 140 -Height 36 -BGColor $Colors.Success
    $btnCancel = New-CustomButton -Text 'Cancel' -X 300 -Y 310 -Width 140 -Height 36 -BGColor $Colors.Danger

    $dlg.Controls.AddRange(@($lblId,$txtId,$lblName,$txtName,$lblPattern,$txtPattern,$lblType,$cmbType,$lblUrl,$txtUrl,$lblCategory,$txtCategory,$btnOK,$btnCancel))

    $btnOK.Add_Click({
        # Basic validation
        if ([string]::IsNullOrWhiteSpace($txtId.Text) -or [string]::IsNullOrWhiteSpace($txtName.Text)) {
            [System.Windows.Forms.MessageBox]::Show('ID and Name are required.','Validation', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        $driver.id = $txtId.Text.Trim()
        $driver.name = $txtName.Text.Trim()
        $driver.pattern = $txtPattern.Text.Trim()
        $driver.url = $txtUrl.Text.Trim()
        $driver.type = $cmbType.SelectedItem
        $driver.category = $txtCategory.Text.Trim()

        # Update or add to database
        $existing = $AppData.Database | Where-Object { $_.id -eq $driver.id }
        if ($existing) {
            $idx = [array]::IndexOf($AppData.Database, $existing)
            $AppData.Database[$idx] = $driver
        } else {
            $AppData.Database += $driver
        }
        $dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $dlg.Close()
    })

    $btnCancel.Add_Click({ $dlg.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $dlg.Close() })

    $dlg.ShowDialog()
    return $dlg.DialogResult
}

# ============================================================================
# Event Wiring - Buttons
# ============================================================================
$btnRefresh.Add_Click({ Load-Database; Refresh-DriverList() })

$btnAddDriver.Add_Click({
    $res = Show-DriverEditor $null
    if ($res -eq [System.Windows.Forms.DialogResult]::OK) { Save-Database; Refresh-DriverList() }
})

$btnEditDriver.Add_Click({
    if ($lbDrivers.SelectedIndex -lt 0) { return }
    $sel = $lbDrivers.SelectedItem -split ':',2
    $id = $sel[0].Trim()
    $d = $AppData.Database | Where-Object { $_.id -eq $id }
    if ($d) {
        $res = Show-DriverEditor @{$d.id=$d.id; name=$d.name; pattern=$d.pattern; url=$d.url; type=($d.type -or 'url'); category=$d.category }
        if ($res -eq [System.Windows.Forms.DialogResult]::OK) { Save-Database; Refresh-DriverList() }
    }
})

$btnDeleteDriver.Add_Click({
    if ($lbDrivers.SelectedIndex -lt 0) { return }
    $sel = $lbDrivers.SelectedItem -split ':',2
    $id = $sel[0].Trim()
    if ([System.Windows.Forms.MessageBox]::Show("Delete driver ID $id?","Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question) -eq [System.Windows.Forms.DialogResult]::Yes) {
        $AppData.Database = $AppData.Database | Where-Object { $_.id -ne $id }
        Save-Database; Refresh-DriverList()
    }
})

$btnSaveAll.Add_Click({
    if (Save-Database) { [System.Windows.Forms.MessageBox]::Show('Database saved.','Saved',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) }
})

# Initialize and show UI after successful login
if ($loginForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    Load-Database
    Refresh-DriverList()
    $mainForm.ShowDialog()
}
