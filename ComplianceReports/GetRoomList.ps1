# Notes on the Script

    # This script was designed to output a wealth of data about every Symphony user to a CSV file for further examination in Excel
    # This is a Windows PowerShell Script and it was tested on Powershell 5.1 which can be found here: https://www.microsoft.com/en-us/download/details.aspx?id=54616
    # You may also enjoy the Windows Powershell Ingtegrated Script Environment (ISE) described here: https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/ise/introducing-the-windows-powershell-ise
    # You must run "Set-ExecutionPolicy RemoteSigned" as described here: http://windowsitpro.com/powershell/running-powershell-scripts-easy-1-2-3
    # Modify the "Fill in these Variables" section below for your specific pod and environment
    # Summary information is output to the screen and a CSV file is written to disk at the output path you sepcify with details on all users
    # The CSV file was designed for Microsoft Excel. To format in Excel follow these instructions:
        # 1. Open the CSV File in Excel
        # 2. Select Column A and click Data > "Text To Columns"
        # 3. Select "Delimited" and click Next
        # 4. Select only "Comma" and a "Text qualifier" of a single quote (') and click Finish

        
# Fill in these Variables


    #$sessionAuthUrl =  "https://mycompany-api.symphony.com:443/sessionauth/v1/authenticate"
    #$podUrl =  "https://mycompany.symphony.com:443"

    $outputPath =   "c:\temp\"

    
    # Optionally set a certificate or hard code a session ID below. Also add this certificate to your WIndows certificate store.
        #$certificateFileAndPath =     "C:\mycert\Symphonyuser.p12"
        #$certificateFilePassword =    "changeit"

    # Comment out the line below to access a certificate and get a session id in realtime. 
    # Uncomment and specific a previously acquired session token to skip certificate authentication
        #$sessionAuthToken = ""


    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #$proxy = "http://localhost:8888/"
    
# Script Body

  $streamCount=0

Clear-Host
Write-Host
Write-Host
Write-Host
Write-Host
Write-Host
Write-Host
$beforeTime = Get-Date
Write-Host "Starting at " $beforeTime.ToLocalTime()


# Skip sessionauth if session ID is specified above

if (! $sessionAuthToken) {

    # Get p12 certificate thumbprint

    try {
            $certificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $certificateObject.Import($certificateFileAndPath, $certificateFilePassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet)
            #Write-Host $certificateObject.Thumbprint

    } catch {

        Write-Host "ERROR: Certificate read failed with error '$($_.Exception.InnerException)'" -ForegroundColor white -BackgroundColor red
        exit
    }



    # Get SessionAuth token

    try {

        if ($proxy) { $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -Proxy $proxy -ProxyUseDefaultCredentials -CertificateThumbprint $certificateObject.Thumbprint).token }
    
        else        { $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -CertificateThumbprint $certificateObject.Thumbprint).token }

    } catch {

        Write-Host "ERROR: REST call to sessionauth endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$sessionAuthUrl'" -ForegroundColor white -BackgroundColor red

        exit
    }

}


# Confirm we have a session auth token before proceeding
if (! $sessionAuthToken) {
            
            Write-Host "Exiting because no sessionAuthToken has been specified"  -ForegroundColor white -BackgroundColor red
            Exit

        }


# Get Full Symphony chat list
$hdrs = @{}
$hdrs.Add("sessionToken",$sessionAuthToken)


# confirm we have a valid session
try {

        if ($proxy) { $sessionauthvalid = (Invoke-RestMethod -contentType 'application/json' -Method GET -Headers $hdrs -Uri "$($podUrl)/pod/v1/sessioninfo" -Proxy $proxy -ProxyUseDefaultCredentials)  }
    
        else        { $sessionauthvalid = (Invoke-RestMethod -contentType 'application/json' -Method GET -Headers $hdrs -Uri "$($podUrl)/pod/v1/sessioninfo") }
        
 } catch {

        Write-Host "ERROR: Bad sessionAuthToken value specified!" -ForegroundColor white -BackgroundColor red
        exit
 }


# Confirm we have a valid session auth token before proceeding
if (! $sessionauthvalid.userId ) {
            
            Write-Host "Exiting because sessionauth token is invalid"  -ForegroundColor white -BackgroundColor red
            Exit

        }


$listURL = "$($podUrl)/pod/v1/admin/streams/list"
$limit=100
$skip=$limit * -1

$totalStreams = 0
$totalUserStreams = 0
$roomCount = 0
$imCount = 0
$mimCount = 0
$postCount = 0

#Prep for output of CSV
$linuxOrigin=[timezone]::CurrentTimeZone.ToLocalTime([datetime]'1/1/1970')
$formattedBeforeTime = Get-Date -Format o

$filename = $formattedBeforeTime | foreach {$_ -replace ":", "."} | foreach {$_ -replace "-", "_"}
$fullPathFilename = "$outputPath\SymphonyChatExport_$filename.csv"

$header="'Stream Type','Stream Name',isExternal,isActive,User,Email,Company"

try {
         $header | Out-File $fullPathFilename

        } catch {

             Write-Host "ERROR: CSV File Write failed with error '$($_.Exception.Message)'" -ForegroundColor white -BackgroundColor red
             exit
         }



