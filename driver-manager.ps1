# Driver Manager - Modern Responsive UI
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
    Border      = [System.Drawing.Color]::FromArgb(50, 50, 50)
}

# Database
$DBDir = Join-Path -Path $env:APPDATA -ChildPath 'DriverManager'
if (-not (Test-Path $DBDir)) { New-Item -Path $DBDir -ItemType Directory -Force | Out-Null }
$DBPath = Join-Path -Path $DBDir -ChildPath 'drivers-db.json'

function Save-Database($db) { $db | ConvertTo-Json -Depth 5 | Set-Content -Path $DBPath -Encoding UTF8 }
function Load-Database() {
    if (-not (Test-Path $DBPath)) {
        $sample = @(
            @{ id = '1'; name = 'Global NVIDIA Driver'; pattern='NVIDIA|GeForce|RTX|GTX'; url='https://us.download.nvidia.com/nvapp/client/11.0.7.247/NVIDIA_app_v11.0.7.247.exe'; type='url'; category='GPU' },
            @{ id = '2'; name = 'AMD Installer (command)'; pattern='AMD|Radeon|RX|Vega'; url='Invoke-WebRequest -Uri "https://drivers.amd.com/drivers/installer/26.10/whql/amd-software-adrenalin-edition-26.5.2-minimalsetup-260513_web.exe" -Headers @{"Referer"="https://www.amd.com/"} -OutFile "$env:USERPROFILE\\Downloads\\amd_driver.exe"; Start-Process -FilePath "$env:USERPROFILE\\Downloads\\amd_driver.exe" -Wait'; type='command'; category='GPU' },
            @{ id = '3'; name = 'Intel Graphics Driver'; pattern='Intel Graphics|Intel Iris'; url='https://www.intel.com/content/www/en/en/download/726609'; type='url'; category='GPU' }
        )
        Save-Database $sample
    }
    try { Get-Content -Path $DBPath -Raw | ConvertFrom-Json } catch { @() }
}

function Detect-Devices() {
    $res = @()
    try { $gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue } catch { $gpus = @() }
    foreach ($g in $gpus) { $res += [pscustomobject]@{ Type='GPU'; Name = $g.Name; PNPDeviceID = $g.PNPDeviceID } }
    try { $nics = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "PhysicalAdapter=TRUE" -ErrorAction SilentlyContinue } catch { $nics = @() }
    foreach ($n in $nics) { if ($n.Name) { $res += [pscustomobject]@{ Type='Network'; Name = $n.Name; PNPDeviceID = $n.PNPDeviceID } } }
    try { $aud = Get-CimInstance -ClassName Win32_SoundDevice -ErrorAction SilentlyContinue } catch { $aud = @() }
    foreach ($a in $aud) { $res += [pscustomobject]@{ Type='Audio'; Name = $a.Name; PNPDeviceID = $a.PNPDeviceID } }
    return $res
}

function New-StyledButton($text) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.FlatStyle = 'Flat'
    $b.ForeColor = $Colors.Text_Primary
    $b.BackColor = $Colors.Accent
    $b.FlatAppearance.BorderColor = $Colors.Accent
    $b.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Regular)
    $b.Height = 40
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Tag = @{ Normal = $Colors.Accent; Hover = $Colors.AccentHover }
    $b.Add_MouseEnter({ param($s,$e) $s.BackColor = $s.Tag.Hover })
    $b.Add_MouseLeave({ param($s,$e) $s.BackColor = $s.Tag.Normal })
    return $b
}

function New-StyledListBox() {
    $lb = New-Object System.Windows.Forms.ListBox
    $lb.BackColor = $Colors.BG_Input
    $lb.ForeColor = $Colors.Text_Primary
    $lb.BorderStyle = 'None'
    $lb.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $lb.ItemHeight = 24
    return $lb
}

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Driver Manager'
$form.Size = New-Object System.Drawing.Size(1200, 750)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $Colors.BG_Dark
$form.ForeColor = $Colors.Text_Primary
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$form.MinimumSize = New-Object System.Drawing.Size(800, 500)

