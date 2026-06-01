# UI Designer - Edit driver-manager.ps1 and push to GitHub
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$defaultOwner = 'pluizigegamer'
$defaultRepo = 'drivers'
$defaultPath = 'driver-manager.ps1'
$defaultBranch = 'main'

$form = New-Object System.Windows.Forms.Form
$form.Text = "UI Designer - driver-manager"
$form.Size = New-Object System.Drawing.Size(1000,700)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Consolas',10)

$top = New-Object System.Windows.Forms.FlowLayoutPanel
$top.Dock = 'Top'
$top.Height = 40

$btnLoadRepo = New-Object System.Windows.Forms.Button; $btnLoadRepo.Text = 'Load from Repo'; $btnLoadRepo.Width = 120
$btnLoadLocal = New-Object System.Windows.Forms.Button; $btnLoadLocal.Text = 'Load from File'; $btnLoadLocal.Width = 120
$btnPreview = New-Object System.Windows.Forms.Button; $btnPreview.Text = 'Preview'; $btnPreview.Width = 120
$btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = 'Save to GitHub'; $btnSave.Width = 120

$top.Controls.AddRange(@($btnLoadRepo,$btnLoadLocal,$btnPreview,$btnSave))

$txt = New-Object System.Windows.Forms.TextBox
$txt.Multiline = $true
$txt.Dock = 'Fill'
$txt.ScrollBars = 'Both'
$txt.WordWrap = $false
$txt.Font = New-Object System.Drawing.Font('Consolas',10)

$status = New-Object System.Windows.Forms.Label
$status.Dock = 'Bottom'
$status.Height = 22
$status.Text = 'Ready'

$form.Controls.Add($txt)
$form.Controls.Add($top)
$form.Controls.Add($status)

# Load from repo handler
$btnLoadRepo.Add_Click({
    $raw = "https://raw.githubusercontent.com/$defaultOwner/$defaultRepo/$defaultBranch/$defaultPath"
    try {
        $content = Invoke-RestMethod -Uri $raw -ErrorAction Stop
        $txt.Text = $content
        $status.Text = "Loaded $defaultPath from $defaultOwner/$defaultRepo"
    } catch {
        $status.Text = "Load failed: $($_.Exception.Message)"
    }
})

# Load local file
$btnLoadLocal.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = 'PowerShell Scripts|*.ps1|All files|*.*'
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $txt.Text = Get-Content -Path $ofd.FileName -Raw
            $status.Text = "Loaded $($ofd.FileName)"
        } catch { $status.Text = "Load failed: $($_.Exception.Message)" }
    }
})

# Preview
$btnPreview.Add_Click({
    $tmp = Join-Path $env:TEMP ("ui-preview-{0}.ps1" -f ([guid]::NewGuid().ToString()))
    Set-Content -Path $tmp -Value $txt.Text -Encoding UTF8 -Force
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$tmp)
        $status.Text = "Preview started"
    } catch { $status.Text = "Preview failed: $($_.Exception.Message)" }
})

# Save dialog function
function Show-SaveDialog {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = 'Save to GitHub'
    $dlg.Size = New-Object System.Drawing.Size(460,300)
    $dlg.StartPosition = 'CenterParent'
    $dlg.Font = New-Object System.Drawing.Font('Segoe UI',9)
    $table = New-Object System.Windows.Forms.TableLayoutPanel
    $table.Dock = 'Fill'
    $table.ColumnCount = 2
    $table.RowCount = 6
    $table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,30)))
    $table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,70)))
    $labels = @('Owner','Repo','Path','Branch','Commit message','Token')
    $defaults = @($defaultOwner,$defaultRepo,$defaultPath,$defaultBranch,'Update driver-manager via UI Designer','')
    $boxes = @()
    for ($i=0;$i -lt $labels.Count;$i++) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $labels[$i]
        $lbl.TextAlign = 'MiddleLeft'
        $tb = New-Object System.Windows.Forms.TextBox
        $tb.Dock = 'Fill'
        $tb.Text = $defaults[$i]
        if ($labels[$i] -eq 'Token') { $tb.UseSystemPasswordChar = $true }
        $table.Controls.Add($lbl,0,$i)
        $table.Controls.Add($tb,1,$i)
        $boxes += $tb
    }
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = 'Save'
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $flow.Dock = 'Bottom'
    $flow.Controls.AddRange(@($btnOK,$btnCancel))
    $dlg.Controls.Add($table)
    $dlg.Controls.Add($flow)
    $dlg.AcceptButton = $btnOK
    $dlg.CancelButton = $btnCancel
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            Owner = $boxes[0].Text
            Repo = $boxes[1].Text
            Path = $boxes[2].Text
            Branch = $boxes[3].Text
            Message = $boxes[4].Text
            Token = $boxes[5].Text
        }
    } else { return $null }
}

# Save to GitHub
function Save-ToGitHub($info, $content) {
    $api = "https://api.github.com/repos/$($info.Owner)/$($info.Repo)/contents/$($info.Path)"
    $headers = @{ 'User-Agent' = 'PowerShell'; Authorization = "token $($info.Token)" }
    try {
        $existing = Invoke-RestMethod -Uri $api -Headers $headers -Method Get -ErrorAction Stop
        $sha = $existing.sha
    } catch {
        $sha = $null
    }
    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
    $body = @{ message = $info.Message; content = $b64; branch = $info.Branch }
    if ($sha) { $body.sha = $sha }
    $json = $body | ConvertTo-Json -Depth 10
    try {
        Invoke-RestMethod -Uri $api -Headers $headers -Method Put -Body $json -ContentType 'application/json' -ErrorAction Stop
        return $true
    } catch {
        $status.Text = 'Save failed: ' + $_.Exception.Message
        return $false
    }
}

$btnSave.Add_Click({
    $info = Show-SaveDialog
    if (-not $info) { $status.Text = 'Save cancelled'; return }
    $status.Text = 'Saving...'
    $ok = Save-ToGitHub $info $txt.Text
    if ($ok) { $status.Text = "Saved to $($info.Owner)/$($info.Repo)/$($info.Path)" } else { $status.Text = 'Save failed' }
})

[void]$form.ShowDialog()
