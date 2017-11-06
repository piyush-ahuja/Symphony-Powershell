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
    # To successfully authorize, you must upload the p12 you use in $certificateFileAndPathb into the Certificate Manager in Windows.  To do this, simply click on the p12 file in File Explorer, and accept all of the defaults when the Certificate manager opens.
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
# Notes on the Script

    # This script was designed to read a csv file of user ids and add the users to a room with a given Conversation ID.

# Fill in these Variables

    $certificateFileAndPath =     "C:\mycerts\bot.user1.p12"
    $certificateFilePassword =    "changeit"

    $sessionAuthUrl =  "https://mycompany-api.symphony.com/sessionauth/v1/authenticate"
    $podUrl =  "https://mycompany.symphony.com/pod"

    # Conversation ID

    # ConversationID - This is the Room Id, and it needs to be convereted.  The + becomes -, and / becomes _, the = are dropped
    #$UnconvertedConversationID = "2Kb108TZEOmfpxSgWsXoIn///qJWYIgTdA=="
    #$ConversationID = "2Kb108TZEOmfpxSgWsXoIni___qJWYIgTdA"
    $ConversationID = "NK8FPo0RQCXKgmWq0Lavx3___qE20EX7dA"

    # CSV file that contains list of usernames.  If you used excel, remove the ""
    $UserNamesFile = "SymphonyUserNames.csv"

    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #currently this only supports unauthenticating proxys 
    #$proxy = "http://myproxy:8888/"

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

# Get p12 certificate thumbprint

try {
        $certificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $certificateObject.Import($certificateFileAndPath, $certificateFilePassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet)
        Write-Host $certificateObject.Thumbprint

} catch {

    Write-Host "ERROR: Certificate read failed with error '$($_.Exception.InnerException)'" -ForegroundColor white -BackgroundColor red
    exit
}

# Get SessionAuth token

try {
        if ($proxy) { $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -Proxy $proxy -CertificateThumbprint $certificateObject.Thumbprint).token }
    
        else        { $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -CertificateThumbprint $certificateObject.Thumbprint).token }
    }

 catch {

        Write-Host "ERROR: REST call to sessionauth endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$sessionAuthUrl'" -ForegroundColor white -BackgroundColor red
        exit
       }

# Define Headers
$hdrs = @{}
$hdrs.Add("sessionToken",$sessionAuthToken)

# Open CSV file and read entries
Write-Host "Opening file $UserNamesFile"
Get-Content .\$UserNamesFile | ForEach-Object {
  Write-Host "Found username $_.  Looking up ID "
  $user=$_

# Look up ID from email
  try {
        if ($proxy) {    $fullUserList = Invoke-RestMethod -Method GET -Headers $hdrs  -Proxy $proxy -Uri "$podUrl/v1/user?email=$_" }
        else        {    $fullUserList = Invoke-RestMethod -Method GET -Headers $hdrs -Uri "$podUrl/v1/user?email=$_" }

  } catch {

    Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    Write-Host "Current endpoint: '$podUrl/v1/admin/user/list'" -ForegroundColor white -BackgroundColor red

  }

$id=$fullUserList.id
Write-Host "Found Id $id"
$DataList = @{}
$DataList.Add("id",$id)
$json = $DataList | ConvertTo-Json
Write-Host "Json: $json"

# Add each entry to the ConversationID
  try {
        if ($proxy) {    $Result = Invoke-RestMethod -Body $json -Method POST -ContentType 'application/json' -Headers $hdrs  -Proxy $proxy -Uri "$podUrl/v1/room/$ConversationID/membership/add"}
        else        {    $Result = Invoke-RestMethod -Body $json -Method POST -ContentType 'application/json' -Headers $hdrs -Uri "$podUrl/v1/room/$ConversationID/membership/add"}

Write-Host "Added $user ID $id Result: $Result"

  } catch {

    Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    Write-Host "Current endpoint: '$podUrl/v1/room/$ConversationID/membership/add'" -ForegroundColor white -BackgroundColor red
Write-Host "Failed to Add $user ID $id.  User might be de-activated.  Activate user to add them to the room."
  }
Start-Sleep -s 3
}

Write-Host "Elapsed time: " (NEW-TIMESPAN –Start $beforeTime –End (Get-Date))


exit

