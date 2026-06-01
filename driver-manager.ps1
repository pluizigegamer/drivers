# Driver Manager - Rewritten Responsive Dark UI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Colors
$Colors = @{
    BG_Dark = [System.Drawing.Color]::FromArgb(20,20,20)
    BG_Panel = [System.Drawing.Color]::FromArgb(30,30,30)
    BG_Input = [System.Drawing.Color]::FromArgb(40,40,40)
    Text_Primary = [System.Drawing.Color]::FromArgb(240,240,240)
    Text_Secondary = [System.Drawing.Color]::FromArgb(170,170,170)
    Accent = [System.Drawing.Color]::FromArgb(58,150,221)
    AccentHover = [System.Drawing.Color]::FromArgb(75,175,255)
}

# DB path
$DBDir = Join-Path -Path $env:APPDATA -ChildPath 'DriverManager'
if (-not (Test-Path $DBDir)) { New-Item -Path $DBDir -ItemType Directory -Force | Out-Null }
$DBPath = Join-Path -Path $DBDir -ChildPath 'drivers-db.json'

function Load-Database() {
    if (-not (Test-Path $DBPath)) { return @() }
    try { Get-Content -Path $DBPath -Raw | ConvertFrom-Json } catch { @() }
}
function Save-Database($db) { $db | ConvertTo-Json -Depth 5 | Set-Content -Path $DBPath -Encoding UTF8 }

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

# Helper controls
function New-AccentButton($text) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Height = 36
    $b.Font = New-Object System.Drawing.Font('Segoe UI',9)
    $b.FlatStyle = 'Flat'
    $b.ForeColor = $Colors.Text_Primary
    $b.BackColor = $Colors.Accent
    $b.FlatAppearance.BorderColor = $Colors.Accent
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Tag = @{ Normal = $Colors.Accent; Hover = $Colors.AccentHover }
    $b.Add_MouseEnter({ param($s,$e) $s.BackColor = $s.Tag.Hover })
    $b.Add_MouseLeave({ param($s,$e) $s.BackColor = $s.Tag.Normal })
    return $b
}
function New-PanelList($multiselect = $false) {
    $lb = New-Object System.Windows.Forms.ListBox
    $lb.Dock = 'Fill'
    $lb.BackColor = $Colors.BG_Input
    $lb.ForeColor = $Colors.Text_Primary
    $lb.BorderStyle = 'None'
    $lb.Font = New-Object System.Drawing.Font('Segoe UI',10)
    $lb.SelectionMode = $([System.Windows.Forms.SelectionMode]::MultiExtended)
    return $lb
}

# Ensure sample DB exists
if (-not (Test-Path $DBPath)) {
    $sample = @(
        @{ id='1'; name='Global NVIDIA Driver'; pattern='NVIDIA|GeForce|RTX|GTX'; url='https://us.download.nvidia.com/nvapp/client/11.0.7.247/NVIDIA_app_v11.0.7.247.exe'; type='url'; category='GPU' },
        @{ id='2'; name='AMD Installer (command)'; pattern='AMD|Radeon|RX|Vega'; url='Invoke-WebRequest -Uri "https://drivers.amd.com/drivers/installer/26.10/whql/amd-software-adrenalin-edition-26.5.2-minimalsetup-260513_web.exe" -OutFile "$env:USERPROFILE\\Downloads\\amd_driver.exe"; Start-Process -FilePath "$env:USERPROFILE\\Downloads\\amd_driver.exe" -Wait'; type='command'; category='GPU' }
    )
    Save-Database $sample
}

# Load DB
$db = Load-Database

# Main Form - responsive
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Driver Manager'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(1100,700)
$form.MinimumSize = New-Object System.Drawing.Size(800,500)
$form.BackColor = $Colors.BG_Dark
$form.Font = New-Object System.Drawing.Font('Segoe UI',10)

# Header (top)
$header = New-Object System.Windows.Forms.Panel
$header.Dock = 'Top'
$header.Height = 64
$header.BackColor = $Colors.BG_Panel
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = 'Driver Manager'
$lblTitle.Font = New-Object System.Drawing.Font('Segoe UI',16,[System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $Colors.Accent
$lblTitle.AutoSize = $false
$lblTitle.Dock = 'Fill'
$lblTitle.TextAlign = 'MiddleLeft'
$lblTitle.Padding = New-Object System.Windows.Forms.Padding(16,0,0,0)
$header.Controls.Add($lblTitle)

# Footer (bottom)
$footer = New-Object System.Windows.Forms.Panel
$footer.Dock = 'Bottom'
$footer.Height = 60
$footer.BackColor = $Colors.BG_Panel
$footerPadding = New-Object System.Windows.Forms.Padding(10)
$footer.Padding = $footerPadding

$flowFooter = New-Object System.Windows.Forms.FlowLayoutPanel
$flowFooter.Dock = 'Fill'
$flowFooter.FlowDirection = 'LeftToRight'
$flowFooter.WrapContents = $false
$flowFooter.AutoSize = $false
$flowFooter.Padding = New-Object System.Windows.Forms.Padding(0)

$btnScan = New-AccentButton 'Scan Devices'
$btnInstall = New-AccentButton 'Download & Install Selected'
$btnExit = New-AccentButton 'Exit'
$btnExit.BackColor = [System.Drawing.Color]::FromArgb(200,60,60)
$btnExit.Tag = @{ Normal = [System.Drawing.Color]::FromArgb(200,60,60); Hover = [System.Drawing.Color]::FromArgb(230,90,90) }

$flowFooter.Controls.AddRange(@($btnScan, $btnInstall))

# right-aligned exit buttonn$panelRight = New-Object System.Windows.Forms.Panel
$panelRight.Dock = 'Right'
$panelRight.Width = 120
$panelRight.Padding = New-Object System.Windows.Forms.Padding(0)
$panelRight.Controls.Add($btnExit)
$btnExit.Dock = 'Fill'

$footer.Controls.Add($panelRight)
$footer.Controls.Add($flowFooter)

# Content - 3 columns
$content = New-Object System.Windows.Forms.TableLayoutPanel
$content.Dock = 'Fill'
$content.ColumnCount = 3
$content.RowCount = 1
$content.Padding = New-Object System.Windows.Forms.Padding(12)
$content.ColumnStyles.Clear()
$content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,34)))
$content.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))

