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
        # 4. Select only "Comma" and a "Text qualifier" of a single quote (') and click Next
        # 5. In the Data format screen scroll to teh right to find the 3 dates (created, last updated and last login)
        # 6. Change the "Column data format" to Date/YMD for each and click Finish
        # 7. Format the ID (column A) as a number with zero decimal places
        

# Fill in these Variables

    $certificateFileAndPath =     "C:\mycerts\my_Bot_cert.p12"
    $certificateFilePassword =    "changeit"

    
    $sessionAuthUrl =  "https://mycompany-api.symphony.com/sessionauth/v1/authenticate"
    $podUrl =  "https://mycompany.symphony.com:443"


    #If you have an outbound proxy then uncomment this line and add in your HTTP proxy value such as "http://myproxy:8888"
    #currently this does support authenticating proxys with your current user context
    #$proxy = "http://localhost:8888/"

    $outpoutPath =   "c:\temp\"


# Script Body

  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $adminCount=0
  $superAdminCount=0
  $systemCount=0
  $l1SupportCount=0
  $l2SupportCount=0
  $complianceCount=0
  $superComplianceCount=0
  $userCount=0
  $totalCount=0
  $enabled=0
  $newEntitlement=""

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
        #Write-Host $certificateObject.Thumbprint

} catch {

    Write-Host "ERROR: Certificate read failed with error '$($_.Exception.InnerException)'" -ForegroundColor white -BackgroundColor red
    exit
}



# Get SessionAuth token

try {
        if ($proxy) { $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -Proxy $proxy -ProxyUseDefaultCredentials -CertificateThumbprint $certificateObject.Thumbprint).token }
    
        else        { $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -CertificateThumbprint $certificateObject.Thumbprint).token }
    }

 catch {

        Write-Host "ERROR: REST call to sessionauth endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$sessionAuthUrl'" -ForegroundColor white -BackgroundColor red
        exit
       }


# Get Full Symphony userlist
$hdrs = @{}
$hdrs.Add("sessionToken",$sessionAuthToken)

try {
        if ($proxy) {    $fullUserList = Invoke-RestMethod -Method GET -Headers $hdrs  -Proxy $proxy -ProxyUseDefaultCredentials -Uri "$podUrl/pod/v1/admin/user/list"}
        else        {    $fullUserList = Invoke-RestMethod -Method GET -Headers $hdrs -Uri "$podUrl/pod/v1/admin/user/list"}



} catch {

    Write-Host "ERROR: REST call to pod endpoint failed with error '$($_.Exception.Status) - $($_.Exception)'" -ForegroundColor white -BackgroundColor red
    Write-Host "Current endpoint: '$podUrl/pod/v1/admin/user/list'" -ForegroundColor white -BackgroundColor red

    exit
}



$userCount=$fullUserList.Count


#Prep for output of CSV
$linuxOrigin=[timezone]::CurrentTimeZone.ToLocalTime([datetime]'1/1/1970') 
$formattedBeforeTime = Get-Date -Format o

$filename = $formattedBeforeTime | foreach {$_ -replace ":", "."} | foreach {$_ -replace "-", "_"}
$fullPathFilename = "$outpoutPath\SymphonyUserExport_$filename.csv"

