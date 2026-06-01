# ui-designer-wysiwyg.ps1 - Full WYSIWYG UI Designer for driver-manager
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Script state
$script:counters = @{}
$script:currentTool = 'Select'
$script:dragging = $false
$script:resizing = $false
$script:dragControl = $null
$script:dragOffset = $null
$script:resizeStart = $null
$script:origSize = $null

# Helper: unique names
function New-UniqueName { param($type) if (-not $script:counters[$type]) { $script:counters[$type] = 0 } $script:counters[$type] += 1; return "$($type)$($script:counters[$type])" }

# Main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'UI Designer - driver-manager (WYSIWYG)'
$form.Size = New-Object System.Drawing.Size(1200,800)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI',9)
$form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

# Toolbar
$toolbar = New-Object System.Windows.Forms.ToolStrip
$toolbar.Dock = 'Top'
$tsNew = New-Object System.Windows.Forms.ToolStripButton 'New'
$tsOpen = New-Object System.Windows.Forms.ToolStripButton 'Open Layout'
$tsSaveLocal = New-Object System.Windows.Forms.ToolStripButton 'Save Layout'
$tsExport = New-Object System.Windows.Forms.ToolStripButton 'Export .ps1'
$tsPush = New-Object System.Windows.Forms.ToolStripButton 'Export & Push'
$tsPreview = New-Object System.Windows.Forms.ToolStripButton 'Preview'
$toolbar.Items.AddRange(@($tsNew,$tsOpen,$tsSaveLocal,$tsExport,$tsPush,$tsPreview))

# Toolbox (left)
$toolbox = New-Object System.Windows.Forms.Panel
$toolbox.Dock = 'Left'
$toolbox.Width = 160
$toolbox.Padding = 6
$toolbox.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)
$tbFlow = New-Object System.Windows.Forms.FlowLayoutPanel
$tbFlow.Dock = 'Fill'
$tbFlow.FlowDirection = 'TopDown'
$tbFlow.AutoScroll = $true
$toolbox.Controls.Add($tbFlow)

$types = @('Select','Button','Label','TextBox','ListView','ComboBox','CheckBox','Panel','PictureBox','GroupBox','NumericUpDown')
foreach ($t in $types) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $t
    $btn.Width = 120
    $btn.Tag = $t
    $btn.BackColor = [System.Drawing.Color]::FromArgb(63,63,70)
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Add_Click({ param($s,$e) $script:currentTool = $s.Tag; $lblStatus.Text = "Tool: $($script:currentTool)" })
    $tbFlow.Controls.Add($btn)
}

# Canvas (center)
$canvas = New-Object System.Windows.Forms.Panel
$canvas.Dock = 'Fill'
$canvas.AutoScroll = $true
$canvas.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$canvas.BorderStyle = 'FixedSingle'

# Property editor (right)
$propPanel = New-Object System.Windows.Forms.Panel
$propPanel.Dock = 'Right'
$propPanel.Width = 320
$propPanel.BackColor = [System.Drawing.Color]::FromArgb(37,37,38)
$propertyGrid = New-Object System.Windows.Forms.PropertyGrid
$propertyGrid.Dock = 'Fill'
$propertyGrid.HelpVisible = $true
$propPanel.Controls.Add($propertyGrid)

# Status strip
$status = New-Object System.Windows.Forms.StatusStrip
$lblStatus = New-Object System.Windows.Forms.ToolStripStatusLabel
$lblStatus.Text = 'Ready'
$status.Items.Add($lblStatus)

# Add controls to form (order matters for Docking)
$form.Controls.AddRange(@($toolbar,$toolbox,$propPanel,$canvas,$status))

