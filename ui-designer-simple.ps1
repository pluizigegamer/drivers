Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Simple drag-only UI designer
$script:currentTool = 'Select'
$script:dragging = $false
$script:dragControl = $null
$script:dragOffset = $null
$script:counters = @{}

function New-UniqueName { param($type) if (-not $script:counters[$type]) { $script:counters[$type] = 0 } $script:counters[$type] += 1; return "$($type)$($script:counters[$type])" }

function Show-InputBox($title,$prompt,$default) {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = $title
    $dlg.Size = New-Object System.Drawing.Size(400,140)
    $dlg.StartPosition = 'CenterParent'
    $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $prompt; $lbl.AutoSize = $true; $lbl.Top = 8; $lbl.Left = 8
    $tb = New-Object System.Windows.Forms.TextBox; $tb.Text = $default; $tb.Width = 360; $tb.Left = 8; $tb.Top = 30
    $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = 'OK'; $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK; $btnOk.Left = 220; $btnOk.Top = 64
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = 'Cancel'; $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $btnCancel.Left = 300; $btnCancel.Top = 64
    $dlg.Controls.AddRange(@($lbl,$tb,$btnOk,$btnCancel))
    $dlg.AcceptButton = $btnOk; $dlg.CancelButton = $btnCancel
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $tb.Text } else { return $null }
}

# Main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Simple UI Designer'
$form.Size = New-Object System.Drawing.Size(1000,700)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI',9)
$form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

# Top toolbar$top = New-Object System.Windows.Forms.FlowLayoutPanel
$top.Dock = 'Top'
$top.Height = 40
$top.Padding = 6
$top.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)

$btnNew = New-Object System.Windows.Forms.Button; $btnNew.Text = 'New'; $btnNew.Width = 80
$btnOpen = New-Object System.Windows.Forms.Button; $btnOpen.Text = 'Open'; $btnOpen.Width = 80
$btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = 'Save'; $btnSave.Width = 80
$btnExport = New-Object System.Windows.Forms.Button; $btnExport.Text = 'Export .ps1'; $btnExport.Width = 100
$btnPreview = New-Object System.Windows.Forms.Button; $btnPreview.Text = 'Preview'; $btnPreview.Width = 80
$btnPush = New-Object System.Windows.Forms.Button; $btnPush.Text = 'Push to GitHub'; $btnPush.Width = 110
$top.Controls.AddRange(@($btnNew,$btnOpen,$btnSave,$btnExport,$btnPreview,$btnPush))

# Toolbox (left)
$toolbox = New-Object System.Windows.Forms.Panel
$toolbox.Dock = 'Left'
$toolbox.Width = 140
$toolbox.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)
$flowTools = New-Object System.Windows.Forms.FlowLayoutPanel
$flowTools.Dock = 'Fill'
$flowTools.FlowDirection = 'TopDown'
$flowTools.WrapContents = $false
$flowTools.AutoScroll = $true
$toolbox.Controls.Add($flowTools)

$controls = @('Select','Button','Label','TextBox','ListView','ComboBox','CheckBox')
foreach ($t in $controls) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $t
    $b.Width = 120
    $b.Tag = $t
    $b.BackColor = [System.Drawing.Color]::FromArgb(63,63,70)
    $b.ForeColor = [System.Drawing.Color]::White
    $b.Add_Click({ param($s,$e) $script:currentTool = $s.Tag; $lblStatus.Text = "Tool: $($script:currentTool)" })
    $flowTools.Controls.Add($b)
}

# Canvas
$canvas = New-Object System.Windows.Forms.Panel
$canvas.Dock = 'Fill'
$canvas.AutoScroll = $true
$canvas.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$canvas.BorderStyle = 'FixedSingle'

# Status label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Dock = 'Bottom'
$lblStatus.Height = 22
$lblStatus.Text = 'Ready'
$lblStatus.ForeColor = [System.Drawing.Color]::LightGray

