    # Welcome to the Symphony Bot Collection

    # This PowerShell bot is brought to you by Symphony's Solutions Architect Team
    # Based on the pioneering work in PowerShell by Patrick O'Brien
    # Guided by the expertise of our API guy Mike Scannell
    # Under the realm of our fearless leader Kevin Byrne

    # Author: JoAnne Mann
    # Date: 9.8.2017
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

    # This Powershell script uses datafeed to listen for requests to suppress a message.

    # Usage: the bot user should be added to one room, such as the "Suppression Test" room, which preferrably is private and unsearchable.
    # For the purposes of this prototype, the ConversatoinID of this  administrative room has been hardcoded.

    # In this room, or any room in which the bot user is a member, any user can type
    #     suppress <messageID>
    # in order to have that message suppressed.  The <messageID> is obtained by clicking on the timestampe of the message.
    # The bot will convert the URL unsafe messageID to the correct URL safe format, and suppress the message.
    # Example:

    #     suppress eU8++8VJ7dA8O7vCkvno73///qOBg+l3dA==
    # The pod will communicate its success in suppressing the message, and the message will be immediately suppressed.
    # There currently is no API call to undo this action, and the suppression is permanent.  Per the API call, this action
    # will be logged in the Content Export.

    # In order to get a help message, a user may also type in a room a request for help:
    #    suppress help

# ---------------------------------------------------------------------------------------------------------
# Fill in these Variables

    $certificateFileAndPath =     "C:\mycerts\bot.user1.p12"
    $certificateFilePassword =    "changeit"

    $sessionAuthUrl =  "https://mycompany-api.symphony.com:8444/sessionauth/v1/authenticate"
    $keyAuthUrl =  "https://mycompany-api.symphony.com/keyauth/v1/authenticate"
    $agentUrl =  "https://mycompany.symphony.com/agent"
    $podUrl =  "https://mycompany.symphony.com:443/pod"

    #Conversation ID for the private unsearchable administrative room
    $ConversationID = "MBu8Lq8QYTFGnx/DuCh/lX///p2NPCsOdA=="



    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #currently this only supports unauthenticating proxys 
    #$proxy = "-Proxy http://myproxy:8888/"

# Script Body


Clear-Host


# Generate a URLSafe Base64 conversion of the Conversation ID
$ConversationID = $ConversationID -replace "/","_"
$ConversationID = $ConversationID -replace '\+',"-" 

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Clean up URLs so they matche what is expected in later function calls
if ($podUrl  -inotmatch "/pod") { $podUrl = $podUrl + "/pod/" }
if ($agentUrl  -inotmatch "/agent") { $agentUrl = $agentUrl + "/agent/" }
if ($sessionAuthUrl  -inotmatch "/sessionauth/v1/authenticate") { $sessionAuthUrl = $sessionAuthUrl + "/sessionauth/v1/authenticate/" }
if ($keyAuthUrl  -inotmatch "/keyauth/v1/authenticate") { $keyAuthUrl = $keyAuthUrl + "/keyauth/v1/authenticate/" }


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

# Define our match regex
$MessageIDMatch = ".*suppress\s+(.*)==.*"

