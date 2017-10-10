function getKeyAuthToken($keyAuthUrl,$Thumbprint) {

    try {
        $keyManagerToken = (Invoke-RestMethod -Method POST -Uri $keyAuthUrl -CertificateThumbprint $Thumbprint).token 
    } catch {

        Write-Host "Failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to keyauth endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$keyAuthUrl'" -ForegroundColor white -BackgroundColor red
        Write-Host "  FAILED to obtain KeyAuthToken.  Please check the health of your pod.  Exiting." -ForegroundColor white -BackgroundColor red
Write-Host "---Setup complete.  Waiting for UserJoinedRoom events."
        exit
    }
  $global:hdrs.Set_Item("keyManagerToken",$keyManagerToken)
  return $keyManagerToken
}

