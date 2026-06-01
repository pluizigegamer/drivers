# Admin Panel - Fixed 1920x1080 Dark Mode
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Modern Dark Color Scheme
$Colors = @{
    BG_Dark     = [System.Drawing.Color]::FromArgb(10,10,10)
    BG_Panel    = [System.Drawing.Color]::FromArgb(24,24,24)
    BG_Input    = [System.Drawing.Color]::FromArgb(34,34,34)
    Text_Primary= [System.Drawing.Color]::FromArgb(240,240,240)
    Text_Secondary=[System.Drawing.Color]::FromArgb(170,170,170)
    Accent      = [System.Drawing.Color]::FromArgb(58,150,221)
    AccentHover = [System.Drawing.Color]::FromArgb(75,175,255)
    Danger      = [System.Drawing.Color]::FromArgb(200,60,60)
    DangerHover = [System.Drawing.Color]::FromArgb(255,80,80)
}

# Password hash (pluisje)
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

# Login Form (DialogResult loop)
$authenticated = $false
while (-not $authenticated) {
    $login = New-Object System.Windows.Forms.Form
    $login.Text = 'Admin Login'
    $login.Size = New-Object System.Drawing.Size(420, 200)
    $login.StartPosition = 'CenterScreen'
    $login.FormBorderStyle = 'FixedDialog'
    $login.MaximizeBox = $false
    $login.MinimizeBox = $false
    $login.BackColor = $Colors.BG_Dark
    $login.ForeColor = $Colors.Text_Primary

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = 'Fill'
    $panel.BackColor = $Colors.BG_Panel
    $panel.Padding = New-Object System.Windows.Forms.Padding(30)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = 'Enter Admin Password'
    $lbl.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = $Colors.Accent
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point(0,0)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(0,45)
    $txt.Width = 360
    $txt.Height = 40
    $txt.UseSystemPasswordChar = $true
    $txt.BackColor = $Colors.BG_Input
    $txt.ForeColor = $Colors.Text_Primary
    $txt.BorderStyle = 'FixedSingle'
    $txt.Font = New-Object System.Drawing.Font('Segoe UI', 11)

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = 'Login'
    $btnOK.Width = 170
    $btnOK.Height = 36
    $btnOK.BackColor = $Colors.Accent
    $btnOK.FlatStyle = 'Flat'
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.Width = 170
    $btnCancel.Height = 36
    $btnCancel.BackColor = $Colors.Danger
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $panel.Controls.AddRange(@($lbl, $txt, $btnOK, $btnCancel))
    $login.Controls.Add($panel)
    $login.AcceptButton = $btnOK
    $login.CancelButton = $btnCancel
    $login.Add_Shown({ $txt.Focus() })

    $result = $login.ShowDialog()
    $pwd = $txt.Text
    $login.Dispose()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $hash = Get-HashBase64 $pwd
        if ($hash -eq $passwdHash) { $authenticated = $true } else { [System.Windows.Forms.MessageBox]::Show('Incorrect password. Please try again.', 'Access Denied') | Out-Null }
    } else { exit }
}

# Admin Main Form - Fixed 1920x1080
$db = Load-Database

$main = New-Object System.Windows.Forms.Form
$main.Text = 'Driver Database Admin'
$main.ClientSize = New-Object System.Drawing.Size(1920, 1080)
$main.StartPosition = 'Manual'
$main.Location = New-Object System.Drawing.Point(0,0)
$main.FormBorderStyle = 'Sizable'
$main.BackColor = $Colors.BG_Dark
$main.ForeColor = $Colors.Text_Primary
$main.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$main.MinimumSize = New-Object System.Drawing.Size(1920, 1080)

# Header
$header = New-Object System.Windows.Forms.Panel; $header.Dock = 'Top'; $header.Height = 60; $header.BackColor = $Colors.BG_Panel; $header.BorderStyle = 'FixedSingle'
$title = New-Object System.Windows.Forms.Label; $title.Text = 'Driver Database Management'; $title.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold); $title.ForeColor = $Colors.Accent; $title.Dock = 'Fill'; $title.Padding = New-Object System.Windows.Forms.Padding(15,0,0,0)
$header.Controls.Add($title); $main.Controls.Add($header)

# Layout
$content = New-Object System.Windows.Forms.TableLayoutPanel; $content.Dock = 'Fill'; $content.ColumnCount = 2; $content.RowCount = 1; $content.Padding = New-Object System.Windows.Forms.Padding(10)
$content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 40))); $content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 60)))
$main.Controls.Add($content)

# Left - List
$pnlList = New-Object System.Windows.Forms.Panel; $pnlList.BackColor = $Colors.BG_Panel; $pnlList.Padding = New-Object System.Windows.Forms.Padding(10)
$lblList = New-Object System.Windows.Forms.Label; $lblList.Text = 'Drivers'; $lblList.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold); $lblList.ForeColor = $Colors.Text_Primary; $lblList.AutoSize = $true
$lb = New-Object System.Windows.Forms.ListBox; $lb.BackColor = $Colors.BG_Input; $lb.ForeColor = $Colors.Text_Primary; $lb.BorderStyle = 'None'; $lb.Font = New-Object System.Drawing.Font('Segoe UI', 10); $lb.ItemHeight = 22
$pnlList.Controls.AddRange(@($lblList, $lb)); $lb.Anchor = [System.Windows.Forms.AnchorStyles]'Top,Bottom,Left,Right'; $content.Controls.Add($pnlList,0,0)