# Attach handlers to a new control (move/resize/select/context)
function Attach-Handlers([System.Windows.Forms.Control]$ctrl) {
    $ctrl.Cursor = [System.Windows.Forms.Cursors]::SizeAll
    $ctrl.Add_MouseDown({ param($s,$e)
        $script:dragControl = $s
        $script:dragging = $true
        $mouse = $canvas.PointToClient([System.Windows.Forms.Control]::MousePosition)
        $script:dragOffset = New-Object System.Drawing.Point($mouse.X - $s.Left, $mouse.Y - $s.Top)
        if (($mouse.X - $s.Left) -ge ($s.Width - 10) -and ($mouse.Y - $s.Top) -ge ($s.Height - 10)) {
            $script:resizing = $true
            $script:resizeControl = $s
            $script:resizeStart = $mouse
            $script:origSize = $s.Size
        } else { $script:resizing = $false }
        $propertyGrid.SelectedObject = $s
        $lblStatus.Text = 'Selected: ' + $s.Name
    })
    $ctrl.Add_MouseMove({ param($s,$e)
        if ($script:resizing -and $script:resizeControl -eq $s) {
            $mouse = $canvas.PointToClient([System.Windows.Forms.Control]::MousePosition)
            $newW = [Math]::Max(10, $script:origSize.Width + ($mouse.X - $script:resizeStart.X))
            $newH = [Math]::Max(10, $script:origSize.Height + ($mouse.Y - $script:resizeStart.Y))
            $s.Size = New-Object System.Drawing.Size($newW,$newH)
            $propertyGrid.Refresh()
        } elseif ($script:dragging -and $script:dragControl -eq $s) {
            $mouse = $canvas.PointToClient([System.Windows.Forms.Control]::MousePosition)
            $s.Left = $mouse.X - $script:dragOffset.X
            $s.Top = $mouse.Y - $script:dragOffset.Y
            $propertyGrid.Refresh()
        }
    })
    $ctrl.Add_MouseUp({ param($s,$e) $script:dragging = $false; $script:resizing = $false; $script:dragControl = $null; $script:resizeControl = $null })
    # Context menu
    $cm = New-Object System.Windows.Forms.ContextMenuStrip
    $miDel = New-Object System.Windows.Forms.ToolStripMenuItem 'Delete'
    $miDel.Add_Click({ param($ss,$ee) $canvas.Controls.Remove($ctrl); $propertyGrid.SelectedObject = $null; $lblStatus.Text = 'Deleted' })
    $cm.Items.Add($miDel)
    $ctrl.ContextMenuStrip = $cm
}

# Create control in canvas at location
function Create-Control([string]$type, [System.Drawing.Point]$pt) {
    $name = New-UniqueName $type
    switch ($type) {
        'Button' { $ctrl = New-Object System.Windows.Forms.Button; $ctrl.Text = 'Button'; $size = New-Object System.Drawing.Size(100,30) }
        'Label' { $ctrl = New-Object System.Windows.Forms.Label; $ctrl.Text = 'Label'; $ctrl.AutoSize = $false; $size = New-Object System.Drawing.Size(100,20) }
        'TextBox' { $ctrl = New-Object System.Windows.Forms.TextBox; $ctrl.Text = ''; $size = New-Object System.Drawing.Size(140,24) }
        'ListView' { $ctrl = New-Object System.Windows.Forms.ListView; $ctrl.View = 'Details'; $ctrl.FullRowSelect = $true; $null = $ctrl.Columns.Add('Column1'); $size = New-Object System.Drawing.Size(200,120) }
        'ComboBox' { $ctrl = New-Object System.Windows.Forms.ComboBox; $null = $ctrl.Items.AddRange(@('Item1','Item2')); $size = New-Object System.Drawing.Size(140,24) }
        'CheckBox' { $ctrl = New-Object System.Windows.Forms.CheckBox; $ctrl.Text = 'Check'; $size = New-Object System.Drawing.Size(120,24) }
        'Panel' { $ctrl = New-Object System.Windows.Forms.Panel; $size = New-Object System.Drawing.Size(200,120) }
        'PictureBox' { $ctrl = New-Object System.Windows.Forms.PictureBox; $ctrl.BorderStyle = 'FixedSingle'; $size = New-Object System.Drawing.Size(200,120) }
        'GroupBox' { $ctrl = New-Object System.Windows.Forms.GroupBox; $ctrl.Text = 'Group'; $size = New-Object System.Drawing.Size(220,120) }
        'NumericUpDown' { $ctrl = New-Object System.Windows.Forms.NumericUpDown; $size = New-Object System.Drawing.Size(120,24) }
        default { $ctrl = New-Object System.Windows.Forms.Label; $ctrl.Text = $type; $size = New-Object System.Drawing.Size(100,20) }
    }
    $ctrl.Name = $name
    $ctrl.Size = $size
    $ctrl.Location = New-Object System.Drawing.Point($pt.X,$pt.Y)
    $ctrl.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
    $ctrl.ForeColor = [System.Drawing.Color]::White
    $ctrl.Font = New-Object System.Drawing.Font('Segoe UI',9)
    $ctrl.Tag = 'designer'
    Attach-Handlers $ctrl
    $canvas.Controls.Add($ctrl)
    return $ctrl
}

