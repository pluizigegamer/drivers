# Driver Manager - Clean UI (fresh file)
# Minimal default WinForms UI. If this still shows the old UI, run this exact file's raw URL.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

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

# Ensure DB
if (-not (Test-Path $DBPath)) {
    $sample = @(
        @{ id='1'; name='Global NVIDIA Driver'; pattern='NVIDIA|GeForce|RTX|GTX'; url='https://us.download.nvidia.com/nvapp/client/11.0.7.247/NVIDIA_app_v11.0.7.247.exe'; type='url'; category='GPU' }
    )
    Save-Database $sample
}
$db = Load-Database

# Simple Form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Driver Manager - Clean'
$form.Size = New-Object System.Drawing.Size(900,600)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI',10)

$layout = New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock = 'Fill'
$layout.ColumnCount = 3
$layout.RowCount = 1
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,34)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$form.Controls.Add($layout)

# Selected
$selPanel = New-Object System.Windows.Forms.Panel; $selPanel.Dock='Fill'
$selLabel = New-Object System.Windows.Forms.Label; $selLabel.Text='Selected Drivers'; $selLabel.Dock='Top'
$selList = New-Object System.Windows.Forms.ListBox; $selList.Dock='Fill'
$selPanel.Controls.Add($selList); $selPanel.Controls.Add($selLabel)

# DB
$dbPanel = New-Object System.Windows.Forms.Panel; $dbPanel.Dock='Fill'
$dbLabel = New-Object System.Windows.Forms.Label; $dbLabel.Text='Available Drivers'; $dbLabel.Dock='Top'
$dbList = New-Object System.Windows.Forms.ListBox; $dbList.Dock='Fill'
$dbPanel.Controls.Add($dbList); $dbPanel.Controls.Add($dbLabel)

# Devices
$devPanel = New-Object System.Windows.Forms.Panel; $devPanel.Dock='Fill'
$devLabel = New-Object System.Windows.Forms.Label; $devLabel.Text='Detected Devices'; $devLabel.Dock='Top'
$devList = New-Object System.Windows.Forms.ListBox; $devList.Dock='Fill'
$devPanel.Controls.Add($devList); $devPanel.Controls.Add($devLabel)

$layout.Controls.Add($selPanel,0,0)
$layout.Controls.Add($dbPanel,1,0)
$layout.Controls.Add($devPanel,2,0)

# Footer buttons
$footer = New-Object System.Windows.Forms.Panel; $footer.Dock='Bottom'; $footer.Height=52
$btnScan = New-Object System.Windows.Forms.Button; $btnScan.Text='Scan'; $btnScan.Width=90; $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text='Add'; $btnAdd.Width=80
$btnRemove = New-Object System.Windows.Forms.Button; $btnRemove.Text='Remove'; $btnRemove.Width=80; $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text='Install'; $btnInstall.Width=120
$btnExit = New-Object System.Windows.Forms.Button; $btnExit.Text='Exit'; $btnExit.Width=80
$flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock='Fill'
$flow.Controls.AddRange(@($btnScan,$btnAdd,$btnRemove,$btnInstall))
$rightP = New-Object System.Windows.Forms.Panel; $rightP.Dock='Right'; $rightP.Width=100; $rightP.Controls.Add($btnExit); $btnExit.Dock='Fill'
$footer.Controls.Add($rightP); $footer.Controls.Add($flow)
$form.Controls.Add($footer)

# Populate db list
foreach ($d in $db) { $dbList.Items.Add($d.name) | Out-Null }

# Events
$btnScan.Add_Click({ $devList.Items.Clear(); $devs = Detect-Devices(); foreach ($dv in $devs) { $devList.Items.Add("$($dv.Type): $($dv.Name)") | Out-Null } })
$btnAdd.Add_Click({ foreach ($i in $dbList.SelectedItems) { $selList.Items.Add($i) | Out-Null } })
$btnRemove.Add_Click({ for ($i=$selList.Items.Count-1; $i -ge 0; $i--) { if ($selList.SelectedIndices -contains $i) { $selList.Items.RemoveAt($i) } } })
$btnInstall.Add_Click({ if ($selList.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show('No drivers selected','Info') | Out-Null; return }; foreach ($name in $selList.Items) { $driver = $db | Where-Object { $_.name -eq $name } | Select-Object -First 1; if (-not $driver) { continue }; if ($driver.type -eq 'command') { $s = $ExecutionContext.InvokeCommand.ExpandString($driver.url); $tmp = Join-Path $env:TEMP ("drv_{0}.ps1" -f ([guid]::NewGuid().ToString())); Set-Content -Path $tmp -Value $s -Encoding UTF8 -Force; try { Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmp`"" -Wait } finally { Remove-Item -Path $tmp -ErrorAction SilentlyContinue } } else { try { Start-Process -FilePath $driver.url } catch { } } } })
$btnExit.Add_Click({ $form.Close() })

[void]$form.ShowDialog()
