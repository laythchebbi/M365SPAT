# AuthenticationModule.ps1
# Authentication module for Microsoft Graph API using certificate-based authentication
# Version: 1.0

function Get-GraphAccessToken {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TenantId,
        
        [Parameter(Mandatory=$true)]
        [string]$ClientId,
        
        [Parameter(Mandatory=$false)]
        [string]$CertificateThumbprint,
        
        [Parameter(Mandatory=$false)]
        [string]$ClientSecret
    )
    
    try {
        # Validate authentication method
        if (-not $CertificateThumbprint -and -not $ClientSecret) {
            throw "Either CertificateThumbprint or ClientSecret must be provided"
        }
        
        if ($CertificateThumbprint -and $ClientSecret) {
            throw "Please provide either CertificateThumbprint OR ClientSecret, not both"
        }
        
        # Microsoft Graph endpoint
        $resource = "https://graph.microsoft.com"
        $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        
        if ($CertificateThumbprint) {
            # Certificate-based authentication
            return Get-GraphAccessTokenWithCertificate -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -TokenEndpoint $tokenEndpoint
        } else {
            # Client Secret authentication
            return Get-GraphAccessTokenWithSecret -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret -TokenEndpoint $tokenEndpoint
        }
        
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-GraphAccessTokenWithCertificate {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$CertificateThumbprint,
        [string]$TokenEndpoint
    )
        
    try {
        # Get certificate from local store
        $certificate = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
        if (-not $certificate) {
            $certificate = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
        }
        
        if (-not $certificate) {
            throw "Certificate with thumbprint '$CertificateThumbprint' not found in certificate store"
        }
        
        Write-Verbose "Certificate found: $($certificate.Subject)"
        
        # Create JWT assertion
        $jwt = New-JWTAssertion -Certificate $certificate -ClientId $ClientId -TokenEndpoint $TokenEndpoint
        
        # Prepare token request
        $body = @{
            client_id = $ClientId
            client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
            client_assertion = $jwt
            scope = "https://graph.microsoft.com/.default"
            grant_type = "client_credentials"
        }
        
        # Request access token
        $response = Invoke-RestMethod -Uri $TokenEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        
        return @{
            Success = $true
            AccessToken = $response.access_token
            ExpiresIn = $response.expires_in
            TokenType = $response.token_type
            AuthMethod = "Certificate"
        }
        
    } catch {
        throw $_.Exception.Message
    }
}

function Get-GraphAccessTokenWithSecret {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$TokenEndpoint
    )
    
    try {
        # Prepare token request for client secret
        $body = @{
            client_id = $ClientId
            client_secret = $ClientSecret
            scope = "https://graph.microsoft.com/.default"
            grant_type = "client_credentials"
        }
        
        # Request access token
        $response = Invoke-RestMethod -Uri $TokenEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        
        return @{
            Success = $true
            AccessToken = $response.access_token
            ExpiresIn = $response.expires_in
            TokenType = $response.token_type
            AuthMethod = "Client Secret"
        }
        
    } catch {
        throw $_.Exception.Message
    }
}

function New-JWTAssertion {
    param(
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [string]$ClientId,
        [string]$TokenEndpoint
    )
    
    # JWT Header
    $header = @{
        alg = "RS256"
        typ = "JWT"
        x5t = [Convert]::ToBase64String($Certificate.GetCertHash()) -replace '\+', '-' -replace '/', '_' -replace '='
    } | ConvertTo-Json -Compress
    
    # JWT Payload
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $payload = @{
        aud = $TokenEndpoint
        exp = $now + 300  # 5 minutes expiration
        iss = $ClientId
        jti = [Guid]::NewGuid().ToString()
        nbf = $now
        sub = $ClientId
    } | ConvertTo-Json -Compress
    
    # Base64Url encode header and payload
    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
    $payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    
    $headerEncoded = [Convert]::ToBase64String($headerBytes) -replace '\+', '-' -replace '/', '_' -replace '='
    $payloadEncoded = [Convert]::ToBase64String($payloadBytes) -replace '\+', '-' -replace '/', '_' -replace '='
    
    # Create signature
    $stringToSign = "$headerEncoded.$payloadEncoded"
    $bytesToSign = [System.Text.Encoding]::UTF8.GetBytes($stringToSign)
    
    $rsa = $Certificate.PrivateKey
    $signature = $rsa.SignData($bytesToSign, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $signatureEncoded = [Convert]::ToBase64String($signature) -replace '\+', '-' -replace '/', '_' -replace '='
    
    return "$headerEncoded.$payloadEncoded.$signatureEncoded"
}

function Invoke-GraphRequest {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AccessToken,
        
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        
        [Parameter(Mandatory=$false)]
        [string]$Method = "GET",
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Body = $null
    )
    
    try {
        $headers = @{
            "Authorization" = "Bearer $AccessToken"
            "Content-Type" = "application/json"
        }
        
        $params = @{
            Uri = $Uri
            Method = $Method
            Headers = $headers
        }
        
        if ($Body) {
            $params.Body = $Body | ConvertTo-Json -Depth 10
        }
        
        $response = Invoke-RestMethod @params
        return @{
            Success = $true
            Data = $response
            StatusCode = 200
        }
        
    } catch {
        $statusCode = if ($_.Exception.Response) { 
            [int]$_.Exception.Response.StatusCode 
        } else { 
            500 
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            StatusCode = $statusCode
            Data = $null
        }
    }
}