$form.Controls.AddRange(@($top,$toolbox,$canvas,$lblStatus))

# Attach simple drag handlers and delete/double-click text edit
function Attach-Handlers($ctrl) {
    $ctrl.Add_MouseDown({ param($s,$e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $script:dragControl = $s
            $script:dragging = $true
            $mouse = $canvas.PointToClient([System.Windows.Forms.Control]::MousePosition)
            $script:dragOffset = New-Object System.Drawing.Point($mouse.X - $s.Left, $mouse.Y - $s.Top)
        }
    })
    $ctrl.Add_MouseMove({ param($s,$e)
        if ($script:dragging -and $script:dragControl -eq $s) {
            $mouse = $canvas.PointToClient([System.Windows.Forms.Control]::MousePosition)
            $s.Left = [Math]::Max(0, $mouse.X - $script:dragOffset.X)
            $s.Top = [Math]::Max(0, $mouse.Y - $script:dragOffset.Y)
        }
    })
    $ctrl.Add_MouseUp({ param($s,$e) if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $script:dragging = $false; $script:dragControl = $null } })
    $ctrl.Add_DoubleClick({ param($s,$e) $val = Show-InputBox('Edit Text','Text:',$s.Text); if ($val -ne $null) { $s.Text = $val } })
    $cm = New-Object System.Windows.Forms.ContextMenuStrip
    $mi = New-Object System.Windows.Forms.ToolStripMenuItem 'Delete'
    $mi.Add_Click({ param($ss,$ee) $canvas.Controls.Remove($ctrl); $lblStatus.Text = "Deleted $($ctrl.Name)" })
    $cm.Items.Add($mi)
    $ctrl.ContextMenuStrip = $cm
}

# Create control on canvas
function Create-Control([string]$type, [System.Drawing.Point]$pt) {
    $name = New-UniqueName $type
    switch ($type) {
        'Button' { $ctrl = New-Object System.Windows.Forms.Button; $ctrl.Text = 'Button'; $size = New-Object System.Drawing.Size(100,30) }
        'Label' { $ctrl = New-Object System.Windows.Forms.Label; $ctrl.Text = 'Label'; $ctrl.AutoSize = $false; $size = New-Object System.Drawing.Size(100,24) }
        'TextBox' { $ctrl = New-Object System.Windows.Forms.TextBox; $ctrl.Text = ''; $size = New-Object System.Drawing.Size(140,24) }
        'ListView' { $ctrl = New-Object System.Windows.Forms.ListView; $ctrl.View = 'Details'; $ctrl.FullRowSelect = $true; $null = $ctrl.Columns.Add('Col1'); $size = New-Object System.Drawing.Size(200,120) }
        'ComboBox' { $ctrl = New-Object System.Windows.Forms.ComboBox; $null = $ctrl.Items.AddRange(@('One','Two')); $size = New-Object System.Drawing.Size(140,24) }
        'CheckBox' { $ctrl = New-Object System.Windows.Forms.CheckBox; $ctrl.Text = 'Option'; $size = New-Object System.Drawing.Size(120,24) }
        default { $ctrl = New-Object System.Windows.Forms.Label; $ctrl.Text = $type; $size = New-Object System.Drawing.Size(100,24) }
    }
    $ctrl.Name = $name
    $ctrl.Size = $size
    $ctrl.Location = New-Object System.Drawing.Point($pt.X,$pt.Y)
    $ctrl.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
    $ctrl.ForeColor = [System.Drawing.Color]::White
    $ctrl.Font = New-Object System.Drawing.Font('Segoe UI',9)
    $ctrl.Tag = 'designer'
    Attach-Handlers $ctrl
    $canvas.Controls.Add($ctrl)
    $lblStatus.Text = "Added $name"
    return $ctrl
}

$canvas.Add_MouseDown({ param($s,$e)
    if ($script:currentTool -and $script:currentTool -ne 'Select') {
        $pt = $e.Location
        Create-Control $script:currentTool $pt
    } else { $lblStatus.Text = 'Canvas clicked' }
})

