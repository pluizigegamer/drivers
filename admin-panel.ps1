# Admin Panel - Modern Responsive CRUD UI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Modern Color Scheme
$Colors = @{
    BG_Dark     = [System.Drawing.Color]::FromArgb(20, 20, 20)
    BG_Panel    = [System.Drawing.Color]::FromArgb(30, 30, 30)
    BG_Input    = [System.Drawing.Color]::FromArgb(40, 40, 40)
    Text_Primary= [System.Drawing.Color]::FromArgb(240, 240, 240)
    Text_Secondary=[System.Drawing.Color]::FromArgb(180, 180, 180)
    Accent      = [System.Drawing.Color]::FromArgb(58, 150, 221)
    AccentHover = [System.Drawing.Color]::FromArgb(75, 175, 255)
    Danger      = [System.Drawing.Color]::FromArgb(220, 60, 60)
    DangerHover = [System.Drawing.Color]::FromArgb(255, 80, 80)
    Border      = [System.Drawing.Color]::FromArgb(50, 50, 50)
}

# Password hash
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

function New-StyledButton($text, $color = $Colors.Accent) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.FlatStyle = 'Flat'
    $b.ForeColor = $Colors.Text_Primary
    $b.BackColor = $color
    $b.FlatAppearance.BorderColor = $color
    $b.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $b.Height = 36
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $hover = if ($color -eq $Colors.Danger) { $Colors.DangerHover } else { $Colors.AccentHover }
    $b.Tag = @{ Normal = $color; Hover = $hover }
    $b.Add_MouseEnter({ param($s,$e) $s.BackColor = $s.Tag.Hover })
    $b.Add_MouseLeave({ param($s,$e) $s.BackColor = $s.Tag.Normal })
    return $b
}

# Login Form
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
    $lbl.Location = New-Object System.Drawing.Point(0, 0)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(0, 45)
    $txt.Width = 360
    $txt.Height = 40
    $txt.UseSystemPasswordChar = $true
    $txt.BackColor = $Colors.BG_Input
    $txt.ForeColor = $Colors.Text_Primary
    $txt.BorderStyle = 'FixedSingle'
    $txt.Font = New-Object System.Drawing.Font('Segoe UI', 11)

    $btnOK = New-StyledButton 'Login'
    $btnOK.Location = New-Object System.Drawing.Point(0, 100)
    $btnOK.Width = 170
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $btnCancel = New-StyledButton 'Cancel'
    $btnCancel.Location = New-Object System.Drawing.Point(190, 100)
    $btnCancel.Width = 170
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $login.AcceptButton = $btnOK
    $login.CancelButton = $btnCancel

    $panel.Controls.AddRange(@($lbl, $txt, $btnOK, $btnCancel))
    $login.Controls.Add($panel)
    $login.Add_Shown({ $txt.Focus() })

    $result = $login.ShowDialog()
    $pwd = $txt.Text
    $login.Dispose()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $hash = Get-HashBase64 $pwd
        if ($hash -eq $passwdHash) {
            $authenticated = $true
        } else {
            [System.Windows.Forms.MessageBox]::Show('Incorrect password. Please try again.', 'Access Denied') | Out-Null
        }
    } else {
        exit
    }
}

# Admin Main Form
$db = Load-Database

$main = New-Object System.Windows.Forms.Form
$main.Text = 'Driver Database Admin'
$main.Size = New-Object System.Drawing.Size(1000, 700)
$main.StartPosition = 'CenterScreen'
$main.BackColor = $Colors.BG_Dark
$main.ForeColor = $Colors.Text_Primary
$main.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$main.MinimumSize = New-Object System.Drawing.Size(800, 500)

# Header
$header = New-Object System.Windows.Forms.Panel
$header.Dock = 'Top'
$header.Height = 50
$header.BackColor = $Colors.BG_Panel
$header.BorderStyle = 'FixedSingle'
$header.Padding = New-Object System.Windows.Forms.Padding(15, 0, 0, 0)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Driver Database Management'
$title.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = $Colors.Accent
$title.AutoSize = $false
$title.TextAlign = 'MiddleLeft'
$title.Dock = 'Fill'

