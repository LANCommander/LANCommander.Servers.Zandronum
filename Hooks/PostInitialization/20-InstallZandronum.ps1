#Requires -Modules Logging
#Requires -Modules Hooks

Invoke-Hook "PreInstallZandronum"

Write-Log -Message "Installing Zandronum version ${Env:ZANDRONUM_VERSION}..."

if (-not (Test-Path -Path "${Env:SERVER_DIR}/zandronum-server")) {
    Write-Log "Could not find zandronum-server in ${Env:SERVER_DIR}, proceeding with installation."

    $downloadUrl = "https://zandronum.com/downloads/zandronum${Env:ZANDRONUM_VERSION}-linux-${Env:SERVER_ARCH}.tar.bz2"

    if ($Env:ZANDRONUM_URL -and $Env:ZANDRONUM_URL.Trim().Length -gt 0) {
        Write-Log -Message "Using custom Zandronum download URL from ZANDRONUM_URL environment variable."
        $downloadUrl = $Env:ZANDRONUM_URL
    }

    curl --output /tmp/zandronum.tar.bz2 "$downloadUrl"

    tar -xjf /tmp/zandronum.tar.bz2 -C $Env:SERVER_DIR
} else {
    Write-Log "Zandronum already installed in ${Env:SERVER_DIR}, skipping installation."
}

Write-Log -Message "Zandronum installation complete."

Invoke-Hook "PostInstallZandronum"

Invoke-Hook "PreDownloadWads"

if ($Env:EXTRA_WAD_URLS -and $Env:EXTRA_WAD_URLS.Trim().Length -gt 0) {
    Write-Log "Downloading extra WADs specified in EXTRA_WAD_URLS..."

    $wadUrls = $Env:EXTRA_WAD_URLS -split '[, \n\r]+' | Where-Object { $_.Trim().Length -gt 0 }

    foreach ($url in $wadUrls) {
        Write-Log -Message "Downloading WAD from URL: $url"
        $fileName = [System.IO.Path]::GetFileName($url)
        $destinationPath = Join-Path -Path $Env:OVERLAY_DIR -ChildPath $fileName

        curl --output $destinationPath $url

        Write-Log -Message "Downloaded WAD to: $destinationPath"
    }
} else {
    Write-Log -Message "No EXTRA_WAD_URLS specified, skipping WAD download."
}

Invoke-Hook "PostDownloadWads"

Set-Location $Env:SERVER_DIR