# Canvas click: add control if a tool is active
$canvas.Add_MouseDown({ param($s,$e)
    if ($script:currentTool -and $script:currentTool -ne 'Select') {
        $pt = $e.Location
        $ctrl = Create-Control $script:currentTool $pt
        $propertyGrid.SelectedObject = $ctrl
        $lblStatus.Text = 'Added ' + $ctrl.Name
    } else { $lblStatus.Text = 'Canvas clicked' }
})

# Layout serialization
function Get-LayoutData {
    $arr = @()
    foreach ($c in $canvas.Controls) {
        if ($c.Tag -eq 'designer') {
            $obj = [ordered]@{
                Type = $c.GetType().Name
                Name = $c.Name
                Text = $c.Text
                Left = $c.Left
                Top = $c.Top
                Width = $c.Width
                Height = $c.Height
                Font = @{ Name = $c.Font.Name; Size = $c.Font.Size; Style = $c.Font.Style.ToString() }
                BackColor = $c.BackColor.ToArgb()
                ForeColor = $c.ForeColor.ToArgb()
                Additional = @{}
            }
            if ($c -is [System.Windows.Forms.ListView]) { $obj.Additional.Columns = @(); foreach ($col in $c.Columns) { $obj.Additional.Columns += $col.Text } }
            $arr += $obj
        }
    }
    return $arr
}

function Save-LayoutToFile([string]$path) {
    $data = Get-LayoutData
    $json = $data | ConvertTo-Json -Depth 6
    Set-Content -Path $path -Value $json -Encoding UTF8 -Force
}

function Load-LayoutFromData($data) {
    $canvas.Controls.Clear()
    $script:counters = @{}
    foreach ($c in $data) {
        $type = $c.Type
        if (-not $script:counters[$type]) { $script:counters[$type] = 0 }
        $script:counters[$type] += 1
        switch ($type) {
            'Button' { $ctrl = New-Object System.Windows.Forms.Button; $ctrl.Text = $c.Text }
            'Label' { $ctrl = New-Object System.Windows.Forms.Label; $ctrl.Text = $c.Text; $ctrl.AutoSize = $false }
            'TextBox' { $ctrl = New-Object System.Windows.Forms.TextBox; $ctrl.Text = $c.Text }
            'ListView' { $ctrl = New-Object System.Windows.Forms.ListView; $ctrl.View = 'Details'; $ctrl.FullRowSelect = $true; $ctrl.Columns.Clear(); if ($c.Additional -and $c.Additional.Columns) { foreach ($col in $c.Additional.Columns) { $null = $ctrl.Columns.Add($col) } } }
            'ComboBox' { $ctrl = New-Object System.Windows.Forms.ComboBox; $ctrl.Items.AddRange(@('Item1')) | Out-Null }
            'CheckBox' { $ctrl = New-Object System.Windows.Forms.CheckBox; $ctrl.Text = $c.Text }
            'Panel' { $ctrl = New-Object System.Windows.Forms.Panel }
            'PictureBox' { $ctrl = New-Object System.Windows.Forms.PictureBox; $ctrl.BorderStyle = 'FixedSingle' }
            'GroupBox' { $ctrl = New-Object System.Windows.Forms.GroupBox; $ctrl.Text = $c.Text }
            'NumericUpDown' { $ctrl = New-Object System.Windows.Forms.NumericUpDown }
            default { $ctrl = New-Object System.Windows.Forms.Label; $ctrl.Text = $c.Text }
        }
        $ctrl.Name = $c.Name
        $ctrl.Size = New-Object System.Drawing.Size($c.Width,$c.Height)
        $ctrl.Location = New-Object System.Drawing.Point($c.Left,$c.Top)
        $ctrl.Font = New-Object System.Drawing.Font($c.Font.Name,[double]$c.Font.Size,[System.Drawing.FontStyle]::Parse($c.Font.Style))
        $bgc = [System.Drawing.Color]::FromArgb([int]$c.BackColor); $ctrl.BackColor = [System.Drawing.Color]::FromArgb($bgc.A,$bgc.R,$bgc.G,$bgc.B)
        $fgc = [System.Drawing.Color]::FromArgb([int]$c.ForeColor); $ctrl.ForeColor = [System.Drawing.Color]::FromArgb($fgc.A,$fgc.R,$fgc.G,$fgc.B)
        $ctrl.Tag = 'designer'
        Attach-Handlers $ctrl
        $canvas.Controls.Add($ctrl)
    }
}