#Start Loop through chats
do {


#Write-Host "Now on $($totalStreams) of $($chatCount) chats with skip: $($skip)"


#Get next limit block of chats

    $skip = $skip + $limit
    $listUrl = "$($podUrl)/pod/v1/admin/streams/list?skip=$($skip)&limit=$($limit)"

    try {

        if ($proxy) { $fullChatList = Invoke-RestMethod -contentType 'application/json' -Method POST -Headers $hdrs -Uri $listUrl -Proxy $proxy -ProxyUseDefaultCredentials  }
    
        else        { $fullChatList = Invoke-RestMethod -contentType 'application/json' -Method POST -Headers $hdrs -Uri $listUrl }
        
        } catch {

            Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
            Write-Host "Current endpoint: '$podUrl/pod/v1/admin/user/list'" -ForegroundColor white -BackgroundColor red
            exit
        }

    
    $chatCount=$fullChatList.Count

    #Loop through current block of chats

    foreach ($stream in $fullChatList.streams ) {

        $streamInfoURL = "$podUrl/pod/v1/streams/$($stream.id)/info"

        if ($proxy) { $streamInfo = Invoke-RestMethod -Method GET -Headers $Hdrs -Uri $streamInfoURL -Proxy $proxy -ProxyUseDefaultCredentials  }
    
        else        { $streamInfo = Invoke-RestMethod -Method GET -Headers $Hdrs -Uri $streamInfoURL }
        

        $members = $streamInfo.streamAttributes.members

        $totalStreams = $totalStreams+1
   
        $pctComplete=[math]::Round(($totalStreams/$chatCount)*100)
        Write-Progress -Activity "Looping through all Symphony chats..." -PercentComplete $pctComplete -CurrentOperation "$pctComplete% complete of $chatCount chats" -Status "Please wait."

        #fix stream as Excel doesn't like =
        $fixedStreamID = $stream.id | foreach {$_ -replace "=", "_"}

        #get chat room/IM information
        switch ($streamInfo.streamType.type)            { 

            "ROOM"  { 
                    
                        $roomCount = $roomCount + 1
                 
                        $streamName="'ROOM','$($stream.attributes.roomName)'"
                        $members = New-Object System.Collections.ArrayList
                        $roomMemberUrl = "$podUrl/pod/v2/room/$($stream.id)/membership/list"

                        if ($proxy) { $roomMembers = Invoke-RestMethod -Method GET -Headers $Hdrs -Uri $roomMemberUrl -Proxy $proxy -ProxyUseDefaultCredentials  }
    
                        else        { $roomMembers = Invoke-RestMethod -Method GET -Headers $Hdrs -Uri $roomMemberUrl }
                        

                        foreach ($member in $roomMembers) {

                            $members.Add($($member.id)) > $null
                        }
                    }
    
            "IM"    { 
                        $imCount = $imCount + 1
                        $streamName="'IM','$fixedStreamID'"
                    }
        
            "MIM"   { 
                        $mimCount = $mimCount + 1
                        $streamName="'MIM','$fixedStreamID'"
                    }

            "POST"  { 
                        $postCount = $postCount + 1    
                        $streamName="'POST','$fixedStreamID'"
                     }
        
                
            default { Write-Host "Unsupported Stream type '$($stream.type)'" -ForegroundColor white -BackgroundColor red
                    $streamName = ""  }
         }

         #some debug code
         if ($stream.id -eq "IUtfim0hEHwjdjciNDulz3___q5UI2LhdA") {

                Write-Host "Pause"
            }
       

        #If I was able to determine the type of stream then loop through each member
        if ( $streamName ) {
            
            foreach ($userID in $members) {

                   $userDetail=""
                   $userUrl="$podUrl/pod/v2/user?uid=$($userID)&local=true"

                   if ($proxy) { $userDetail = Invoke-RestMethod -Method GET -Headers $Hdrs -Uri $userUrl -Proxy $proxy -ProxyUseDefaultCredentials  }
    
                   else        { $userDetail = Invoke-RestMethod -Method GET -Headers $Hdrs -Uri $userUrl }

                   
                   $username = "'$($userDetail.username)','$($userDetail.emailAddress)','$($userDetail.company)'"

                    if ( ! $userDetail) {
                    
                        $userUrl="$podUrl/pod/v2/user?uid=$($userID)&local=false"

                        if ($proxy) { $userDetail = Invoke-RestMethod -Method GET -Headers $Hdrs -Uri $userUrl -Proxy $proxy -ProxyUseDefaultCredentials  }
    
                        else        { $userDetail = Invoke-RestMethod -Method GET -Headers $Hdrs -Uri $userUrl }

                        
                        $username = "'$($userDetail.displayName)','','$($userDetail.company)'"
                    
                    }

                     if ( ! $userDetail) {

                        $username = "'$($userID)','User Deactivated by Xpod Partner','',''"
                    
                        #Write-Host "User not found for thread $($streamName), external $($streamInfo.crossPod) and UserID $($userID)"  -ForegroundColor white -BackgroundColor red
                    
                    }


                    #Write-Host "$streamName, $username"

                    $record = "$streamName,$($streamInfo.crossPod),$($streamInfo.active),$username"
                    try {
                            [string]$record | Out-File $fullPathFilename -Append

                    } catch {

                        Write-Host "ERROR: CSV File Write failed with error '$($_.Exception.Message)'" -ForegroundColor white -BackgroundColor red
                        exit
                    }

                    $totalUserStreams = $totalUserStreams + 1
                    }
            }

}

} Until ( $totalStreams -ge $chatCount )


Write-Host ""
Write-Host "Found $($chatCount) chats"
Write-Host "$($roomCount) Rooms, $($imCount) IMs and $($mimCount) MIMs"
Write-Host ""
Write-Host "Counted $($totalUserStreams) user/chat relationships"
Write-Host ""
Write-Host "Wrote report to $($fullPathFilename)"
Write-Host ""
Write-Host "Elapsed time: " (NEW-TIMESPAN -Start $beforeTime -End (Get-Date)) 
