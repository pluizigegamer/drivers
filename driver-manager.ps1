# Driver Manager (simplified, robust rewrite)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Colors (dark theme)
$C = [ordered]@{
    Background = [System.Drawing.Color]::FromArgb(30,30,30)
    Foreground = [System.Drawing.Color]::FromArgb(230,230,230)
    Accent     = [System.Drawing.Color]::FromArgb(60,63,65)
    ButtonBG   = [System.Drawing.Color]::FromArgb(45,45,48)
    ButtonHover= [System.Drawing.Color]::FromArgb(70,70,72)
}

# Database path
$DBDir = Join-Path -Path $env:APPDATA -ChildPath 'DriverManager'
if (-not (Test-Path $DBDir)) { New-Item -Path $DBDir -ItemType Directory -Force | Out-Null }
$DBPath = Join-Path -Path $DBDir -ChildPath 'drivers-db.json'

function Save-Database($db) {
    $db | ConvertTo-Json -Depth 5 | Set-Content -Path $DBPath -Encoding UTF8
}
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

function New-CustomButton($text) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.FlatStyle = 'Flat'
    $b.ForeColor = $C.Foreground
    $b.BackColor = $C.ButtonBG
    $b.Tag = @{ Normal = $C.ButtonBG; Hover = $C.ButtonHover }
    $b.Add_MouseEnter({ param($s,$e) $s.BackColor = $s.Tag.Hover })
    $b.Add_MouseLeave({ param($s,$e) $s.BackColor = $s.Tag.Normal })
    return $b
}

# Build UI
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Driver Manager'
$form.Size = New-Object System.Drawing.Size(1000,700)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $C.Background
$form.ForeColor = $C.Foreground

$tl = New-Object System.Windows.Forms.TableLayoutPanel
$tl.Dock = 'Fill'
$tl.ColumnCount = 3
$tl.RowCount = 1
$tl.ColumnStyles.Add( (New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30)))
$tl.ColumnStyles.Add( (New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 40)))
$tl.ColumnStyles.Add( (New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30)))
$tl.RowStyles.Add( (New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
$form.Controls.Add($tl)

# Left: Selected drivers (to install)
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Dock = 'Fill'
$lbSelected = New-Object System.Windows.Forms.ListBox
$lbSelected.Dock = 'Fill'
$leftPanel.Controls.Add($lbSelected)

# Middle: Database
$midPanel = New-Object System.Windows.Forms.Panel
$midPanel.Dock = 'Fill'
$lbDatabase = New-Object System.Windows.Forms.ListBox
$lbDatabase.Dock = 'Fill'
$midPanel.Controls.Add($lbDatabase)

# Right: Detected devices
$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Dock = 'Fill'
$lbDevices = New-Object System.Windows.Forms.ListBox
$lbDevices.Dock = 'Fill'
$rightPanel.Controls.Add($lbDevices)

$tl.Controls.Add($leftPanel,0,0)
$tl.Controls.Add($midPanel,1,0)
$tl.Controls.Add($rightPanel,2,0)

# Bottom controls
$flow = New-Object System.Windows.Forms.FlowLayoutPanel
$flow.Dock = 'Bottom'
$flow.Height = 48
$flow.BackColor = $C.Accent
$form.Controls.Add($flow)

$btnScan = New-CustomButton 'Scan Devices'
$btnAdd = New-CustomButton 'Add Selected'
$btnInstall = New-CustomButton 'Download / Install'
$btnExit = New-CustomButton 'Exit'
$flow.Controls.AddRange(@($btnScan,$btnAdd,$btnInstall,$btnExit))

# Load DB and populate database list
$db = Load-Database
function Refresh-DatabaseList() {
    $lbDatabase.Items.Clear()
    foreach ($d in $db) { $lbDatabase.Items.Add("$($d.name) [$($d.category)]") | Out-Null }
}
Refresh-DatabaseList

function Refresh-DeviceList() {
    $lbDevices.Items.Clear()
    $devs = Detect-Devices
    foreach ($dv in $devs) { $lbDevices.Items.Add("$($dv.Type): $($dv.Name)") | Out-Null }
}
Refresh-DeviceList

$btnScan.Add_Click({ Refresh-DeviceList })
$btnAdd.Add_Click({
    foreach ($i in $lbDatabase.SelectedItems) {
        $lbSelected.Items.Add($i) | Out-Null
    }
})

$btnInstall.Add_Click({
    if ($lbSelected.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show('No drivers selected','Info') | Out-Null; return }
    for ($i=0; $i -lt $lbSelected.Items.Count; $i++) {
        $sel = $lbSelected.Items[$i]
        # find by name prefix
        $name = ($sel -split '\s\[')[0]
        $driver = $db | Where-Object { $_.name -eq $name } | Select-Object -First 1
        if (-not $driver) { continue }
        if ($driver.type -eq 'command') {
            $expanded = $ExecutionContext.InvokeCommand.ExpandString($driver.url)
            $tmpFile = Join-Path -Path $env:TEMP -ChildPath ("drv_install_{0}.ps1" -f ([guid]::NewGuid().ToString()))
            Set-Content -Path $tmpFile -Value $expanded -Encoding UTF8 -Force
            try { Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmpFile`"" -Wait } finally { Remove-Item -Path $tmpFile -ErrorAction SilentlyContinue }
        } else {
            try { Start-Process -FilePath $driver.url } catch { [System.Windows.Forms.MessageBox]::Show("Failed to open: $($driver.url)", 'Error') | Out-Null }
        }
    }
})

$btnExit.Add_Click({ $form.Close() })

# Double-click on device: try to find matching drivers
$lbDevices.Add_DoubleClick({
    $sel = $lbDevices.SelectedItem
    if (-not $sel) { return }
    $name = ($sel -split ':',2)[1].Trim()
    $matches = $db | Where-Object { $name -match ($_ .pattern) }
    $lbSelected.Items.Clear()
    foreach ($m in $matches) { $lbSelected.Items.Add("$($m.name) [$($m.category)]") | Out-Null }
})

$form.Add_Shown({ param($s,$e) $form.Activate() })
[void]$form.ShowDialog()
