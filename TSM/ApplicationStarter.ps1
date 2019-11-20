Write-Output "Starting the GUI" | Out-File C:\temp\tsm.log -Append
$Title = 'TSM Installer'
$curdir = Get-Location | Select-Object -ExpandProperty Path
Write-Output "current dir is $curdir" | Out-File C:\temp\tsm.log -Append
$Location = '75,75'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Write-Output "Added GUI types" | Out-File C:\temp\tsm.log -Append
$form = [System.Windows.Forms.Form]::New()
$form.StartPosition = 'Manual'
$form.Location = $Location
$form.Text = $Title
$font = New-Object System.Drawing.Font("Comic Sans",10,[System.Drawing.FontStyle]::Bold)
$form.Font = $font
$form.Width = 700
$form.Height = 200

# Welcome Message
$label =  New-Object “System.Windows.Forms.Label”
$label.Left = 25
$label.Top = 15 
$label.AutoSize = $false
$label.TextAlign = 'TopCenter'
$label.Dock = 'Top'
$label.Text = "Welcome to the TSM Client Installer"

# Password Label
$textLabel1 =  New-Object “System.Windows.Forms.Label”
$textLabel1.Left = 25
$textLabel1.Top = 50 
$textLabel1.Width = 180
$textLabel1.AutoSize = $false
$textLabel1.TextAlign = 'TopLeft'
$textLabel1.Text = "TSM Client Pass"

# Password Box 
$textBox1 = New-Object “System.Windows.Forms.MaskedTextBox”
$textBox1.PasswordChar = "*"
$textBox1.Left = 250
$textBox1.Top = 50
$textBox1.width = 200
    
# Password Enter Button
$button = New-Object “System.Windows.Forms.Button”
$button.Left = 500
$button.Top = 50
$button.Width = 100
$button.Text = “Enter”

# What happens when we hit enter
$eventHandler = [System.EventHandler]{
    if($textBox1.Text){
        $curdir = Get-Location | Select-Object -ExpandProperty Path
        $tsmpass = $textBox1.Text
        $runninglabel =  New-Object “System.Windows.Forms.Label”
        $runninglabel.Left = 25
        $runninglabel.Top = 100 
        $runninglabel.Width = 500
        $runninglabel.AutoSize = $false
        $runninglabel.Text = "TSM Installation Running"
        $form.Controls.Add($runninglabel)
        sleep 1
        Write-Output "starting psadt process" | Out-File C:\temp\tsm.log -Append
        $psadt = Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-ExecutionPolicy Bypass","-NoLogo","-NoProfile","-File `"$curdir\Deploy-Application.ps1`" $tsmpass" -Wait -PassThru -NoNewWindow
        Write-Output "psadt exited with code $($psadt.ExitCode)" | Out-File C:\temp\tsm.log -Append
        if($($psadt.ExitCode) -ne 0){
            $form.Controls.Remove($runninglabel)
            $returnlabel =  New-Object “System.Windows.Forms.Label”
            $returnlabel.Left = 25
            $returnlabel.Top = 100 
            $returnlabel.Width = 500
            $returnlabel.AutoSize = $false
            $returnlabel.Text = "TSM Installation Failed Please Try Again"
            $form.Controls.Add($returnlabel)  
        } else {
            $form.Controls.Remove($runninglabel)
            $returnlabel =  New-Object “System.Windows.Forms.Label”
            $returnlabel.Left = 25
            $returnlabel.Top = 100 
            $returnlabel.Width = 500
            $returnlabel.AutoSize = $false
            $returnlabel.Text = "TSM Installation Succeeded!"
            $form.Controls.Add($returnlabel)
            Sleep 3
            $form.Close()
        }    
    }
}
$button.Add_Click($eventHandler)

# Skip Button
$skip = New-Object “System.Windows.Forms.Button”
$skip.Left = 500
$skip.Top = 100
$skip.Width = 100
$skip.Text = “Skip”

# What happens when we hit skip
$skipeventHandler = [System.EventHandler]{
    $returnlabel =  New-Object “System.Windows.Forms.Label”
    $returnlabel.Left = 25
    $returnlabel.Top = 100 
    $returnlabel.Width = 400
    $returnlabel.AutoSize = $false
    $returnlabel.Text = "Skipping TSM Installation"
    $form.Controls.Add($returnlabel)
    Sleep 3
    $form.Close()
}
$skip.Add_Click($skipeventHandler)

$form.Controls.Add($label)
$form.Controls.Add($textLabel1)
$form.Controls.Add($button)
$form.Controls.Add($skip)
$form.Controls.Add($textBox1)
Write-Output "starting the form" | Out-File C:\temp\tsm.log -Append
$ret = $form.ShowDialog()
Write-Output "form completed with code `n $($ret)" | Out-File C:\temp\tsm.log -Append
return 0