# Open layout
$tsOpen.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = 'UI Layout (*.json)|*.json|All files|*.*'
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try { $json = Get-Content -Path $ofd.FileName -Raw | ConvertFrom-Json; Load-LayoutFromData $json; $lblStatus.Text = 'Loaded layout' } catch { $lblStatus.Text = 'Open failed: ' + $_.Exception.Message }
    }
})

# Save layout local
$tsSaveLocal.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = 'UI Layout (*.json)|*.json|All files|*.*'
    $sfd.FileName = 'layout.json'
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try { Save-LayoutToFile $sfd.FileName; $lblStatus.Text = 'Saved layout to ' + $sfd.FileName } catch { $lblStatus.Text = 'Save failed: ' + $_.Exception.Message }
    }
})

# Export layout to a standalone PowerShell script that recreates the UI
function Export-LayoutToScript([string]$path) {
    $controls = Get-LayoutData
    $formSize = $form.Size
    $lines = @()
    $lines += "Add-Type -AssemblyName System.Windows.Forms"
    $lines += "Add-Type -AssemblyName System.Drawing"
    $lines += "[System.Windows.Forms.Application]::EnableVisualStyles()"
    $lines += "`$form = New-Object System.Windows.Forms.Form"
    $lines += "`$form.Text = 'Driver Manager - Generated UI'"
    $lines += "`$form.Size = New-Object System.Drawing.Size($($formSize.Width),$($formSize.Height))"
    $lines += "`$form.StartPosition = 'CenterScreen'"
    $lines += "`$form.Font = New-Object System.Drawing.Font('Segoe UI',9)"
    $lines += "`$form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)"
    $lines += ""
    foreach ($c in $controls) {
        $var = $c.Name
        $type = $c.Type
        $lines += ("`$" + $var + " = New-Object System.Windows.Forms." + $type)
        # Name & Text
        $escapedText = $c.Text -replace "'","''"
        $lines += ("`$" + $var + ".Name = '$($c.Name)'")
        $lines += ("`$" + $var + ".Text = '$escapedText'")
        $lines += ("`$" + $var + ".Size = New-Object System.Drawing.Size($($c.Width),$($c.Height))")
        $lines += ("`$" + $var + ".Location = New-Object System.Drawing.Point($($c.Left),$($c.Top))")
        # Font
        $lines += ("`$" + $var + ".Font = New-Object System.Drawing.Font('$($c.Font.Name)',$([double]$c.Font.Size),[System.Drawing.FontStyle]::" + $c.Font.Style + ")")
        # Colors
        $bg = [System.Drawing.Color]::FromArgb([int]$c.BackColor)
        $fg = [System.Drawing.Color]::FromArgb([int]$c.ForeColor)
        $lines += ("`$" + $var + ".BackColor = [System.Drawing.Color]::FromArgb($($bg.A),$($bg.R),$($bg.G),$($bg.B))")
        $lines += ("`$" + $var + ".ForeColor = [System.Drawing.Color]::FromArgb($($fg.A),$($fg.R),$($fg.G),$($fg.B))")
        # ListView columns
        if ($type -eq 'ListView' -and $c.Additional -and $c.Additional.Columns) {
            $lines += ("[void]`$" + $var + ".Columns.Clear()")
            foreach ($col in $c.Additional.Columns) { $colEsc = $col -replace "'","''"; $lines += ("[void]`$" + $var + ".Columns.Add('$colEsc')") }
        }
        $lines += ("[void]`$form.Controls.Add(`$" + $var + ")")
        $lines += ("`$" + $var + ".Add_Click({ param($s,$e) # TODO: implement handler for $($var) })")
        $lines += ""
    }
    $lines += "[void]`$form.ShowDialog()"
    try { Set-Content -Path $path -Value ($lines -join "`r`n") -Encoding UTF8 -Force; return $true } catch { return $false }
}

