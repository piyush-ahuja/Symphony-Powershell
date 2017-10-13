# This script will toggle the user entitlement "canCreatePublicRoom" to off for every user in a pod
# The Cmdlets are required for this script to function.

    # Welcome to the Symphony Bot Collection

    # This PowerShell bot is brought to you by Symphony's Solutions Architect Team
    # Based on the pioneering work in PowerShell by Patrick O'Brien
    # Guided by the expertise of our API guy Mike Scannell
    # Under the realm of our fearless leader Kevin Byrne

    # Author: JoAnne Mann
    # Date: 10.9.2017
    # Copyright Symphony Communications LLC 2017 All Rights Reserved

    # This is a Windows PowerShell Script and it was tested on Powershell 5.1 which can be found here:
    #    https://www.microsoft.com/en-us/download/details.aspx?id=54616
    # You may also enjoy the Windows Powershell Ingtegrated Script Environment (ISE) described here:
    #    https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/ise/introducing-the-windows-powershell-ise
    # You must run "Set-ExecutionPolicy RemoteSigned" as described here:
    #    http://windowsitpro.com/powershell/running-powershell-scripts-easy-1-2-3

    # Modify the "Fill in these Variables" section below for your specific pod and environment

    #                                ,,                       
    #                                 ||                       
    #      _-_, '\\/\\ \\/\\/\\ -_-_  ||/\\  /'\\ \\/\\ '\\/\\ 
    #     ||_.   || ;' || || || || \\ || || || || || ||  || ;' 
    #      ~ ||  ||/   || || || || || || || || || || ||  ||/   
    #     ,-_-   |/    \\ \\ \\ ||-'  \\ |/ \\,/  \\ \\  |/    
    #           (               |/      _/              (      
    #            -_-            '                        -_- 



# ---------------------------------------------------------------------------------------------------------
# Fill in these Variables

    $certificateFileAndPath =     "C:\mycerts\bot.user1.p12"
    $certificateFilePassword =    "changeit"

    $sessionAuthUrl =  "https://mycompany-api.symphony.com/sessionauth/v1/authenticate"
    $keyAuthUrl = "https://mycompany-api.symphony.com/keyauth/v1/authenticate"
    $podUrl =  "https://mycompany.symphony.com"
    $agentUrl = "$podUrl/agent"
    $datafeedUrl = "$agentUrl/v1/datafeed/create"
    $userUrl = "$podUrl/v2/user"
    $roomUrl = "$podUrl/v2/room"
    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #currently this only supports unauthenticating proxys 
    #$proxy = "-Proxy http://myproxy:8888/"
    $Cmdlets = "C:/Symphony-Powershell/Cmdlets"

# Script Body

Clear-Host
Write-Host
Write-Host
Write-Host
Write-Host
Write-Host
Write-Host
$beforeTime = Get-Date
Write-Host "Starting at " $beforeTime.ToLocalTime()


$global:hdrs = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$global:hdrs.Add("sessionToken","123")
$global:hdrs.Add("keyManagerToken",$keyManagerToken)

function processError ($reason,$status,$exception) {
  Write-Host "Received error on message create.  Reason: $reason Status: $status Exception: $exception"
  return
}

# Get p12 certificate thumbprint
try {
            $certificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $certificateObject.Import($certificateFileAndPath, $certificateFilePassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet)

    } catch {

        Write-Host "ERROR: Certificate read failed with error '$($_.Exception.InnerException)'" -ForegroundColor white -BackgroundColor red
	Write-Host "    There is a problem with your certificate $certificateFileAndPath.  This needs to be resolved, " -ForegroundColor white -BackgroundColor red
	Write-Host "    before you can try to start your bot.  Exiting. " -ForegroundColor white -BackgroundColor red
        exit
    }

#Set up for processing
Import-Module $Cmdlets\getSessionAuthToken.ps1  -force
Import-Module $Cmdlets\getKeyAuthToken.ps1 -force
Import-Module $Cmdlets\getUserName.ps1 -force
Import-Module $Cmdlets\getUserStatus.ps1 -force

$sessionAuthToken = getSessionAuthToken $sessionAuthUrl $certificateObject.Thumbprint
$global:hdrs.Set_Item("sessionToken",$sessionAuthToken)
$keyManagerToken = getKeyAuthToken $keyAuthUrl $certificateObject.Thumbprint
$global:hdrs.Set_Item("keyManagerToken",$keyManagerToken)

# Get Full Symphony userlist
#$hdrs = @{}
#$hdrs.Add("sessionToken",$sessionAuthToken)

Write-Host "Generating list of users for this pod."
try {
        if ($proxy) {    $fullUserList = Invoke-RestMethod -Method GET -Headers $global:hdrs  -Proxy $proxy -Uri "$podUrl/pod/v1/admin/user/list"}
        else        {    $fullUserList = Invoke-RestMethod -Method GET -Headers $global:hdrs -Uri "$podUrl/pod/v1/admin/user/list"}

} catch {

    Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    Write-Host "Current endpoint: '$podUrl/pod/v1/admin/user/list'" -ForegroundColor white -BackgroundColor red

    exit
}

$userCount=$fullUserList.Count

Write-Host "Found $userCount active and inactive accounts in this pod."
$DataList = @{}
$DataList.Add("entitlment", "canCreatePublicRoom")
$DataList.Add("enabled", "false")
$json = $DataList | ConvertTo-Json

# Loop on the user list  to get the user detail
$fullUserList | foreach { 

   $totalCount=$totalCount+1
   
$id = $_
$userIdUrl = $userUrl + "?uid=$id&local=true"
$userStatus = getUserStatus($userIdUrl)
if ($userStatus -ne "service") {
  $userName = getUserName($userIdUrl)
  Write-Host "Updating entitlement canCreatePublicRoom for end user id $_  user $userName "
  try {
   if ($proxy) { $userDetail = Invoke-RestMethod -Method POST -Body [$json]  -ContentType 'application/json' -Headers $global:hdrs -Proxy $proxy -Uri "$podUrl/pod/v1/admin/user/$id/features/update" }
   else        { $userDetail = Invoke-RestMethod -Method POST -Body [$json]  -ContentType 'application/json' -Headers $global:hdrs  -Uri "$podUrl/pod/v1/admin/user/$id/features/update" } 
} catch {

     Write-Host "Failed to update entitlement for user $id"
      Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    }

  } else { $serviceCount=$serviceCount+1} 
  Start-Sleep -s 3
}

Write-Host "Attempted to update $totalCount users of $userCount found in the pod; $serviceCount service accounts skipped"
exit

