$Policy = "Unrestricted"
#$Policy = "RemoteSigned"
If ((get-ExecutionPolicy) -ne $Policy) {
  Set-ExecutionPolicy $Policy -Force
}

Function Install-Features
{
   [cmdletbinding()]
    Param([Parameter(Position=0, Mandatory)][string[]]$requiredFeatures ='')
        Write-Output "`nRetrieving all Windows Features...`n"
        $allFeatures = DISM.exe /ONLINE /Get-Features /FORMAT:List | Where-Object { $_.StartsWith("Feature Name") -OR $_.StartsWith("State") } 
        $features = new-object System.Collections.ArrayList
        for($i = 0; $i -lt $allFeatures.length; $i=$i+2) {
            $feature = $allFeatures[$i]
            $state = $allFeatures[$i+1]
            $features.add(@{feature=$feature.split(":")[1].trim();state=$state.split(":")[1].trim()}) | OUT-NULL
        }
        Write-Output "Checking for missing Windows Features..."
        $missingFeatures = new-object System.Collections.ArrayList
        $features | foreach { 
        if( $requiredFeatures -contains $_.feature -and $_.state -eq 'Disabled') 
            { 
            Write-Output "Feature:",$_.feature" is Missed `n" 
            $missingFeatures.add($_.feature) | OUT-NULL 
            } 
        }
        if(! $missingFeatures) {
            Write-Output "All required Windows Features are installed`n" 
            return $true
            exit
        }

        $missingFeatures | foreach { 
        Write-host "Installing FeatureName:$_ `n" -ForegroundColor Green
        DISM.exe /ONLINE /Enable-Feature /FeatureName:$_  /All /NoRestart
        }
        return $true
}

$scriptExecutionStatus =@()
 [System.Collections.ArrayList]$output =Install-Features -requiredFeatures IIS-WebServerRole
 #,IIS-WebServer,IIS-CommonHttpFeatures,IIS-HttpErrors,IIS-HttpRedirect,IIS-ApplicationDevelopment,IIS-HealthAndDiagnostics,IIS-HttpLogging,IIS-LoggingLibraries,IIS-RequestMonitor,IIS-HttpTracing,IIS-Security,IIS-URLAuthorization,IIS-RequestFiltering,IIS-IPSecurity,IIS-Performance,IIS-WebServerManagementTools,IIS-ManagementScriptingTools,IIS-IIS6ManagementCompatibility,IIS-Metabase,IIS-CertProvider,IIS-WindowsAuthentication,IIS-DigestAuthentication,IIS-ClientCertificateMappingAuthentication,IIS-IISCertificateMappingAuthentication,IIS-ODBCLogging,IIS-StaticContent,IIS-DefaultDocument,IIS-DirectoryBrowsing,IIS-WebDAV,IIS-WebSockets,IIS-ApplicationInit,IIS-CGI,IIS-ISAPIExtensions,IIS-ISAPIFilter,IIS-ServerSideIncludes,IIS-CustomLogging,IIS-BasicAuthentication,IIS-HttpCompressionStatic,IIS-ManagementConsole,IIS-WMICompatibility,IIS-LegacyScripts,IIS-LegacySnapIn,IIS-FTPServer,IIS-FTPSvc,IIS-FTPExtensibility,NetFx4Extended-ASPNET45,IIS-NetFxExtensibility,IIS-NetFxExtensibility45,IIS-ASPNET,IIS-ASPNET45,IIS-ASP,IIS-ManagementService
 #$Settings.Settings.WindowsFeatures.FeatureName
 if( $output -ne $null)
 {
    if($output.Contains($true))
      {
        $scriptExecutionStatus += $true
      }
}
else
{
	Write-Output "ERROR in Capturing the Output"
}
if( $scriptExecutionStatus.Contains($false) )
{
    Write-Output "Script Execution Status :: $false" 
    Write-Output "$StepName  Step has Failed..!"
}
Else
{
    Write-Output "Script Execution Status :: $true"
    Write-Output "$StepName Step has successfully completed..!"
}

Stop-Transcript
