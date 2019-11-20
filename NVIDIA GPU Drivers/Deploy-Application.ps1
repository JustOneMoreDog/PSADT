<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows. 
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. 
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'NonInteractive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'NVIDIA'
	[string]$appName = 'NVIDIA GPU Drivers'
	[string]$appVersion = '419' # UPDATE ME 
	[string]$appArch = 'x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '6.1.6' # UPDATE ME 
	[string]$appScriptDate = '05/06/2019'
	[string]$appScriptAuthor = 'picnicsecurity'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.7.0'
	[string]$deployAppScriptDate = '04/2069'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
    
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}	

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress

        if($(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption) -notlike "*Windows 10*"){
            Write-Log "This host is not coming up as Windows 10 and therefor will not get a driver ( $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption) )"
            Write-Log "Exiting"
            return 0
        }

        # Log information for troubleshooting
        $gpuobj = Get-WmiObject -Class win32_videocontroller
        $gpuname = $gpuobj | Select-Object -ExpandProperty Name		
        $gpuver = $gpuobj | Select-Object -ExpandProperty DriverVersion
        Write-Log "Starting driver installation process for a $gpuname with current version $gpuver"

		## <Perform Pre-Installation tasks here>
        switch -Wildcard ($gpuname){

            *quadro* { $installingquadro = $true }
            *nvs*    { $installingquadro = $true }
            default  { $installinggtx    = $true }

        }

        # If we are in the task sequence then we do not need to do a clean install
        try {
            $TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
            $inTS = $true
        } catch { 
            $inTS = $false
        } 

        # First we extract the right exe files
        if($installingquadro){
            Write-Log "Installing Standard Quadro Drivers"
            Write-Log "$(Get-ChildItem -Path $dirSupportFiles)"
            $Source = Get-ChildItem -Path $dirSupportFiles | Where-Object { $_.Name -like "*quadro*.exe" } | Select-Object -ExpandProperty FullName
            Write-Log $Source
            $Target = "$dirFiles"
            $7ziparg = @('x';'-y';"`"-o$($Target)`"";"`"$($Source)`"")
		    Execute-Process -Path "$env:ProgramFiles\7-Zip\7z.exe" -Parameters $7ziparg -PassThru 
        } else {
            Write-Log "Installing Standard GTX Drivers"
            Write-Log "$(Get-ChildItem -Path $dirSupportFiles)"
            $Source = Get-ChildItem -Path $dirSupportFiles | Where-Object { $_.Name -notlike "*quadro*.exe" -and $_.Name -like "*.exe" } | Select-Object -ExpandProperty FullName
            Write-Log $Source
            $Target = "$dirFiles"
            $7ziparg = @('x';'-y';"`"-o$($Target)`"";"`"$($Source)`"")
		    Execute-Process -Path "$env:ProgramFiles\7-Zip\7z.exe" -Parameters $7ziparg -PassThru
        }
	
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}
		
		### <Perform Installation tasks here> ###

        # First thing we want to do is make sure NVIDIA Logging is enabled
        $regpath = Join-Path $dirSupportFiles "EnableFullLogging.reg"
        Invoke-Expression "regedit /s $regpath"

        if($installingquadro){

            ###### QUADRO BLOCK ######
            # The list devices text file contains all the devices that are supported by the driver.  If our gpu is not in there then we do not install
            if($(Get-Content "$dirFiles\ListDevices.txt" | Select-String -Pattern $(Get-WmiObject -Class win32_videocontroller | Select-Object -ExpandProperty name))){
            
                # Since it is quadro we can just execute setup.exe right away
                Execute-Process -Path "$dirFiles\setup.exe" -Parameters "-s -clean"
            
                # When it comes to these drivers, there are two types of drivers we can install, Standard and DCH.  We will always try Standard first but if it fails, then we try DCH
                if($mainExitCode -ne "0"){
                    Write-Log "Standard Quadro Drivers failed with LASTEXITCODE equaling $LASTEXITCODE and mainExitCode $mainExitCode"
                    Write-Log "Trying DCH Drivers"

                    if($(Get-Content "$dirFiles\ListDevices.txt" | Select-String -Pattern $(Get-WmiObject -Class win32_videocontroller | Select-Object -ExpandProperty name))){

                        Remove-Item -Path $dirFiles\* -Recurse -Force
                        Write-Log "Cleared everything out of the files directory"
                        $dirFilesDCH = Join-Path $dirSupportFiles "DCH"
                        $Source = Get-ChildItem -Path $dirFilesDCH | Where-Object { $_.Name -like "*quadro*dch*.exe" } | Select-Object -ExpandProperty FullName 
                        $Target = "$dirFiles"
                        $7ziparg = @('x';'-y';"`"-o$($Target)`"";"`"$($Source)`"")
		                Execute-Process -Path "$env:ProgramFiles\7-Zip\7z.exe" -Parameters $7ziparg -PassThru    
                        
                        Execute-Process -Path "$dirFiles\setup.exe" -Parameters "-s -clean"

                    } else {
                        Write-Log "GPU is not supported by the DCH Drivers"
                    }                           
                } else {
                   Write-Log "Standard Quadro Drivers completed fine with LASTEXITCODE equaling $LASTEXITCODE and mainExitCode $mainExitCode"
                } 
            } else {
                Write-Log "GPU NOT SUPPORTED"
                Exit-Script -ExitCode 0
            }

        } else {

            ###### GTX BLOCK ######
            # The list devices text file contains all the devices that are supported by the driver.  If our gpu is not in there then we do not install
            if($(Get-Content "$dirFiles\ListDevices.txt" | Select-String -Pattern $(Get-WmiObject -Class win32_videocontroller | Select-Object -ExpandProperty name))){
            
                # Since we do not want geforce experience, but still have to keep certain files in their directories, we do some shuffling 
                if($(Get-ChildItem $dirFiles | Where-Object { $_.Name -like "GFExperience*" })){
                    New-Item -ItemType Directory -Path "$dirFiles\temp"
                    Copy-Item -Path "$dirFiles\GFExperience\EULA.html" -Destination "$dirFiles\temp\"
                    Copy-Item -Path "$dirFiles\GFExperience\PrivacyPolicy" -Destination "$dirFiles\temp\" -Recurse
                    Copy-Item -Path "$dirFiles\GFExperience\FunctionalConsent*" -Destination "$dirFiles\temp\"
                    $gforceName = Get-ChildItem $dirFiles | Where-Object { $_.Name -like "GFExperience" } | Select-Object -ExpandProperty Name
                    Get-ChildItem $dirFiles | Where-Object { $_.Name -like "GFExperience*" } | Select-Object -ExpandProperty FullName | Remove-Item -Recurse
                    Move-Item -Path "$dirFiles\temp" -Destination "$dirFiles\$gforceName"
                }

                # Now that we have removed all the geforce experience crap that we do not want we can do our clean and silent install of the driver
                Execute-Process -Path "$dirFiles\setup.exe" -Parameters "-s -clean"

                if($mainExitCode -ne "0"){
                    Write-Log "Standard Drivers failed with LASTEXITCODE equaling $LASTEXITCODE and mainExitCode $mainExitCode"
                    Write-Log "Trying DCH Drivers"

                    if($(Get-Content "$dirFiles\ListDevices.txt" | Select-String -Pattern $(Get-WmiObject -Class win32_videocontroller | Select-Object -ExpandProperty name))){
                        Remove-Item -Path $dirFiles\* -Recurse -Force
                        Write-Log "Cleared everything out of the files directory"
                        $dirFilesDCH = Join-Path $dirSupportFiles "DCH"
                        $Source = Get-ChildItem -Path $dirFilesDCH | Where-Object { $_.Name -notlike "*quadro*" -and $_.Name -like "*dch*.exe" } | Select-Object -ExpandProperty FullName 
                        $Target = "$dirFiles"
                        $7ziparg = @('x';'-y';"`"-o$($Target)`"";"`"$($Source)`"")
		                Execute-Process -Path "$env:ProgramFiles\7-Zip\7z.exe" -Parameters $7ziparg -PassThru

                        # Since we do not want geforce experience, but still have to keep certain files in their directories, we do some shuffling 
                        if($(Get-ChildItem $dirFiles | Where-Object { $_.Name -like "GFExperience*" })){
                            New-Item -ItemType Directory -Path "$dirFiles\temp"
                            Copy-Item -Path "$dirFiles\GFExperience\EULA.html" -Destination "$dirFiles\temp\"
                            Copy-Item -Path "$dirFiles\GFExperience\PrivacyPolicy" -Destination "$dirFiles\temp\" -Recurse
                            Copy-Item -Path "$dirFiles\GFExperience\FunctionalConsent*" -Destination "$dirFiles\temp\"
                            $gforceName = Get-ChildItem $dirFiles | Where-Object { $_.Name -like "GFExperience" } | Select-Object -ExpandProperty Name
                            Get-ChildItem $dirFiles | Where-Object { $_.Name -like "GFExperience*" } | Select-Object -ExpandProperty FullName | Remove-Item -Recurse
                            Move-Item -Path "$dirFiles\temp" -Destination "$dirFiles\$gforceName"
                        }

                        Execute-Process -Path "$dirFiles\setup.exe" -Parameters "-s -clean"
                       
                    } else {
                        Write-Log "GPU is not supported by the DCH Drivers"
                    }                           
                } else {
                    Write-Log "Standard Drivers completed fine with LASTEXITCODE equaling $LASTEXITCODE and mainExitCode $mainExitCode"
                } 
            } else {
                Write-Log "GPU NOT SUPPORTED"
                Exit-Script -ExitCode 0
            }

        }

        # Log information for troubleshooting
        $gpuobj = Get-WmiObject -Class win32_videocontroller
        $gpuname = $gpuobj | Select-Object -ExpandProperty Name		
        $gpuver = $gpuobj | Select-Object -ExpandProperty DriverVersion
        Write-Log "Finished driver installation process for a $gpuname with current version $gpuver"
		
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		
		## Display a message at the end of the install
		If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		
		# <Perform Uninstallation tasks here>
		
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
		
		
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}