$header.Controls.Add($title)
$main.Controls.Add($header)

# Main Content
$content = New-Object System.Windows.Forms.TableLayoutPanel
$content.Dock = 'Fill'
$content.ColumnCount = 2
$content.RowCount = 1
$content.Padding = New-Object System.Windows.Forms.Padding(10)
$content.ColumnStyles.Clear()
$content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 40)))
$content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 60)))
$content.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
$main.Controls.Add($content)

# Left Panel - List
$pnlList = New-Object System.Windows.Forms.Panel
$pnlList.BackColor = $Colors.BG_Panel
$pnlList.Padding = New-Object System.Windows.Forms.Padding(10)

$lblList = New-Object System.Windows.Forms.Label
$lblList.Text = 'Drivers'
$lblList.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$lblList.ForeColor = $Colors.Text_Primary
$lblList.AutoSize = $true

$lb = New-Object System.Windows.Forms.ListBox
$lb.BackColor = $Colors.BG_Input
$lb.ForeColor = $Colors.Text_Primary
$lb.BorderStyle = 'None'
$lb.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$lb.ItemHeight = 22

$pnlList.Controls.Add($lb)
$pnlList.Controls.Add($lblList)

$lb.Anchor = [System.Windows.Forms.AnchorStyles]'Top,Bottom,Left,Right'
$lb.Top = 35
$lb.Left = 0
$lb.Width = $pnlList.Width - 20
$lb.Height = $pnlList.Height - 35

# Right Panel - Editor
$pnlEditor = New-Object System.Windows.Forms.Panel
$pnlEditor.BackColor = $Colors.BG_Panel
$pnlEditor.Padding = New-Object System.Windows.Forms.Padding(15)

$lblEditor = New-Object System.Windows.Forms.Label
$lblEditor.Text = 'Edit Driver'
$lblEditor.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$lblEditor.ForeColor = $Colors.Text_Primary
$lblEditor.AutoSize = $true
$lblEditor.Location = New-Object System.Drawing.Point(0, 0)

$lblName = New-Object System.Windows.Forms.Label; $lblName.Text = 'Name'; $lblName.ForeColor = $Colors.Text_Secondary; $lblName.AutoSize = $true; $lblName.Location = New-Object System.Drawing.Point(0, 40)
$txtName = New-Object System.Windows.Forms.TextBox; $txtName.BackColor = $Colors.BG_Input; $txtName.ForeColor = $Colors.Text_Primary; $txtName.BorderStyle = 'FixedSingle'; $txtName.Font = New-Object System.Drawing.Font('Segoe UI', 10); $txtName.Location = New-Object System.Drawing.Point(0, 65); $txtName.Width = 280; $txtName.Height = 30

$lblPattern = New-Object System.Windows.Forms.Label; $lblPattern.Text = 'Pattern (regex)'; $lblPattern.ForeColor = $Colors.Text_Secondary; $lblPattern.AutoSize = $true; $lblPattern.Location = New-Object System.Drawing.Point(0, 105)
$txtPattern = New-Object System.Windows.Forms.TextBox; $txtPattern.BackColor = $Colors.BG_Input; $txtPattern.ForeColor = $Colors.Text_Primary; $txtPattern.BorderStyle = 'FixedSingle'; $txtPattern.Font = New-Object System.Drawing.Font('Segoe UI', 10); $txtPattern.Location = New-Object System.Drawing.Point(0, 130); $txtPattern.Width = 280; $txtPattern.Height = 30

$lblType = New-Object System.Windows.Forms.Label; $lblType.Text = 'Type'; $lblType.ForeColor = $Colors.Text_Secondary; $lblType.AutoSize = $true; $lblType.Location = New-Object System.Drawing.Point(0, 170)
$cbType = New-Object System.Windows.Forms.ComboBox; $cbType.Items.AddRange(@('url', 'command')); $cbType.BackColor = $Colors.BG_Input; $cbType.ForeColor = $Colors.Text_Primary; $cbType.Font = New-Object System.Drawing.Font('Segoe UI', 10); $cbType.Location = New-Object System.Drawing.Point(0, 195); $cbType.Width = 280; $cbType.Height = 30; $cbType.DropDownStyle = 'DropDownList'