$fullUserList | foreach { 

   $totalCount=$totalCount+1
   
   if ($proxy) { $userDetail = Invoke-RestMethod -Method GET -Headers $hdrs -Proxy $proxy -ProxyUseDefaultCredentials -Uri "$podUrl/pod/v1/admin/user/$_" }
   else        { $userDetail = Invoke-RestMethod -Method GET -Headers $hdrs -Uri "$podUrl/pod/v1/admin/user/$_" } 


    
   # Symphony doesn't send a user.userSystemInfo.createdBy for original system accounts so we need to check for that
   if($userDetail.userSystemInfo.createdBy) {
        $creatorUrl="$podUrl/pod/v1/admin/user/$($userDetail.userSystemInfo.createdBy)"
        #Write-Host $creatorUrl
        if ($proxy) { $creatorDetail = Invoke-RestMethod -Method GET -Headers $hdrs -Proxy $proxy -ProxyUseDefaultCredentials -Uri $creatorUrl }
        else        { $creatorDetail = Invoke-RestMethod -Method GET -Headers $hdrs -Uri $creatorUrl }

        $createdBy=($creatorDetail.userAttributes.userName)
        }
   Else { $createdBy= "SYSTEM" }


  $userName = $userDetail.userAttributes.userName
  $emailAddress=$($userDetail.userAttributes.emailAddress)
  $displayName=$($userDetail.userAttributes.displayName)
  $accountType=$userDetail.userAttributes.accountType
  $accountType=$userDetail.userAttributes.accountType
  $status=$userDetail.userSystemInfo.status

  if ($status -eq "ENABLED") {$enabled = $enabled+1}


  $department=$($userDetail.userAttributes.department)
  $division=$($userDetail.userAttributes.division)
  $location = $($userDetail.userAttributes.location)
  $jobFunction = $($userDetail.userAttributes.jobFunction)
  $createdDate=$linuxOrigin.AddSeconds($userDetail.userSystemInfo.createdDate/1000).ToString("yyyy-MM-dd hh:mm:ss")
  $lastUpdatedDate=$linuxOrigin.AddSeconds($userDetail.userSystemInfo.lastUpdatedDate/1000).ToString("yyyy-MM-dd hh:mm:ss")
  $lastLoginDate=$linuxOrigin.AddSeconds($userDetail.userSystemInfo.lastLoginDate/1000).ToString("yyyy-MM-dd hh:mm:ss")
  
  #Roles
  $SUPER_ADMINISTRATOR=$userDetail.roles.Contains("SUPER_ADMINISTRATOR")
  $ADMINISTRATOR=$userDetail.roles.Contains("ADMINISTRATOR")
  $SUPER_COMPLIANCE_OFFICER=$userDetail.roles.Contains("SUPER_COMPLIANCE_OFFICER")
  $COMPLIANCE_OFFICER=$userDetail.roles.Contains("COMPLIANCE_OFFICER")
  $L2_SUPPORT=$userDetail.roles.Contains("L2_SUPPORT")
  $L1_SUPPORT=$userDetail.roles.Contains("L1_SUPPORT")
  
  #Service account roles not currently available
  $USER_PROVISIONING=$userDetail.roles.Contains("USER_PROVISIONING")
  $CONTENT_MANAGEMENT=$userDetail.roles.Contains("CONTENT_MANAGEMENT")
  $KEY_MANAGER=$userDetail.roles.Contains("KEY_MANAGER")
  $CONTENT_EXPORT_SERVICE=$userDetail.roles.Contains("CONTENT_EXPORT_SERVICE")


  #GetEntitlements Loop

   if ($proxy) {   $userEntitlements = Invoke-RestMethod -Method GET -Headers $hdrs -Proxy $proxy -ProxyUseDefaultCredentials -Uri "$podUrl/pod/v1/admin/user/$_/features" }
   else        {   $userEntitlements = Invoke-RestMethod -Method GET -Headers $hdrs -Uri "$podUrl/pod/v1/admin/user/$_/features" }



   For ($i=0; $i -le ($userEntitlements.GetLength(0)-1); $i++) {
       
       $entitlement = $userEntitlements.GetValue($i)

       switch ($entitlement.entitlment) 
            { 

                "canCreatePublicRoom"                 { $canCreatePublicRoom =    $entitlement.enabled }
                "isExternalRoomEnabled"               { $isExternalRoomEnabled =  $entitlement.enabled }
                "delegatesEnabled"                    { $delegatesEnabled =       $entitlement.enabled }
                "isExternalIMEnabled"                 { $isExternalIMEnabled =    $entitlement.enabled }
                "canShareFilesExternally"             { $canShareFilesExternally =$entitlement.enabled }
                "sendFilesEnabled"                    { $sendFilesEnabled =       $entitlement.enabled }
                "canCreatePushedSignals"              { $canCreatePushedSignals = $entitlement.enabled }
                "canUpdateAvatar"                     { $canUpdateAvatar =        $entitlement.enabled }
                "canProjectInternalScreenShare"       { $canProjectInternalScreenShare = $entitlement.enabled }
                "postWriteEnabled"                    { $postWriteEnabled =       $entitlement.enabled }
                "canViewInternalScreenShare"          { $canViewInternalScreenShare = $entitlement.enabled }
                "canUseInternalVideo"                 { $canUseInternalVideo =    $entitlement.enabled }
                "postReadEnabled"                     { $postReadEnabled =        $entitlement.enabled }
                "canUseInternalAudio"                 { $canUseInternalAudio =    $entitlement.enabled }
                "canCreateMultiLateralRoom"           { $canCreateMultiLateralRoom = $entitlement.enabled }
                "canUseFirehose"                      { $canUseFirehose =         $entitlement.enabled }
                "canViewInternalScreenShareMobile"    { $canViewInternalScreenShareMobile = $entitlement.enabled }
                "canJoinMultiLateralRoom"             { $canJoinMultiLateralRoom = $entitlement.enabled }
                "mustBeRecorded"                      { $mustBeRecorded = $entitlement.enabled }
                "canUseCompactMode"                   { $canUseCompactMode = $entitlement.enabled }
                "canUseInternalVideoMobile"           { $canUseInternalVideoMobile = $entitlement.enabled }
                "canUseInternalAudioMobile"           { $canUseInternalAudioMobile = $entitlement.enabled }
                "canProjectInternalScreenShareMobile" { $canProjectInternalScreenShareMobile = $entitlement.enabled }
                "canIntegrateEmail"                   { $canIntegrateEmail = $entitlement.enabled }
                "canChatWithCepUser"                  { $canChatWithCepUser = $entitlement.enabled }



                default {
                            If (($newEntitlement -like "*$($entitlement.entitlment)*") -Or ($entitlement.entitlment -Contains "isScreenSharingEnabled")) { # do nothing
                                                                                         }
                            else {
                                    $newEntitlement = $newEntitlement + $($entitlement.entitlment)
                                    Write-Host "ERROR: Unknown user entitlement '$($entitlement.entitlment)'. Update script." -ForegroundColor white -BackgroundColor red
                                 }
                        }

 }
 }
 
   #GetPartnerApps Loop
  if ($proxy) {   $userApps = Invoke-RestMethod -Method GET -Headers $hdrs -Proxy $proxy -ProxyUseDefaultCredentials -Uri "$podUrl/pod/v1/admin/user/$_/app/entitlement/list" }
  else        {   $userApps = Invoke-RestMethod -Method GET -Headers $hdrs -Uri "$podUrl/pod/v1/admin/user/$_/app/entitlement/list" }



   For ($i=0; $i -le ($userApps.GetLength(0)-1); $i++) {
       
       $app = $userApps.GetValue($i)

       switch ($app.appId) 
            { 

                "ChartIQApp"                    { $ChartIQApp=$app.install
                                                  $ChartIQVisible=$app.listed }

                "fintech-app"                   { $fintechapp=$app.install
                                                  $fintechappVisible=$app.listed }

                "githubWebHookIntegration"      { $githubWebHookIntegration=$app.install
                                                  $githubWebHookIntegrationVisible=$app.listed }

                "hvstApp"                       { $hvstApp=$app.install
                                                  $hvstAppVisible=$app.listed }

                "infrontApp"                    { $infrontApp=$app.install
                                                  $infrontAppVisible=$app.listed }

                "jiraWebHookIntegration"        { $jiraWebHookIntegration=$app.install
                                                  $jiraWebHookIntegrationVisible=$app.listed }

                "spcapiq"                       { $spcapiq=$app.install
                                                  $spcapiqVisible=$app.listed }

                "salesforceWebHookIntegration"  { $salesforceWebHookIntegration=$app.install
                                                  $salesforceWebHookIntegrationVisible=$app.listed }

                "selerity"                      { $selerity=$app.install
                                                  $selerityVisible=$app.listed }

                "simpleWebHookIntegration"      { $simpleWebHookIntegration=$app.install
                                                  $simpleWebHookIntegrationVisible=$app.listed }


                "zapierWebHookIntegration"      { $zapierWebHookIntegration=$app.install
                                                  $zapierWebHookIntegrationVisible=$app.listed }


                "box"                           { $box=$app.install
                                                  $boxVisible=$app.listed }


                "djApp"                         { $djApp=$app.install
                                                  $djAppVisible=$app.listed  }


         #default {Write-Host "ERROR: Unknown partner app '$($app.appId)'" -ForegroundColor white -BackgroundColor red }
            }

 }

 
   if ($totalCount -eq 1) {
        
        $header="ID,userName,emailAddress,displayName,status,accountType,department,division,location,jobFunction,createdBy,createdDate,lastUpdatedDate,lastLoginDate"
        $header= $header + ",SUPER_ADMINISTRATOR,ADMINISTRATOR,SUPER_COMPLIANCE_OFFICER,COMPLIANCE_OFFICER,L2_SUPPORT,L1_SUPPORT,CONTENT_MANAGEMENT,USER_PROVISIONING,KEY_MANAGER,CONTENT_EXPORT_SERVICE"
        $header= $header+  ",isExternalIMEnabled,isExternalRoomEnabled,canShareFilesExternally,canCreatePublicRoom,delegatesEnabled,sendFilesEnabled,canCreatePushedSignals,canUpdateAvatar"
        $header= $header+  ",canProjectInternalScreenShare,postWriteEnabled,canViewInternalScreenShare,canUseInternalVideo,postReadEnabled,canUseInternalAudio"
        $header= $header+  ",canCreateMultiLateralRoom,canUseFirehose,canViewInternalScreenShareMobile,canJoinMultiLateralRoom,mustBeRecorded,canUseCompactMode,canUseInternalVideoMobile,canUseInternalAudioMobile,canProjectInternalScreenShareMobile,canIntegrateEmail,canChatWithCepUser"
        $header= $header+  ",ChartIQApp,ChartIQVisible,fintech-app,fintechappVisible,githubWebHookIntegration,githubWebHookIntegrationVisible,hvstApp,hvstAppVisible,infrontApp,infrontAppVisible,jiraWebHookIntegration,jiraWebHookIntegrationVisible"
        $header= $header+  ",spcapiq,spcapiqVisible,salesforceWebHookIntegration,salesforceWebHookIntegrationVisible,selerity,selerityVisible,simpleWebHookIntegration,simpleWebHookIntegrationVisible,zapierWebHookIntegration,zapierWebHookIntegrationVisible,box,boxVisible,djApp,djAppVisible"

        try {
                   $header | Out-File $fullPathFilename

        } catch {

            Write-Host "ERROR: CSV File Write failed with error '$($_.Exception.Message)'" -ForegroundColor white -BackgroundColor red
             exit
        }
    }

  
  $output ="$_,$userName,$emailAddress,'$displayName',$status,$accountType,'$department','$division','$location','$jobFunction',$createdBy,$createdDate,$lastUpdatedDate,$lastLoginDate"
  $output = $output + ",$SUPER_ADMINISTRATOR,$ADMINISTRATOR,$SUPER_COMPLIANCE_OFFICER,$COMPLIANCE_OFFICER,$L2_SUPPORT,$L1_SUPPORT,$CONTENT_MANAGEMENT, $USER_PROVISIONING, $KEY_MANAGER, $CONTENT_EXPORT_SERVICE"
  $output = $output + ",$isExternalIMEnabled,$isExternalRoomEnabled,$canShareFilesExternally,$canCreatePublicRoom,$delegatesEnabled,$sendFilesEnabled,$canCreatePushedSignals,$canUpdateAvatar"
  $output = $output + ",$canProjectInternalScreenShare,$postWriteEnabled,$canViewInternalScreenShare,$canUseInternalVideo,$postReadEnabled,$canUseInternalAudio"
  $output = $output + ",$canCreateMultiLateralRoom,$canUseFirehose,$canViewInternalScreenShareMobile,$canJoinMultiLateralRoom,$mustBeRecorded,$canUseCompactMode,$canUseInternalVideoMobile,$canUseInternalAudioMobile,$canProjectInternalScreenShareMobile,$canIntegrateEmail,$canChatWithCepUser"
  $output = $output + ",$ChartIQApp,$ChartIQVisible,$fintechapp,$fintechappVisible,$githubWebHookIntegration,$githubWebHookIntegrationVisible,$hvstApp,$hvstAppVisible,$infrontApp,$infrontAppVisible,$jiraWebHookIntegration,$jiraWebHookIntegrationVisible"
  $output = $output + ",$spcapiq,$spcapiqVisible,$salesforceWebHookIntegration,$salesforceWebHookIntegrationVisible,$selerity,$selerityVisible,$simpleWebHookIntegration,$simpleWebHookIntegrationVisible,$zapierWebHookIntegration,$zapierWebHookIntegrationVisible,$box,$boxVisible,$djApp,$djAppVisible"
  
  
  [string]$output  | Out-File $fullPathFilename -Append
  #Write-Host $output
 

  $superAdmin=0
  $admin=0
  $system=0
  $compliance=0
  $superCompliance=0
  $l1Support=0
  $l2Support=0


  foreach ($role in $userDetail.roles) {

 
    if ($role -eq "SUPER_ADMINISTRATOR") {
        $superAdmin=1
        $superAdminCount=$superAdminCount+1
        $userCount=$userCount-1
    }
    if ($role -eq "ADMINISTRATOR") {
        $admin=1
        $adminCount=$adminCount+1
        $userCount=$userCount-1
    }


    if ($role -eq "SUPER_COMPLIANCE_OFFICER") {
       $superCompliance=1
       $superComplianceCount=$superComplianceCount+1
       $userCount=$userCount-1
    }
    
    if ($role -eq "COMPLIANCE_OFFICER") {
        $compliance=1
        $complianceCount=$complianceCount+1
        $userCount=$userCount-1
    }

  
    if ($role -eq "L2_SUPPORT") {
        $l2Support=1
        $l2SupportCount=$l2SupportCount+1
        $userCount=$userCount-1
    }

    if ($role -eq "L1_SUPPORT") {
        $l1Support=1
        $l1SupportCount=$l1SupportCount+1
        $userCount=$userCount-1
    }
    

  }

    if ($userDetail.userAttributes.accountType -eq "SYSTEM") {
        $system=1
        $systemCount=$systemCount+1
        $userCount=$userCount-1
    }

  $count=$fullUserList.Count
  $pctComplete=[math]::Round(($totalCount/$count)*100)
  Write-Progress -Activity "Looping through all Symphony users..." -PercentComplete $pctComplete -CurrentOperation "$pctComplete% complete of $count users" -Status "Please wait."

  
  }

  Write-Host "Elapsed time: " (NEW-TIMESPAN –Start $beforeTime –End (Get-Date)) 
                              
  Write-Host ""
  Write-Host "Users:             " $userCount
  Write-Host "Super Admins:      " $superAdminCount
  Write-Host "Admins:            " $adminCount
  Write-Host "Super Compliance:  " $superComplianceCount
  Write-Host "Compliance:        " $complianceCount
  Write-Host "L1 Support:        " $l1SupportCount
  Write-Host "L2 Support:        " $l2SupportCount
  Write-Host "System:            " $systemCount
  Write-Host "------------------------"
  Write-Host "Total*:            " ($fullUserList.Count) "($enabled or $([math]::Round(($enabled/$count)*100))% of users are enabled)"

  Write-Host "   * Note that a user can have admin, compliance and support roles"
  Write-Host
  Write-Host "Detailed user data written to '$fullPathFilename'"