# Right - Editor
$pnlEditor = New-Object System.Windows.Forms.Panel; $pnlEditor.BackColor = $Colors.BG_Panel; $pnlEditor.Padding = New-Object System.Windows.Forms.Padding(15)
$lblEditor = New-Object System.Windows.Forms.Label; $lblEditor.Text = 'Edit Driver'; $lblEditor.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold); $lblEditor.ForeColor = $Colors.Text_Primary; $lblEditor.AutoSize = $true
$lblName = New-Object System.Windows.Forms.Label; $lblName.Text = 'Name'; $lblName.ForeColor = $Colors.Text_Secondary; $lblName.Location = New-Object System.Drawing.Point(0,40)
$txtName = New-Object System.Windows.Forms.TextBox; $txtName.BackColor = $Colors.BG_Input; $txtName.ForeColor = $Colors.Text_Primary; $txtName.Location = New-Object System.Drawing.Point(0,65); $txtName.Width = 420
$lblPattern = New-Object System.Windows.Forms.Label; $lblPattern.Text = 'Pattern (regex)'; $lblPattern.ForeColor = $Colors.Text_Secondary; $lblPattern.Location = New-Object System.Drawing.Point(0,105)
$txtPattern = New-Object System.Windows.Forms.TextBox; $txtPattern.BackColor = $Colors.BG_Input; $txtPattern.ForeColor = $Colors.Text_Primary; $txtPattern.Location = New-Object System.Drawing.Point(0,130); $txtPattern.Width = 420
$lblType = New-Object System.Windows.Forms.Label; $lblType.Text = 'Type'; $lblType.ForeColor = $Colors.Text_Secondary; $lblType.Location = New-Object System.Drawing.Point(0,170)
$cbType = New-Object System.Windows.Forms.ComboBox; $cbType.Items.AddRange(@('url','command')); $cbType.Location = New-Object System.Drawing.Point(0,195); $cbType.Width = 200; $cbType.DropDownStyle = 'DropDownList'
$lblUrl = New-Object System.Windows.Forms.Label; $lblUrl.Text = 'URL or Command'; $lblUrl.ForeColor = $Colors.Text_Secondary; $lblUrl.Location = New-Object System.Drawing.Point(0,235)
$txtUrl = New-Object System.Windows.Forms.TextBox; $txtUrl.BackColor = $Colors.BG_Input; $txtUrl.ForeColor = $Colors.Text_Primary; $txtUrl.Multiline = $true; $txtUrl.Location = New-Object System.Drawing.Point(0,260); $txtUrl.Width = 780; $txtUrl.Height = 100
$btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = 'Add New'; $btnAdd.Location = New-Object System.Drawing.Point(0,380); $btnUpdate = New-Object System.Windows.Forms.Button; $btnUpdate.Text = 'Update'; $btnUpdate.Location = New-Object System.Drawing.Point(100,380)
$btnDelete = New-Object System.Windows.Forms.Button; $btnDelete.Text = 'Delete'; $btnDelete.Location = New-Object System.Drawing.Point(200,380); $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = 'Save Database'; $btnSave.Location = New-Object System.Drawing.Point(0,420)
$pnlEditor.Controls.AddRange(@($lblEditor,$lblName,$txtName,$lblPattern,$txtPattern,$lblType,$cbType,$lblUrl,$txtUrl,$btnAdd,$btnUpdate,$btnDelete,$btnSave))
$content.Controls.Add($pnlEditor,1,0)

# Functions
function Refresh-ListBox() { $lb.Items.Clear(); foreach ($d in $db) { $lb.Items.Add("$($d.id): $($d.name)") | Out-Null } } 
Refresh-ListBox

# Events
$lb.Add_SelectedIndexChanged({ if ($lb.SelectedItem) { $id = ($lb.SelectedItem -split ':', 2)[0].Trim(); $item = $db | Where-Object { $_.id -eq $id } | Select-Object -First 1; if ($item) { $txtName.Text = $item.name; $txtPattern.Text = $item.pattern; $txtUrl.Text = $item.url; $cbType.SelectedItem = $item.type } } })
$btnAdd.Add_Click({ if ([string]::IsNullOrWhiteSpace($txtName.Text)) { [System.Windows.Forms.MessageBox]::Show('Enter driver name','Warning') | Out-Null; return }; $new = @{ id = ([guid]::NewGuid().ToString()); name = $txtName.Text; pattern = $txtPattern.Text; url = $txtUrl.Text; type = ($cbType.SelectedItem -or 'url'); category = '' }; $db += $new; Refresh-ListBox; $txtName.Clear(); $txtPattern.Clear(); $txtUrl.Clear(); $cbType.SelectedIndex = -1 })
$btnUpdate.Add_Click({ if (-not $lb.SelectedItem) { [System.Windows.Forms.MessageBox]::Show('Select a driver','Warning') | Out-Null; return }; $id = ($lb.SelectedItem -split ':', 2)[0].Trim(); $item = $db | Where-Object { $_.id -eq $id } | Select-Object -First 1; if ($item) { $item.name = $txtName.Text; $item.pattern = $txtPattern.Text; $item.url = $txtUrl.Text; $item.type = ($cbType.SelectedItem -or 'url'); Refresh-ListBox } })
$btnDelete.Add_Click({ if (-not $lb.SelectedItem) { [System.Windows.Forms.MessageBox]::Show('Select a driver to delete','Warning') | Out-Null; return }; $id = ($lb.SelectedItem -split ':', 2)[0].Trim(); $db = @($db | Where-Object { $_.id -ne $id }); Refresh-ListBox; $txtName.Clear(); $txtPattern.Clear(); $txtUrl.Clear(); $cbType.SelectedIndex = -1 })
$btnSave.Add_Click({ Save-Database $db; [System.Windows.Forms.MessageBox]::Show('Database saved successfully','Success') | Out-Null })

[void]$main.ShowDialog()
