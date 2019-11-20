Write-Output "Starting the starterstarter" | Out-File C:\temp\tsm.log
$curdir = Get-Location | Select-Object -ExpandProperty Path
Write-Output "current dir is $curdir" | Out-File C:\temp\tsm.log -Append
$process = Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-ExecutionPolicy Bypass","-NoLogo","-NoProfile","-File `"$curdir\ApplicationStarter.ps1`"" -Wait -PassThru
Write-Output "process exited with $($process.ExitCode)" | Out-File C:\temp\tsm.log -Append