# Header
$header = New-Object System.Windows.Forms.Panel
$header.Dock = 'Top'
$header.Height = 60
$header.BackColor = $Colors.BG_Panel
$header.BorderStyle = 'FixedSingle'

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Driver Manager Pro'
$title.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = $Colors.Accent
$title.AutoSize = $false
$title.TextAlign = 'MiddleLeft'
$title.Dock = 'Fill'
$title.Padding = New-Object System.Windows.Forms.Padding(20, 0, 0, 0)

$header.Controls.Add($title)
$form.Controls.Add($header)

# Main Content - Table Layout
$content = New-Object System.Windows.Forms.TableLayoutPanel
$content.Dock = 'Fill'
$content.ColumnCount = 3
$content.RowCount = 1
$content.Padding = New-Object System.Windows.Forms.Padding(10)
$content.ColumnStyles.Clear()
$content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$content.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
$form.Controls.Add($content)

# Left Panel - Selected Drivers
$pnlSelected = New-Object System.Windows.Forms.Panel
$pnlSelected.BackColor = $Colors.BG_Panel
$pnlSelected.Padding = New-Object System.Windows.Forms.Padding(10)

$lblSelected = New-Object System.Windows.Forms.Label
$lblSelected.Text = 'Selected Drivers'
$lblSelected.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$lblSelected.ForeColor = $Colors.Text_Primary
$lblSelected.AutoSize = $true

$lbSelected = New-StyledListBox
$lbSelected.SelectionMode = 'MultiExtended'

$btnRemove = New-StyledButton 'Remove'
$btnRemove.Dock = 'Bottom'
$btnRemove.Margin = New-Object System.Windows.Forms.Padding(0, 10, 0, 0)

$pnlSelected.Controls.Add($btnRemove)
$pnlSelected.Controls.Add($lbSelected)
$pnlSelected.Controls.Add($lblSelected)

$lbSelected.Anchor = [System.Windows.Forms.AnchorStyles]'Top,Bottom,Left,Right'
$lbSelected.Top = 35
$lbSelected.Left = 0
$lbSelected.Width = $pnlSelected.Width - 20
$lbSelected.Height = $pnlSelected.Height - 90

# Middle Panel - Database
$pnlDatabase = New-Object System.Windows.Forms.Panel
$pnlDatabase.BackColor = $Colors.BG_Panel
$pnlDatabase.Padding = New-Object System.Windows.Forms.Padding(10)

$lblDatabase = New-Object System.Windows.Forms.Label
$lblDatabase.Text = 'Available Drivers'
$lblDatabase.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$lblDatabase.ForeColor = $Colors.Text_Primary
$lblDatabase.AutoSize = $true

$lbDatabase = New-StyledListBox
$lbDatabase.SelectionMode = 'MultiExtended'

$btnAdd = New-StyledButton 'Add to Selection'
$btnAdd.Dock = 'Bottom'
$btnAdd.Margin = New-Object System.Windows.Forms.Padding(0, 10, 0, 0)

$pnlDatabase.Controls.Add($btnAdd)
$pnlDatabase.Controls.Add($lbDatabase)
$pnlDatabase.Controls.Add($lblDatabase)

$lbDatabase.Anchor = [System.Windows.Forms.AnchorStyles]'Top,Bottom,Left,Right'
$lbDatabase.Top = 35
$lbDatabase.Left = 0
$lbDatabase.Width = $pnlDatabase.Width - 20
$lbDatabase.Height = $pnlDatabase.Height - 90

# Right Panel - Devices
$pnlDevices = New-Object System.Windows.Forms.Panel
$pnlDevices.BackColor = $Colors.BG_Panel
$pnlDevices.Padding = New-Object System.Windows.Forms.Padding(10)

$lblDevices = New-Object System.Windows.Forms.Label
$lblDevices.Text = 'Detected Devices'
$lblDevices.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$lblDevices.ForeColor = $Colors.Text_Primary
$lblDevices.AutoSize = $true

$lbDevices = New-StyledListBox

$btnScan = New-StyledButton 'Scan Devices'
$btnScan.Dock = 'Bottom'
$btnScan.Margin = New-Object System.Windows.Forms.Padding(0, 10, 0, 0)