# Left column - Selectedn$leftPanel = New-Object System.Windows.Forms.Paneln$leftPanel.Dock = 'Fill'
$leftPanel.BackColor = $Colors.BG_Panel
$lblSel = New-Object System.Windows.Forms.Label; $lblSel.Text='Selected Drivers'; $lblSel.Dock='Top'; $lblSel.Height=28; $lblSel.ForeColor=$Colors.Text_Primary; $lblSel.Font = New-Object System.Drawing.Font('Segoe UI',11,[System.Drawing.FontStyle]::Bold)
$listSelected = New-PanelList
$listSelected.Dock = 'Fill'
$btnRemove = New-AccentButton 'Remove Selected'
$btnRemove.Height = 34; $btnRemove.Dock = 'Bottom'
$leftPanel.Controls.Add($listSelected); $leftPanel.Controls.Add($btnRemove); $leftPanel.Controls.Add($lblSel)

# Middle column - Database
$midPanel = New-Object System.Windows.Forms.Panel
$midPanel.Dock = 'Fill'
$midPanel.BackColor = $Colors.BG_Panel
$lblDB = New-Object System.Windows.Forms.Label; $lblDB.Text='Available Drivers'; $lblDB.Dock='Top'; $lblDB.Height=28; $lblDB.ForeColor=$Colors.Text_Primary; $lblDB.Font = New-Object System.Drawing.Font('Segoe UI',11,[System.Drawing.FontStyle]::Bold)
$listDB = New-PanelList
$listDB.Dock = 'Fill'
$btnAdd = New-AccentButton 'Add to Selection'
$btnAdd.Height = 34; $btnAdd.Dock = 'Bottom'
$midPanel.Controls.Add($listDB); $midPanel.Controls.Add($btnAdd); $midPanel.Controls.Add($lblDB)

# Right column - Devices
$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Dock = 'Fill'
$rightPanel.BackColor = $Colors.BG_Panel
$lblDevices = New-Object System.Windows.Forms.Label; $lblDevices.Text='Detected Devices'; $lblDevices.Dock='Top'; $lblDevices.Height=28; $lblDevices.ForeColor=$Colors.Text_Primary; $lblDevices.Font = New-Object System.Drawing.Font('Segoe UI',11,[System.Drawing.FontStyle]::Bold)
$listDevices = New-PanelList
$listDevices.Dock = 'Fill'
$rightPanel.Controls.Add($listDevices); $rightPanel.Controls.Add($lblDevices)

$content.Controls.Add($leftPanel,0,0)
$content.Controls.Add($midPanel,1,0)
$content.Controls.Add($rightPanel,2,0)

# Add controls to form in order: header, footer, content (footer added before content to reserve bottom space)
$form.Controls.Add($header)
$form.Controls.Add($footer)
$form.Controls.Add($content)

# Functions to refresh lists
function Refresh-DBList() {
    $listDB.Items.Clear()
    foreach ($d in $db) { $listDB.Items.Add($d.name) | Out-Null }
}
function Refresh-DeviceList() {
    $listDevices.Items.Clear()
    $devs = Detect-Devices
    foreach ($dv in $devs) { $listDevices.Items.Add("$($dv.Type): $($dv.Name)") | Out-Null }
}
Refresh-DBList; Refresh-DeviceList()

# Events
$btnScan.Add_Click({ Refresh-DeviceList })
$btnAdd.Add_Click({ foreach ($i in $listDB.SelectedItems) { $listSelected.Items.Add($i) | Out-Null } })
$btnRemove.Add_Click({ for ($i = $listSelected.Items.Count - 1; $i -ge 0; $i--) { if ($listSelected.SelectedIndices -contains $i) { $listSelected.Items.RemoveAt($i) } } })

$btnInstall.Add_Click({
    if ($listSelected.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show('No drivers selected','Info') | Out-Null; return }
    foreach ($name in $listSelected.Items) {
        $driver = $db | Where-Object { $_.name -eq $name } | Select-Object -First 1
        if (-not $driver) { continue }
        if ($driver.type -eq 'command') {
            $expanded = $ExecutionContext.InvokeCommand.ExpandString($driver.url)
            $tmp = Join-Path $env:TEMP ("drv_{0}.ps1" -f ([guid]::NewGuid().ToString()))
            Set-Content -Path $tmp -Value $expanded -Encoding UTF8 -Force
            try { Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmp`"" -Wait } finally { Remove-Item -Path $tmp -ErrorAction SilentlyContinue }
        } else {
            try { Start-Process -FilePath $driver.url } catch { }
        }
    }
})

$listDevices.Add_DoubleClick({
    $sel = $listDevices.SelectedItem
    if (-not $sel) { return }
    $name = ($sel -split ':',2)[1].Trim()
    $matches = $db | Where-Object { $name -match $_.pattern }
    $listSelected.Items.Clear()
    foreach ($m in $matches) { $listSelected.Items.Add($m.name) | Out-Null }
})

$btnExit.Add_Click({ $form.Close() })

# Show form
[void]$form.ShowDialog()