#Function Declarations
function getSessionAuthToken {

    try {
        $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -CertificateThumbprint $certificateObject.Thumbprint).token
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

function getStreamId {
   try {        $streamID = (Invoke-RestMethod -Method POST -Uri $datafeedUrl -Headers $global:hdrs -ContentType 'application/json').id
    } catch {

        Write-Host "Failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to create datafeed  endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$datafeedUrl'" -ForegroundColor white -BackgroundColor red
        Write-Host "  FAILED to obtain datafeedID.  Exiting." -ForegroundColor white -BackgroundColor red
        exit
    }
  return $streamID
}

function processError ($reason,$status,$exception) {
Write-Host "Received error on read or suppress.  Reason: $reason Status: $status Exception: $exception"



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
$sessionAuthToken=getSessionAuthToken
$keyManagerToken = getKeyAuthToken
$datafeedUrl = "$agentUrl/v4/datafeed/create"
$streamID = getStreamId
$readUrl = "$agentUrl/v4/datafeed/$streamID/read"

Write-Host "---Setup complete.  Waiting for suppression requests."
# This is a daemon, so run forever
# In this loop, we camp out on the datafeed and wait for messages.  When we get a message, we look for
# keyword "suppression", and then we process.  Everything else we ignore.

While($true) {

  try {
          $Result = (Invoke-RestMethod -Method GET  -Headers $global:hdrs  -Uri "$readUrl").payload.messageSent.message.message
	  if ($Result -match $MessageIDMatch -and $Result -notmatch "I am a Suppression Bot") {

        #drop messageml
        $Result -match "suppress (?<content>.*)</p>"
        $Result=$matches.content

	    # Generate a URLSafe Base64 conversion of the Message ID
	    $messageID = $Result -replace $MessageIDMatch, '$1'
	    $messageID = $messageID -replace "/","_"
	    $messageID = $messageID -replace '\+',"-" 
        $messageID = $messageID -replace ' ',""
        $messageID = $messageID -replace '==',""

	    Write-Host "Found message: $Result for messageID $messageID "
  	    $user = $_.fromUserId
	    #Write-Host "From User: $user $_ $Result.fromUserId"
	    
	   # Message the user
 	    try {
		  $msg = @{}
		  $msg.Add("message","Received your request for  message ID $messageID.  This is a permanent and irreversible operation. Suppressing message now.")
	 	  $msg.Add("format","TEXT")
		  $msgjson = $msg | ConvertTo-Json
Write-Host "Calling Invoke-RestMethod -Method POST  -ContentType 'application/json' -Headers $global:hdrs -Body $msgjson -Uri $agentUrl/v2/stream/$ConversationID/message/create"
		  $messageResult = (Invoke-RestMethod -Method POST  -ContentType 'application/json' -Headers $global:hdrs -Body $msgjson -Uri $agentUrl/v2/stream/$ConversationID/message/create)
		} catch { 
		  Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    		  Write-Host "Current endpoint: '$agentUrl/v2/stream/$ConversationID/message/create'" -ForegroundColor white -BackgroundColor red
		processError($($_.CategoryInfo.Reason), $($_.Exception.Status), $($_.Exception))
		}
	  
	  # Perform the suppression
 	  try {
                  $messageResult = (Invoke-RestMethod -Method POST  -ContentType 'application/json' -Headers $global:hdrs -Body $msgjson -Uri $podUrl/v1/admin/messagesuppression/$MessageID/suppress)
                } catch {
                  Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
                  Write-Host "Current endpoint: '$podUrl/v1/admin/messagesuppression/$MessageID/suppress'" -ForegroundColor white -BackgroundColor red
	

		  $msg = @{}                  
		  $msg.Add("message","I had an issue with message ID $messageID.  The operation did not complete. Please check that you have a correct message ID format.  You can just cut+paste and I will take care of making it a URL safe Message ID. ")
                  $msg.Add("format","TEXT")
                  $msgjson = $msg | ConvertTo-Json
                  $messageResult = (Invoke-RestMethod -Method POST  -ContentType 'application/json' -Headers $global:hdrs -Body $msgjson -Uri $agentUrl/v2/stream/$ConversationID/message/create)
		processError($($_.CategoryInfo.Reason), $($_.Exception.Status), $($_.Exception))
                }
Write-Host "Completed: $messageResult"

    } ElseIf ($Result -match "suppress help") {
	$msg = @{}
        $msg.Add("message",'I am a Suppression Bot.
You are in this private unsearchable room because you have been specially invited by an administrator.  
You can suppress messages anywhere in your pod by entering in this room the keyword "suppress" followed by a cut+paste of a Message ID.  
Find the Message ID by clicking on the timestamp of the message.  It typically looks something like MlAAAAXB+rpBMut9d4tpQn///qI3ipmCdA==.  Just cut+paste the whole thing and I will take care of converting it.  
Because this bot uses datafeed, you can also suppress messages anywhere in your pod from a room in which this bot user is added.
Your actions in this room are permanent and irreversible so please act responsibly..')
        $msg.Add("format","TEXT")
        $msgjson = $msg | ConvertTo-Json
        $messageResult = (Invoke-RestMethod -Method POST  -ContentType 'application/json' -Headers $global:hdrs -Body $msgjson -Uri $agentUrl/v2/stream/$ConversationID/message/create)
}

 
	  Start-Sleep -s 3 
  } catch {

    Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    Write-Host "Current endpoint: '$readUrl'" -ForegroundColor white -BackgroundColor red
    Write-Host "Failed to connect on $readUrl."
    Write-Host "     ...Sleeping while you try to figure out what is wrong. "
Start-Sleep -s 30
  }
} 
  Write-Host "Elapsed time: " (NEW-TIMESPAN –Start $beforeTime –End (Get-Date)) 

exit
