    # Welcome to the Symphony Bot Collection

    # This PowerShell bot is brought to you by Symphony's Solutions Architect Team
    # Based on the pioneering work in PowerShell by Patrick O'Brien
    # Guided by the expertise of our API guy Mike Scannell
    # Under the realm of our fearless leader Kevin Byrne

    # Author: JoAnne Mann
    # Date: 2.8.2018
    # Copyright Symphony Communications LLC 2017 All Rights Reserved
    # These scripts are distributed as-is and are meant to be a template for automating pod administration tasks.

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

# Notes on the Script

    # This Powershell script performs a one-time requests to suppress a message.
    # It requires the messageID of the message that should be suppressed.  MessageID is of the format
    #     eU8++8VJ7dA8O7vCkvno73///qOBg+l3dA==
    # The widget will convert it to URL safe, and suppress the message.

# ---------------------------------------------------------------------------------------------------------

# Grab the commandline parameters
param (
    [Parameter(Mandatory=$true)][string]$messageID
    #[string]$password = $( Read-Host "Input password, please" )
 )
if (-Not $messageID) {
  Write-Host "Blank messageID. "
  Write-Host "Usage: $MyInvocation.MyCommand.Name -message eU8++8VJ7dA8O7vCkvno73///qOBg+l3dA=="
  Write-Host "   Exiting"
  exit
} 

# Fill in these Variables

    $certificateFileAndPath =     "C:\mycerts\bot.user1.p12"
    $certificateFilePassword =    "changeit"

    $sessionAuthUrl =  "https://mypod-api.symphony.com/sessionauth/v1/authenticate"
    $keyAuthUrl = "https://mypod.symphony.com/keyauth/v1/authenticate"
    $podUrl =  "https://mypod.symphony.com/pod"
    $agentUrl = "https://mypod.symphony.com/agent"


    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #currently this only supports unauthenticating proxys 
    #$proxy = "-Proxy http://myproxy:8888/"

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

if (-Not $messageID) {
  Write-Host "Blank messageID. "
  Write-Host "Usage: $MyInvocation.ScriptName -message eU8++8VJ7dA8O7vCkvno73///qOBg+l3dA=="
  Write-Host "   Exiting"
  exit
} 

$global:hdrs = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$global:hdrs.Add("sessionToken","123")
$global:hdrs.Add("keyManagerToken",$keyManagerToken)

#Function Declarations
function getSessionAuthToken {

    try {
        $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -CertificateThumbprint $certificateObject.Thumbprint).token
	#$sessionAuthToken = "8ef9c10b5e3afcd4e511eb7d6fec034d6a94002228f8024d062c7fb6712aba6dbd86ae37ee5d09169366eb4145c586d47cdf00bf3b669298bd2881c68ee78da9"
    } catch {
        Write-Host "failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to sessionauth endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$sessionAuthUrl'" -ForegroundColor white -BackgroundColor red
	Write-Host "  FAILED to obtain SessionAuthToken.  Please check the health of your pod.  Exiting." -ForegroundColor white -BackgroundColor re
        exit
    }
  $global:hdrs.Set_Item("sessionToken",$sessionAuthToken)
  return $sessionAuthToken
}

function getKeyAuthToken {

    try {
        $keyManagerToken = (Invoke-RestMethod -Method POST -Uri $keyAuthUrl -CertificateThumbprint $certificateObject.Thumbprint).token 
    } catch {

        Write-Host "Failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to keyauth endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$keyAuthUrl'" -ForegroundColor white -BackgroundColor red
	Write-Host "  FAILED to obtain KeyAuthToken.  Please check the health of your pod.  Exiting." -ForegroundColor white -BackgroundColor red
        exit
    }
  $global:hdrs.Set_Item("keyManagerToken",$keyManagerToken)
  return $keyManagerToken
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
$sessionAuthToken=getSessionAuthToken
$keyManagerToken = getKeyAuthToken

Write-Host "---Setup complete.  Converting messageID $messageID to URLSafe Base64."

	    # Generate a URLSafe Base64 conversion of the Message ID
	    $messageID = $messageID -replace "/","_"
	    $messageID = $messageID -replace '\+',"-" 
	  
	  # Perform the suppression
 	  try {
                  $messageResult = (Invoke-RestMethod -Method POST  -ContentType 'application/json' -Headers $global:hdrs -Body $msgjson -Uri $podUrl/v1/admin/messagesuppression/$MessageID/suppress)
                Write-Host "Message $messageID has been suppressed.  Result: $messageResult"
                } catch {
                  Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
                  Write-Host "Current endpoint: '$podUrl/v1/admin/messagesuppression/$MessageID/suppress'" -ForegroundColor white -BackgroundColor red

		  $msg = "I had an issue with message ID $messageID.  The operation did not complete. Please check that you have a correct message ID format.  You can just cut+paste and I will take care of making it a URL safe Message ID. "
Write-Host $msg

    } 

  Write-Host "Elapsed time: " (NEW-TIMESPAN –Start $beforeTime –End (Get-Date)) 

exit

