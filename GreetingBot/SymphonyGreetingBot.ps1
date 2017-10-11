# This script is designed to camp out on a room and display a welcome greeting when a UserAddedToRoom event has been detected

    # Welcome to the Symphony Bot Collection

    # This PowerShell bot is brought to you by Symphony's Solutions Architect Team
    # Based on the pioneering work in PowerShell by Patrick O'Brien
    # Guided by the expertise of our API guy Mike Scannell
    # Under the realm of our fearless leader Kevin Byrne

    # Author: JoAnne Mann
    # Date: 9.8.2017
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
    $keyAuthUrl = "https://mycompany.symphony.com/keyauth/v1/authenticate"
    #$keyAuthUrl = $sessionAuthUrl
    $podUrl =  "https://sup-agent.symphony.com"
    $agentUrl = "https://sup-agent.symphony.com/agent"
    $datafeedUrl = "$agentUrl/v1/datafeed/create"
    $podUrl = "https://mycompany.symphony.com/pod"
    $userUrl = "$podUrl/v2/user"
    $roomUrl = "$podUrl/v2/room"
    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #currently this only supports unauthenticating proxys 
    #$proxy = "-Proxy http://myproxy:8888/"

    # This script allows you to store messages for each room.  The format is a file with the name of the room in
    # a directory.  You can also have a file called "Default" in this directory, which will display a default message
    # if a room doe not have a specific file with content.  Alternatively, you can use the system default.
    # Note: you can use <room> in the content files to have the program use the room name.  Use <name> for user name.
    $roomDir="./Rooms"

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
Import-Module ..\Cmdlets\getSessionAuthToken.ps1  -force
Import-Module ..\Cmdlets\getKeyAuthToken.ps1 -force
Import-Module ..\Cmdlets\getStreamID.ps1 -force
Import-Module ..\Cmdlets\getUserName.ps1 -force
Import-Module ..\Cmdlets\getRoomName.ps1 -force

$sessionAuthToken = getSessionAuthToken $sessionAuthUrl $certificateObject.Thumbprint
$global:hdrs.Set_Item("sessionToken",$sessionAuthToken)
$keyManagerToken = getKeyAuthToken $keyAuthUrl $certificateObject.Thumbprint
$global:hdrs.Set_Item("keyManagerToken",$keyManagerToken)
$streamID = getStreamID $datafeedUrl $global:hdrs
if ($streamID) {$readUrl = "$agentUrl/v2/datafeed/$streamID/read"} else {Write-host "Could not get a streamID.  Exiting";exit}

Write-Host "---Setup complete.  Waiting for UserAddedToRoom Events."
# This is a daemon, so run forever

While($true) {

  try {
          $Result = (Invoke-RestMethod -Method GET  -ContentType 'application/json' -Headers $global:hdrs  -Uri "$readUrl") 

	  if ($Result.memberAddedUserId) {
	    # We have a UserAddedToRoom Event.  Let's post the greeting.
	    $memberAddedUserId = $Result.memberAddedUserId
 	    $streamId = $Result.streamId

            # Get the room name so we can find the greeting and the conversationID
            $roomNameUrl = "$roomUrl/$StreamId/info"
            $roomName = getRoomName($roomNameUrl)

            # Get the user name so we can @mention them

            $userIdUrl = "$userUrl/?uid=$memberAddedUserId&local=true"
            $userName = getUserName($userIdUrl)
            Write-Host
            Write-Host

            # Message the user.  We use an external curl bash script as PowerShell does not support --form-content needed for messageML..
            try { 
              $out = &./GreetingCurl.sh -s $sessionAuthToken -k $keyManagerToken -T $streamID -u $memberAddedUserId -n $userName -r $roomName -R $roomDir
            } catch {
              Write-Host "Failed"
              Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
            }
      }
      Start-Sleep -s 3 
  } catch {

        Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$readUrl'" -ForegroundColor white -BackgroundColor red
        Write-Host "Failed to connect on $readUrl "
  }
} 

Write-Host "Elapsed time: " (NEW-TIMESPAN –Start $beforeTime –End (Get-Date)) 

exit