# Preview (runs generated UI in temp file)
$tsPreview.Add_Click({
    $tmp = Join-Path $env:TEMP ("ui-preview-{0}.ps1" -f ([guid]::NewGuid().ToString()))
    if (Export-LayoutToScript $tmp) { Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tmp); $lblStatus.Text = 'Preview started' } else { $lblStatus.Text = 'Preview export failed' }
})

# Export to file dialog
$tsExport.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = 'PowerShell script (*.ps1)|*.ps1|All files|*.*'
    $sfd.FileName = 'driver-manager.generated.ps1'
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        if (Export-LayoutToScript $sfd.FileName) { $lblStatus.Text = 'Exported to ' + $sfd.FileName } else { $lblStatus.Text = 'Export failed' }
    }
})

# Export + Push to GitHub
function Show-PushDialog() {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = 'Export and push to GitHub'
    $dlg.Size = New-Object System.Drawing.Size(480,300)
    $dlg.StartPosition = 'CenterParent'
    $tbl = New-Object System.Windows.Forms.TableLayoutPanel
    $tbl.Dock = 'Fill'; $tbl.ColumnCount = 2; $tbl.RowCount = 6
    $tbl.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,30)))
    $tbl.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,70)))
    $labels = @('Owner','Repo','Path','Branch','Commit message','Token')
    $defaults = @('pluizigegamer','drivers','driver-manager.ps1','main','Update driver-manager from UI Designer','')
    $boxes = @()
    for ($i=0;$i -lt $labels.Count;$i++) {
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $labels[$i]; $lbl.TextAlign = 'MiddleLeft'
        $tb = New-Object System.Windows.Forms.TextBox; $tb.Dock = 'Fill'; $tb.Text = $defaults[$i]
        if ($labels[$i] -eq 'Token') { $tb.UseSystemPasswordChar = $true }
        $tbl.Controls.Add($lbl,0,$i); $tbl.Controls.Add($tb,1,$i); $boxes += $tb
    }
    $btnOK = New-Object System.Windows.Forms.Button; $btnOK.Text = 'Push'; $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = 'Cancel'; $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock='Bottom'; $flow.Controls.AddRange(@($btnOK,$btnCancel))
    $dlg.Controls.Add($tbl); $dlg.Controls.Add($flow); $dlg.AcceptButton=$btnOK; $dlg.CancelButton=$btnCancel
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return @{
        Owner=$boxes[0].Text; Repo=$boxes[1].Text; Path=$boxes[2].Text; Branch=$boxes[3].Text; Message=$boxes[4].Text; Token=$boxes[5].Text }
    } else { return $null }
}

function Save-ToGitHub($info, $localPath) {
    $api = "https://api.github.com/repos/$($info.Owner)/$($info.Repo)/contents/$($info.Path)"
    $headers = @{ 'User-Agent' = 'PowerShell' }
    if ($info.Token) { $headers.Authorization = "token $($info.Token)" }
    try { $existing = Invoke-RestMethod -Uri $api -Headers $headers -Method Get -ErrorAction Stop; $sha = $existing.sha } catch { $sha = $null }
    $content = Get-Content -Path $localPath -Raw
    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
    $body = @{ message = $info.Message; content = $b64; branch = $info.Branch }
    if ($sha) { $body.sha = $sha }
    $json = $body | ConvertTo-Json -Depth 10
    try { Invoke-RestMethod -Uri $api -Headers $headers -Method Put -Body $json -ContentType 'application/json' -ErrorAction Stop; return $true } catch { $lblStatus.Text = 'Push failed: ' + $_.Exception.Message; return $false }
}

$tsPush.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = 'PowerShell script (*.ps1)|*.ps1|All files|*.*'
    $sfd.FileName = 'driver-manager.generated.ps1'
    if ($sfd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    if (-not (Export-LayoutToScript $sfd.FileName)) { $lblStatus.Text = 'Export failed'; return }
    $info = Show-PushDialog
    if (-not $info) { $lblStatus.Text = 'Push cancelled'; return }
    $lblStatus.Text = 'Pushing to GitHub...'
    if (Save-ToGitHub $info $sfd.FileName) { $lblStatus.Text = "Pushed to $($info.Owner)/$($info.Repo)/$($info.Path)" } else { $lblStatus.Text = 'Push failed' }
})

# New layout
$tsNew.Add_Click({ $canvas.Controls.Clear(); $script:counters = @{}; $lblStatus.Text = 'New layout' })

# Final: show form
[void]$form.ShowDialog()
