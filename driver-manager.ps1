# Driver Manager - Minimal Simple UI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Database path
$DBDir = Join-Path -Path $env:APPDATA -ChildPath 'DriverManager'
if (-not (Test-Path $DBDir)) { New-Item -Path $DBDir -ItemType Directory -Force | Out-Null }
$DBPath = Join-Path -Path $DBDir -ChildPath 'drivers-db.json'

function Load-Database() { if (-not (Test-Path $DBPath)) { return @() } ; try { Get-Content -Path $DBPath -Raw | ConvertFrom-Json } catch { @() } }
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

# Ensure sample DB
if (-not (Test-Path $DBPath)) {
    $sample = @(
        @{ id='1'; name='Global NVIDIA Driver'; pattern='NVIDIA|GeForce|RTX|GTX'; url='https://us.download.nvidia.com/nvapp/client/11.0.7.247/NVIDIA_app_v11.0.7.247.exe'; type='url'; category='GPU' },
        @{ id='2'; name='AMD Installer (command)'; pattern='AMD|Radeon|RX|Vega'; url='Invoke-WebRequest -Uri "https://drivers.amd.com/drivers/installer/26.10/whql/amd-software-adrenalin-edition-26.5.2-minimalsetup-260513_web.exe" -OutFile "$env:USERPROFILE\\Downloads\\amd_driver.exe"; Start-Process -FilePath "$env:USERPROFILE\\Downloads\\amd_driver.exe" -Wait'; type='command'; category='GPU' }
    )
    Save-Database $sample
}

$db = Load-Database

# Simple Form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Driver Manager - Simple'
$form.Size = New-Object System.Drawing.Size(1000,600)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI',10)

# Layout: 3 columns
$layout = New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock = 'Fill'
$layout.ColumnCount = 3
$layout.RowCount = 1
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,34)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$form.Controls.Add($layout)

# Left - Selected
$left = New-Object System.Windows.Forms.Panel
$left.Dock = 'Fill'
$lblLeft = New-Object System.Windows.Forms.Label; $lblLeft.Text='Selected Drivers'; $lblLeft.Dock='Top'
$lbSelected = New-Object System.Windows.Forms.ListBox; $lbSelected.Dock='Fill'
$left.Controls.Add($lbSelected); $left.Controls.Add($lblLeft)

# Middle - Database
$mid = New-Object System.Windows.Forms.Panel
$mid.Dock = 'Fill'
$lblMid = New-Object System.Windows.Forms.Label; $lblMid.Text='Available Drivers'; $lblMid.Dock='Top'
$lbDB = New-Object System.Windows.Forms.ListBox; $lbDB.Dock='Fill'
$mid.Controls.Add($lbDB); $mid.Controls.Add($lblMid)

# Right - Devices
$right = New-Object System.Windows.Forms.Panel
$right.Dock = 'Fill'
$lblRight = New-Object System.Windows.Forms.Label; $lblRight.Text='Detected Devices'; $lblRight.Dock='Top'
$lbDevices = New-Object System.Windows.Forms.ListBox; $lbDevices.Dock='Fill'
$right.Controls.Add($lbDevices); $right.Controls.Add($lblRight)

$layout.Controls.Add($left,0,0)
$layout.Controls.Add($mid,1,0)
$layout.Controls.Add($right,2,0)

# Footer buttons - simple
$footer = New-Object System.Windows.Forms.Panel
$footer.Dock = 'Bottom'
$footer.Height = 50
$btnScan = New-Object System.Windows.Forms.Button; $btnScan.Text='Scan Devices'; $btnScan.Width=120; $btnScan.Height=32
$btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text='Add ->'; $btnAdd.Width=90; $btnAdd.Height=32
$btnRemove = New-Object System.Windows.Forms.Button; $btnRemove.Text='Remove'; $btnRemove.Width=90; $btnRemove.Height=32
$btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text='Install Selected'; $btnInstall.Width=140; $btnInstall.Height=32
$btnExit = New-Object System.Windows.Forms.Button; $btnExit.Text='Exit'; $btnExit.Width=80; $btnExit.Height=32

$footFlow = New-Object System.Windows.Forms.FlowLayoutPanel
$footFlow.Dock = 'Fill'
$footFlow.Controls.AddRange(@($btnScan,$btnAdd,$btnRemove,$btnInstall))
$rightMost = New-Object System.Windows.Forms.Panel; $rightMost.Dock='Right'; $rightMost.Width=100; $rightMost.Controls.Add($btnExit); $btnExit.Dock='Fill'
$footer.Controls.Add($rightMost); $footer.Controls.Add($footFlow)
$form.Controls.Add($footer)

# Fill DB listnforeach ($d in $db) { $lbDB.Items.Add($d.name) | Out-Null }

# Eventsn$btnScan.Add_Click({ $lbDevices.Items.Clear(); $devs = Detect-Devices; foreach ($dv in $devs) { $lbDevices.Items.Add("$($dv.Type): $($dv.Name)") | Out-Null } })
$btnAdd.Add_Click({ foreach ($i in $lbDB.SelectedItems) { $lbSelected.Items.Add($i) | Out-Null } })
$btnRemove.Add_Click({ for ($i = $lbSelected.Items.Count - 1; $i -ge 0; $i--) { if ($lbSelected.SelectedIndices -contains $i) { $lbSelected.Items.RemoveAt($i) } } })
$btnInstall.Add_Click({ if ($lbSelected.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show('No drivers selected','Info') | Out-Null; return }; foreach ($name in $lbSelected.Items) { $driver = $db | Where-Object { $_.name -eq $name } | Select-Object -First 1; if (-not $driver) { continue }; if ($driver.type -eq 'command') { $expanded = $ExecutionContext.InvokeCommand.ExpandString($driver.url); $tmp = Join-Path $env:TEMP ("drv_{0}.ps1" -f ([guid]::NewGuid().ToString())); Set-Content -Path $tmp -Value $expanded -Encoding UTF8 -Force; try { Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmp`"" -Wait } finally { Remove-Item -Path $tmp -ErrorAction SilentlyContinue } } else { try { Start-Process -FilePath $driver.url } catch { } } } })
$btnExit.Add_Click({ $form.Close() })

[void]$form.ShowDialog()
