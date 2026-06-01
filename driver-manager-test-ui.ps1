# Driver Manager - Test UI (very small)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Driver Manager - Test'
$form.Size = New-Object System.Drawing.Size(420,180)
$form.StartPosition = 'CenterScreen'

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = 'Scan'
$btnScan.Size = New-Object System.Drawing.Size(100,30)
$btnScan.Location = New-Object System.Drawing.Point(20,20)
$btnScan.Add_Click({ [System.Windows.Forms.MessageBox]::Show('Scan clicked','Info') })

$form.Controls.Add($btnScan)
[void]$form.ShowDialog()