# Layout serialization
function Get-LayoutData {
    $arr = @()
    foreach ($c in $canvas.Controls) {
        if ($c.Tag -eq 'designer') {
            $arr += [ordered]@{
                Type = $c.GetType().Name
                Name = $c.Name
                Text = $c.Text
                Left = $c.Left
                Top = $c.Top
                Width = $c.Width
                Height = $c.Height
            }
        }
    }
    return $arr
}

function Save-LayoutToFile([string]$path) {
    $data = Get-LayoutData
    $json = $data | ConvertTo-Json -Depth 6
    Set-Content -Path $path -Value $json -Encoding UTF8 -Force
}

function Load-LayoutFromFile([string]$path) {
    $json = Get-Content -Path $path -Raw | ConvertFrom-Json
    $canvas.Controls.Clear()
    $script:counters = @{}
    foreach ($c in $json) {
        $pt = New-Object System.Drawing.Point($c.Left,$c.Top)
        $new = Create-Control $c.Type $pt
        $added = $canvas.Controls[$new.Name]
        $added.Size = New-Object System.Drawing.Size($c.Width,$c.Height)
        $added.Text = $c.Text
    }
}

# Export to standalone PowerShell script
function Export-LayoutToScript([string]$path) {
    $controls = Get-LayoutData
    $lines = @()
    $lines += "Add-Type -AssemblyName System.Windows.Forms"
    $lines += "Add-Type -AssemblyName System.Drawing"
    $lines += "[System.Windows.Forms.Application]::EnableVisualStyles()"
    $lines += "`$form = New-Object System.Windows.Forms.Form"
    $lines += "`$form.Text = 'Driver Manager - Generated UI'"
    $lines += "`$form.Size = New-Object System.Drawing.Size($($form.Size.Width),$($form.Size.Height))"
    $lines += "`$form.StartPosition = 'CenterScreen'"
    foreach ($c in $controls) {
        $var = $c.Name
        $type = $c.Type
        $txt = ($c.Text -replace "'","''")
        $lines += "`$$var = New-Object System.Windows.Forms.$type"
        $lines += "`$$var.Name = '$($c.Name)'"
        $lines += "`$$var.Text = '$txt'"
        $lines += "`$$var.Size = New-Object System.Drawing.Size($($c.Width),$($c.Height))"
        $lines += "`$$var.Location = New-Object System.Drawing.Point($($c.Left),$($c.Top))"
        $lines += "[void]`$form.Controls.Add(`$$var)"
    }
    $lines += "[void]`$form.ShowDialog()"
    try { $lines -join "`r`n" | Set-Content -Path $path -Encoding UTF8 -Force; return $true } catch { return $false }
}

# Buttons handlers
$btnNew.Add_Click({ $canvas.Controls.Clear(); $script:counters = @{}; $lblStatus.Text = 'New layout' })
$btnOpen.Add_Click({ $ofd = New-Object System.Windows.Forms.OpenFileDialog; $ofd.Filter = 'Layout (*.json)|*.json|All files|*.*'; if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { try { Load-LayoutFromFile $ofd.FileName; $lblStatus.Text = 'Loaded ' + $ofd.FileName } catch { $lblStatus.Text = 'Load failed: ' + $_.Exception.Message } } })
$btnSave.Add_Click({ $sfd = New-Object System.Windows.Forms.SaveFileDialog; $sfd.Filter = 'Layout (*.json)|*.json|All files|*.*'; $sfd.FileName = 'layout.json'; if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Save-LayoutToFile $sfd.FileName; $lblStatus.Text = 'Saved ' + $sfd.FileName } })
$btnExport.Add_Click({ $sfd = New-Object System.Windows.Forms.SaveFileDialog; $sfd.Filter = 'PowerShell script (*.ps1)|*.ps1|All files|*.*'; $sfd.FileName = 'driver-manager.generated.ps1'; if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { if (Export-LayoutToScript $sfd.FileName) { $lblStatus.Text = 'Exported to ' + $sfd.FileName } else { $lblStatus.Text = 'Export failed' } } })
$btnPreview.Add_Click({ $tmp = Join-Path $env:TEMP ("ui-preview-{0}.ps1" -f ([guid]::NewGuid().ToString())); if (Export-LayoutToScript $tmp) { Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tmp); $lblStatus.Text = 'Preview started' } else { $lblStatus.Text = 'Preview failed' } })

