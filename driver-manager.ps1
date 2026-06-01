# Driver Manager - Minimal functional UI (restore)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

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

# ensure sample DB exists
if (-not (Test-Path $DBPath)) {
    $sample = @(
        @{ id='1'; name='Global NVIDIA Driver'; pattern='NVIDIA|GeForce|RTX|GTX'; url='https://us.download.nvidia.com/nvapp/client/11.0.7.247/NVIDIA_app_v11.0.7.247.exe'; type='url'; category='GPU' }
    )
    Save-Database $sample
}

$db = Load-Database

# Form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Driver Manager'
$form.Size = New-Object System.Drawing.Size(1000,700)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI',10)

# Layout panel (3 columns)
$layout = New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock = 'Fill'
$layout.ColumnCount = 3
$layout.RowCount = 1
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,34)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$form.Controls.Add($layout)

# Left - selected
$left = New-Object System.Windows.Forms.Panel
$left.Dock = 'Fill'
$lblLeft = New-Object System.Windows.Forms.Label; $lblLeft.Text = 'Selected Drivers'; $lblLeft.Dock = 'Top'
$lbSelected = New-Object System.Windows.Forms.ListBox; $lbSelected.Dock = 'Fill'
$left.Controls.Add($lbSelected); $left.Controls.Add($lblLeft)

# Middle - DB
$mid = New-Object System.Windows.Forms.Panel
$mid.Dock = 'Fill'
$lblDB = New-Object System.Windows.Forms.Label; $lblDB.Text = 'Available Drivers'; $lblDB.Dock = 'Top'
$lbDB = New-Object System.Windows.Forms.ListBox; $lbDB.Dock = 'Fill'
$mid.Controls.Add($lbDB); $mid.Controls.Add($lblDB)

# Right - Devices
$right = New-Object System.Windows.Forms.Panel
$right.Dock = 'Fill'
$lblDev = New-Object System.Windows.Forms.Label; $lblDev.Text = 'Detected Devices'; $lblDev.Dock = 'Top'
$lbDevices = New-Object System.Windows.Forms.ListBox; $lbDevices.Dock = 'Fill'
$right.Controls.Add($lbDevices); $right.Controls.Add($lblDev)

$layout.Controls.Add($left,0,0)
$layout.Controls.Add($mid,1,0)
$layout.Controls.Add($right,2,0)

# Footer buttons
$footer = New-Object System.Windows.Forms.Panel
$footer.Dock = 'Bottom'
$footer.Height = 56
$scanBtn = New-Object System.Windows.Forms.Button; $scanBtn.Text='Scan'; $scanBtn.Width=100
$addBtn = New-Object System.Windows.Forms.Button; $addBtn.Text='Add'; $addBtn.Width=100
$removeBtn = New-Object System.Windows.Forms.Button; $removeBtn.Text='Remove'; $removeBtn.Width=100
$installBtn = New-Object System.Windows.Forms.Button; $installBtn.Text='Install Selected'; $installBtn.Width=140
$exitBtn = New-Object System.Windows.Forms.Button; $exitBtn.Text='Exit'; $exitBtn.Width=90

$flow = New-Object System.Windows.Forms.FlowLayoutPanel
$flow.Dock = 'Fill'
$flow.Controls.AddRange(@($scanBtn,$addBtn,$removeBtn,$installBtn))
$rightPanel = New-Object System.Windows.Forms.Panel; $rightPanel.Dock='Right'; $rightPanel.Width=100
$rightPanel.Controls.Add($exitBtn); $exitBtn.Dock='Fill'
$footer.Controls.Add($rightPanel); $footer.Controls.Add($flow)
$form.Controls.Add($footer)

# populate db list
foreach ($d in $db) { $lbDB.Items.Add($d.name) | Out-Null }

# Eventsn$scanBtn.Add_Click({
    $lbDevices.Items.Clear()
    $devs = Detect-Devices()
    foreach ($dv in $devs) { $lbDevices.Items.Add("$($dv.Type): $($dv.Name)") | Out-Null }
})

$addBtn.Add_Click({ foreach ($i in $lbDB.SelectedItems) { $lbSelected.Items.Add($i) | Out-Null } })

$removeBtn.Add_Click({ for ($i=$lbSelected.Items.Count-1; $i -ge 0; $i--) { if ($lbSelected.SelectedIndices -contains $i) { $lbSelected.Items.RemoveAt($i) } } })

$installBtn.Add_Click({
    if ($lbSelected.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show('No drivers selected','Info') | Out-Null; return }
    foreach ($name in $lbSelected.Items) {
        $driver = $db | Where-Object { $_.name -eq $name } | Select-Object -First 1
        if (-not $driver) { continue }
        if ($driver.type -eq 'command') {
            $script = $ExecutionContext.InvokeCommand.ExpandString($driver.url)
            $tmp = Join-Path $env:TEMP ("drv_{0}.ps1" -f ([guid]::NewGuid().ToString()))
            Set-Content -Path $tmp -Value $script -Encoding UTF8 -Force
            Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tmp) -Wait
            Remove-Item -Path $tmp -ErrorAction SilentlyContinue
        } else {
            try { Start-Process -FilePath $driver.url } catch { }
        }
    }
})

$exitBtn.Add_Click({ $form.Close() })

[void]$form.ShowDialog()
