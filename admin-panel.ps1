# Admin Panel - Password protected simple CRUD for drivers DB
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Password (sha256 base64 of 'pluisje')
$passwdHash = 'YAosVJOCA6dgm5kFVJtwnLMRj3uKbNF3/p7++tX/DB4='

$DBDir = Join-Path -Path $env:APPDATA -ChildPath 'DriverManager'
if (-not (Test-Path $DBDir)) { New-Item -Path $DBDir -ItemType Directory -Force | Out-Null }
$DBPath = Join-Path -Path $DBDir -ChildPath 'drivers-db.json'

function Load-Database() { if (-not (Test-Path $DBPath)) { return @() } ; try { Get-Content -Path $DBPath -Raw | ConvertFrom-Json } catch { @() } }
function Save-Database($db) { $db | ConvertTo-Json -Depth 5 | Set-Content -Path $DBPath -Encoding UTF8 }

function Get-HashBase64($text) {
    $b = [System.Text.Encoding]::UTF8.GetBytes($text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $h = $sha.ComputeHash($b)
    [Convert]::ToBase64String($h)
}

# Login form loop
$authenticated = $false
while (-not $authenticated) {
    $login = New-Object System.Windows.Forms.Form
    $login.Text = 'Admin Login'
    $login.Size = New-Object System.Drawing.Size(360, 150)
    $login.StartPosition = 'CenterScreen'
    $login.FormBorderStyle = 'FixedDialog'
    $login.MaximizeBox = $false
    $login.MinimizeBox = $false

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = 'Password:'
    $lbl.Location = New-Object System.Drawing.Point(10, 20)
    $lbl.AutoSize = $true

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(90, 18)
    $txt.Width = 240
    $txt.UseSystemPasswordChar = $true

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = 'Login'
    $btnOK.Location = New-Object System.Drawing.Point(90, 60)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.Location = New-Object System.Drawing.Point(180, 60)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $login.AcceptButton = $btnOK
    $login.CancelButton = $btnCancel
    $login.Controls.AddRange(@($lbl, $txt, $btnOK, $btnCancel))
    $login.Add_Shown({ $txt.Focus() })

    $result = $login.ShowDialog()
    $pwd = $txt.Text
    $login.Dispose()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $hash = Get-HashBase64 $pwd
        if ($hash -eq $passwdHash) {
            $authenticated = $true
        } else {
            [System.Windows.Forms.MessageBox]::Show('Incorrect password', 'Error') | Out-Null
        }
    } else {
        exit
    }
}

# Admin main form
$db = Load-Database

$main = New-Object System.Windows.Forms.Form
$main.Text = 'Driver DB Admin'
$main.Size = New-Object System.Drawing.Size(800, 500)
$main.StartPosition = 'CenterScreen'

$lb = New-Object System.Windows.Forms.ListBox
$lb.Dock = 'Left'
$lb.Width = 350

$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = 'Fill'

$lblName = New-Object System.Windows.Forms.Label; $lblName.Text = 'Name'; $lblName.Location = New-Object System.Drawing.Point(10, 10)
$txtName = New-Object System.Windows.Forms.TextBox; $txtName.Location = New-Object System.Drawing.Point(10, 30); $txtName.Width = 380

$lblPattern = New-Object System.Windows.Forms.Label; $lblPattern.Text = 'Pattern (regex)'; $lblPattern.Location = New-Object System.Drawing.Point(10, 60)
$txtPattern = New-Object System.Windows.Forms.TextBox; $txtPattern.Location = New-Object System.Drawing.Point(10, 80); $txtPattern.Width = 380

$lblUrl = New-Object System.Windows.Forms.Label; $lblUrl.Text = 'URL or Command'; $lblUrl.Location = New-Object System.Drawing.Point(10, 110)
$txtUrl = New-Object System.Windows.Forms.TextBox; $txtUrl.Location = New-Object System.Drawing.Point(10, 130); $txtUrl.Width = 380; $txtUrl.Height = 60; $txtUrl.Multiline = $true

$lblType = New-Object System.Windows.Forms.Label; $lblType.Text = 'Type'; $lblType.Location = New-Object System.Drawing.Point(10, 200)
$cbType = New-Object System.Windows.Forms.ComboBox; $cbType.Items.AddRange(@('url', 'command')); $cbType.Location = New-Object System.Drawing.Point(10, 220); $cbType.Width = 120

$btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = 'Add'; $btnAdd.Location = New-Object System.Drawing.Point(10, 260)
$btnUpdate = New-Object System.Windows.Forms.Button; $btnUpdate.Text = 'Update'; $btnUpdate.Location = New-Object System.Drawing.Point(90, 260)
$btnDelete = New-Object System.Windows.Forms.Button; $btnDelete.Text = 'Delete'; $btnDelete.Location = New-Object System.Drawing.Point(170, 260)
$btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = 'Save DB'; $btnSave.Location = New-Object System.Drawing.Point(250, 260)

$panel.Controls.AddRange(@($lblName, $txtName, $lblPattern, $txtPattern, $lblUrl, $txtUrl, $lblType, $cbType, $btnAdd, $btnUpdate, $btnDelete, $btnSave))
$main.Controls.AddRange(@($lb, $panel))

function Refresh-ListBox() { 
    $lb.Items.Clear()
    foreach ($d in $db) { 
        $lb.Items.Add("$($d.id): $($d.name) [$($d.type)]") | Out-Null 
    } 
}
Refresh-ListBox

$lb.Add_SelectedIndexChanged({
    if ($lb.SelectedItem) {
        $id = ($lb.SelectedItem -split ':', 2)[0].Trim()
        $item = $db | Where-Object { $_.id -eq $id } | Select-Object -First 1
        if ($item) {
            $txtName.Text = $item.name
            $txtPattern.Text = $item.pattern
            $txtUrl.Text = $item.url
            $cbType.SelectedItem = $item.type
        }
    }
})

$btnAdd.Add_Click({
    $new = @{ id = ([guid]::NewGuid().ToString()); name = $txtName.Text; pattern = $txtPattern.Text; url = $txtUrl.Text; type = ($cbType.SelectedItem -or 'url'); category = '' }
    $db += $new
    Refresh-ListBox
    $txtName.Clear()
    $txtPattern.Clear()
    $txtUrl.Clear()
    $cbType.SelectedIndex = -1
})

$btnUpdate.Add_Click({
    if (-not $lb.SelectedItem) { return }
    $id = ($lb.SelectedItem -split ':', 2)[0].Trim()
    $item = $db | Where-Object { $_.id -eq $id } | Select-Object -First 1
    if ($item) {
        $item.name = $txtName.Text
        $item.pattern = $txtPattern.Text
        $item.url = $txtUrl.Text
        $item.type = ($cbType.SelectedItem -or 'url')
        Refresh-ListBox
    }
})

$btnDelete.Add_Click({
    if (-not $lb.SelectedItem) { return }
    $id = ($lb.SelectedItem -split ':', 2)[0].Trim()
    $db = @($db | Where-Object { $_.id -ne $id })
    Refresh-ListBox
})

$btnSave.Add_Click({
    Save-Database $db
    [System.Windows.Forms.MessageBox]::Show('Saved', 'Info') | Out-Null
})

[void]$main.ShowDialog()