$pnlDevices.Controls.Add($btnScan)
$pnlDevices.Controls.Add($lbDevices)
$pnlDevices.Controls.Add($lblDevices)

$lbDevices.Anchor = [System.Windows.Forms.AnchorStyles]'Top,Bottom,Left,Right'
$lbDevices.Top = 35
$lbDevices.Left = 0
$lbDevices.Width = $pnlDevices.Width - 20
$lbDevices.Height = $pnlDevices.Height - 90

$content.Controls.Add($pnlSelected, 0, 0)
$content.Controls.Add($pnlDatabase, 1, 0)
$content.Controls.Add($pnlDevices, 2, 0)

# Footer
$footer = New-Object System.Windows.Forms.Panel
$footer.Dock = 'Bottom'
$footer.Height = 60
$footer.BackColor = $Colors.BG_Panel
$footer.BorderStyle = 'FixedSingle'
$footer.Padding = New-Object System.Windows.Forms.Padding(10)

$btnInstall = New-StyledButton 'Download & Install Selected'
$btnInstall.Width = 250
$btnInstall.Dock = 'Left'

$btnExit = New-StyledButton 'Exit'
$btnExit.Width = 100
$btnExit.Dock = 'Right'
$btnExit.BackColor = $Colors.Accent
$btnExit.Tag = @{ Normal = $Colors.Accent; Hover = [System.Drawing.Color]::FromArgb(200, 50, 50) }

$footer.Controls.Add($btnExit)
$footer.Controls.Add($btnInstall)
$form.Controls.Add($footer)

# Load Data
$db = Load-Database

function Refresh-DatabaseList() {
    $lbDatabase.Items.Clear()
    foreach ($d in $db) { $lbDatabase.Items.Add("$($d.name)") | Out-Null }
}
Refresh-DatabaseList

function Refresh-DeviceList() {
    $lbDevices.Items.Clear()
    $devs = Detect-Devices
    foreach ($dv in $devs) { $lbDevices.Items.Add("$($dv.Type): $($dv.Name)") | Out-Null }
}
Refresh-DeviceList

# Event Handlers
$btnScan.Add_Click({ Refresh-DeviceList })

$btnAdd.Add_Click({
    foreach ($i in $lbDatabase.SelectedItems) {
        $lbSelected.Items.Add($i) | Out-Null
    }
})

$btnRemove.Add_Click({
    $indices = @()
    for ($i = $lbSelected.Items.Count - 1; $i -ge 0; $i--) {
        if ($lbSelected.SelectedIndices -contains $i) { $indices += $i }
    }
    foreach ($i in $indices) { $lbSelected.Items.RemoveAt($i) }
})

$btnInstall.Add_Click({
    if ($lbSelected.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show('No drivers selected', 'Info') | Out-Null; return }
    for ($i=0; $i -lt $lbSelected.Items.Count; $i++) {
        $name = $lbSelected.Items[$i]
        $driver = $db | Where-Object { $_.name -eq $name } | Select-Object -First 1
        if (-not $driver) { continue }
        if ($driver.type -eq 'command') {
            $expanded = $ExecutionContext.InvokeCommand.ExpandString($driver.url)
            $tmpFile = Join-Path -Path $env:TEMP -ChildPath ("drv_install_{0}.ps1" -f ([guid]::NewGuid().ToString()))
            Set-Content -Path $tmpFile -Value $expanded -Encoding UTF8 -Force
            try { Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmpFile`"" -Wait } finally { Remove-Item -Path $tmpFile -ErrorAction SilentlyContinue }
        } else {
            try { Start-Process -FilePath $driver.url } catch { }
        }
    }
})

$btnExit.Add_Click({ $form.Close() })

$lbDevices.Add_DoubleClick({
    $sel = $lbDevices.SelectedItem
    if (-not $sel) { return }
    $name = ($sel -split ':',2)[1].Trim()
    $matches = $db | Where-Object { $name -match $_.pattern }
    $lbSelected.Items.Clear()
    foreach ($m in $matches) { $lbSelected.Items.Add($m.name) | Out-Null }
})

$form.Add_Shown({ param($s,$e) $form.Activate() })
[void]$form.ShowDialog()
