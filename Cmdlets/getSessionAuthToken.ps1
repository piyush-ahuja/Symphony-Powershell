function getSessionAuthToken($sessionAuthUrl,$Thumbprint) {

    try {
        $sessionAuthToken = (Invoke-RestMethod -Method POST -Uri $sessionAuthUrl -CertificateThumbprint $Thumbprint).token
    } catch {
        Write-Host "failed with error '$($_.CategoryInfo.Reason) - $($_.Exception.Status) - $($_.Exception)'"
        Write-Host "ERROR: REST call to sessionauth endpoint failed with error '$($_.Exception.Status)'" -ForegroundColor white -BackgroundColor red
        Write-Host "Current endpoint: '$sessionAuthUrl'" -ForegroundColor white -BackgroundColor red
        Write-Host "  FAILED to obtain SessionAuthToken.  Please check the health of your pod.  Exiting." -ForegroundColor white -BackgroundColor red
        exit
    }
  return $sessionAuthToken
}
