# PowerShell script to extract Zscaler certificates from Windows certificate store
# Run this script as Administrator

Write-Host "Searching for Zscaler certificates in Windows certificate store..."

# Function to export certificate
function Export-Certificate {
    param(
        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    $certBytes = $Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    $certPem = [System.Convert]::ToBase64String($certBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
    
    $pemContent = "-----BEGIN CERTIFICATE-----`n" + $certPem + "`n-----END CERTIFICATE-----"
    
    Set-Content -Path $FilePath -Value $pemContent -Encoding ASCII
    Write-Host "Exported: $FilePath"
}

# Search for Zscaler certificates
$zscalerCerts = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { 
    $_.Subject -like "*Zscaler*" -or 
    $_.Issuer -like "*Zscaler*" -or
    $_.FriendlyName -like "*Zscaler*"
}

$zscalerCerts += Get-ChildItem -Path Cert:\LocalMachine\CA | Where-Object { 
    $_.Subject -like "*Zscaler*" -or 
    $_.Issuer -like "*Zscaler*" -or
    $_.FriendlyName -like "*Zscaler*"
}

if ($zscalerCerts.Count -eq 0) {
    Write-Host "No Zscaler certificates found in Windows certificate store."
    Write-Host "Please contact your IT department for the Zscaler root and intermediate certificates."
} else {
    Write-Host "Found $($zscalerCerts.Count) Zscaler certificate(s):"
    
    $certIndex = 0
    foreach ($cert in $zscalerCerts) {
        $certIndex++
        Write-Host "`n$certIndex. Subject: $($cert.Subject)"
        Write-Host "   Issuer: $($cert.Issuer)"
        Write-Host "   Thumbprint: $($cert.Thumbprint)"
        Write-Host "   FriendlyName: $($cert.FriendlyName)"
        
        # Determine certificate type and filename
        $fileName = ""
        if ($cert.Subject -like "*Root*" -or $cert.FriendlyName -like "*Root*") {
            $fileName = "zscaler-root-ca.crt"
        } elseif ($cert.Subject -like "*Intermediate*" -or $cert.FriendlyName -like "*Intermediate*") {
            $fileName = "zscaler-intermediate-ca.crt"
        } else {
            $fileName = "zscaler-cert-$certIndex.crt"
        }
        
        $filePath = Join-Path -Path (Get-Location) -ChildPath $fileName
        Export-Certificate -Certificate $cert -FilePath $filePath
    }
    
    Write-Host "`nCertificates exported to current directory."
    Write-Host "Copy the .crt files to your certificates/ directory and rebuild your containers."
}

Write-Host "`nAlternatively, you can:"
Write-Host "1. Get certificates from your Zscaler admin portal"
Write-Host "2. Contact your IT department"
Write-Host "3. Export from browser (visit HTTPS site, click lock icon, view certificates)"