# Push to GitHub (asks for token; optional)
$btnPush.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = 'PowerShell script (*.ps1)|*.ps1|All files|*.*'
    $sfd.FileName = 'driver-manager.generated.ps1'
    if ($sfd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    if (-not (Export-LayoutToScript $sfd.FileName)) { $lblStatus.Text = 'Export failed'; return }
    $dlg = New-Object System.Windows.Forms.Form; $dlg.Text = 'Push to GitHub'; $dlg.Size = New-Object System.Drawing.Size(420,260); $tbl=New-Object System.Windows.Forms.TableLayoutPanel; $tbl.Dock='Fill'; $tbl.ColumnCount=2; $tbl.RowCount=4; $tbl.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,30))); $tbl.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,70)));
    $labels=@('Owner','Repo','Path','Token'); $defaults=@('pluizigegamer','drivers','driver-manager.ps1',''); $boxes=@();
    for ($i=0;$i -lt $labels.Count;$i++) { $l=New-Object System.Windows.Forms.Label; $l.Text=$labels[$i]; $l.TextAlign='MiddleLeft'; $tb=New-Object System.Windows.Forms.TextBox; $tb.Dock='Fill'; $tb.Text=$defaults[$i]; if ($labels[$i] -eq 'Token') { $tb.UseSystemPasswordChar=$true } $tbl.Controls.Add($l,0,$i); $tbl.Controls.Add($tb,1,$i); $boxes+=$tb }
    $btnOk=New-Object System.Windows.Forms.Button; $btnOk.Text='Push'; $btnOk.DialogResult=[System.Windows.Forms.DialogResult]::OK; $btnCancel=New-Object System.Windows.Forms.Button; $btnCancel.Text='Cancel'; $btnCancel.DialogResult=[System.Windows.Forms.DialogResult]::Cancel; $flow=New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock='Bottom'; $flow.Controls.AddRange(@($btnOk,$btnCancel)); $dlg.Controls.Add($tbl); $dlg.Controls.Add($flow); $dlg.AcceptButton=$btnOk; $dlg.CancelButton=$btnCancel;
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $info = @{ Owner=$boxes[0].Text; Repo=$boxes[1].Text; Path=$boxes[2].Text; Token=$boxes[3].Text; Branch='main'; Message='Update driver-manager via Simple UI Designer' }
        $api = "https://api.github.com/repos/$($info.Owner)/$($info.Repo)/contents/$($info.Path)"
        $headers = @{ 'User-Agent' = 'PowerShell' }
        if ($info.Token) { $headers.Authorization = "token $($info.Token)" }
        try { $existing = Invoke-RestMethod -Uri $api -Headers $headers -Method Get -ErrorAction Stop; $sha = $existing.sha } catch { $sha = $null }
        $content = Get-Content -Path $sfd.FileName -Raw
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
        $body = @{ message = $info.Message; content = $b64; branch = $info.Branch }
        if ($sha) { $body.sha = $sha }
        $json = $body | ConvertTo-Json -Depth 10
        try { Invoke-RestMethod -Uri $api -Headers $headers -Method Put -Body $json -ContentType 'application/json' -ErrorAction Stop; $lblStatus.Text = 'Pushed to GitHub' } catch { $lblStatus.Text = 'Push failed: ' + $_.Exception.Message }
    }
})

[void]$form.ShowDialog()