$lblUrl = New-Object System.Windows.Forms.Label; $lblUrl.Text = 'URL or Command'; $lblUrl.ForeColor = $Colors.Text_Secondary; $lblUrl.AutoSize = $true; $lblUrl.Location = New-Object System.Drawing.Point(0, 235)
$txtUrl = New-Object System.Windows.Forms.TextBox; $txtUrl.BackColor = $Colors.BG_Input; $txtUrl.ForeColor = $Colors.Text_Primary; $txtUrl.BorderStyle = 'FixedSingle'; $txtUrl.Font = New-Object System.Drawing.Font('Segoe UI', 9); $txtUrl.Multiline = $true; $txtUrl.WordWrap = $true; $txtUrl.Location = New-Object System.Drawing.Point(0, 260); $txtUrl.Width = 380; $txtUrl.Height = 80

$btnAdd = New-StyledButton 'Add New'
$btnAdd.Location = New-Object System.Drawing.Point(0, 360)
$btnAdd.Width = 85

$btnUpdate = New-StyledButton 'Update'
$btnUpdate.Location = New-Object System.Drawing.Point(95, 360)
$btnUpdate.Width = 85

$btnDelete = New-StyledButton 'Delete' $Colors.Danger
$btnDelete.Location = New-Object System.Drawing.Point(190, 360)
$btnDelete.Width = 85

$btnSave = New-StyledButton 'Save Database'
$btnSave.Location = New-Object System.Drawing.Point(0, 410)
$btnSave.Width = 275
$btnSave.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$btnSave.Tag = @{ Normal = [System.Drawing.Color]::FromArgb(76, 175, 80); Hover = [System.Drawing.Color]::FromArgb(100, 200, 100) }

$pnlEditor.Controls.AddRange(@($lblEditor, $lblName, $txtName, $lblPattern, $txtPattern, $lblType, $cbType, $lblUrl, $txtUrl, $btnAdd, $btnUpdate, $btnDelete, $btnSave))

$content.Controls.Add($pnlList, 0, 0)
$content.Controls.Add($pnlEditor, 1, 0)

# Functions
function Refresh-ListBox() { 
    $lb.Items.Clear()
    foreach ($d in $db) { 
        $lb.Items.Add("$($d.id): $($d.name)") | Out-Null 
    } 
}
Refresh-ListBox

# Events
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
    if ([string]::IsNullOrWhiteSpace($txtName.Text)) { [System.Windows.Forms.MessageBox]::Show('Enter driver name', 'Warning') | Out-Null; return }
    $new = @{ id = ([guid]::NewGuid().ToString()); name = $txtName.Text; pattern = $txtPattern.Text; url = $txtUrl.Text; type = ($cbType.SelectedItem -or 'url'); category = '' }
    $db += $new
    Refresh-ListBox
    $txtName.Clear(); $txtPattern.Clear(); $txtUrl.Clear(); $cbType.SelectedIndex = -1
})

$btnUpdate.Add_Click({
    if (-not $lb.SelectedItem) { [System.Windows.Forms.MessageBox]::Show('Select a driver', 'Warning') | Out-Null; return }
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
    if (-not $lb.SelectedItem) { [System.Windows.Forms.MessageBox]::Show('Select a driver to delete', 'Warning') | Out-Null; return }
    $id = ($lb.SelectedItem -split ':', 2)[0].Trim()
    $db = @($db | Where-Object { $_.id -ne $id })
    Refresh-ListBox
    $txtName.Clear(); $txtPattern.Clear(); $txtUrl.Clear(); $cbType.SelectedIndex = -1
})

$btnSave.Add_Click({
    Save-Database $db
    [System.Windows.Forms.MessageBox]::Show('Database saved successfully', 'Success') | Out-Null
})

[void]$main.ShowDialog()
