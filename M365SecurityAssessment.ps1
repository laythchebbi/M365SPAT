# M365SecurityAssessment.ps1
# Main script for Microsoft 365 Security Assessment Tool with Simple Explanations
# Author: Security Assessment Team
# Version: 2.0

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$false)]
    [string]$CertificateThumbprint,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientSecret,
    
    [Parameter(Mandatory=$false)]
    [string]$ControlsFile = ".\SecurityControls.json",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = ".\reports\AssessmentResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').json",
    
    [Parameter(Mandatory=$false)]
    [string]$HtmlReport = ".\reports\AssessmentReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
)

# Get the script directory to ensure we can find the module files
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Import required modules with proper error handling
try {
    $AuthModulePath = Join-Path $ScriptDirectory "AuthenticationModule.ps1"
    $AssessmentModulePath = Join-Path $ScriptDirectory "AssessmentEngine.ps1"
    $HtmlModulePath = Join-Path $ScriptDirectory "HtmlReportGenerator.ps1"
    
    Write-Verbose "Loading modules from script directory: $ScriptDirectory"
    
    if (Test-Path $AuthModulePath) {
        . $AuthModulePath
        Write-Verbose "✓ Loaded AuthenticationModule.ps1"
    } else {
        throw "AuthenticationModule.ps1 not found at: $AuthModulePath"
    }
    
    if (Test-Path $AssessmentModulePath) {
        . $AssessmentModulePath
        Write-Verbose "✓ Loaded AssessmentEngine.ps1"
    } else {
        throw "AssessmentEngine.ps1 not found at: $AssessmentModulePath"
    }
    
    if (Test-Path $HtmlModulePath) {
        . $HtmlModulePath
        Write-Verbose "✓ Loaded HtmlReportGenerator.ps1"
    } else {
        throw "HtmlReportGenerator.ps1 not found at: $HtmlModulePath"
    }
    
} catch {
    Write-Host "❌ Failed to load required modules: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure the following files are in the same directory as this script:" -ForegroundColor Yellow
    Write-Host "  - AuthenticationModule.ps1" -ForegroundColor Yellow
    Write-Host "  - AssessmentEngine.ps1" -ForegroundColor Yellow
    Write-Host "  - HtmlReportGenerator.ps1" -ForegroundColor Yellow
    exit 1
}

# Verify that required functions are loaded
$requiredFunctions = @('Get-GraphAccessToken', 'Start-SecurityAssessment', 'New-HtmlReport')
foreach ($function in $requiredFunctions) {
    if (-not (Get-Command $function -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Required function '$function' not found. Module loading failed." -ForegroundColor Red
        exit 1
    }
}

# Main execution
try {
    Write-Host "=== Microsoft 365 Security Assessment Tool ===" -ForegroundColor Cyan
    Write-Host "Tenant ID: $TenantId" -ForegroundColor Gray
    Write-Host "Client ID: $ClientId" -ForegroundColor Gray
    
    # Validate authentication method
    if (-not $CertificateThumbprint -and -not $ClientSecret) {
        throw "Either CertificateThumbprint or ClientSecret must be provided"
    }
    
    if ($CertificateThumbprint -and $ClientSecret) {
        throw "Please provide either CertificateThumbprint OR ClientSecret, not both"
    }
    
    $authMethod = if ($CertificateThumbprint) { "Certificate" } else { "Client Secret" }
    Write-Host "Authentication Method: $authMethod" -ForegroundColor Gray
    if ($CertificateThumbprint) { Write-Host "Certificate Thumbprint: $CertificateThumbprint" -ForegroundColor Gray }
    Write-Host ""

    # Step 1: Authenticate
    Write-Host "[1/4] Authenticating to Microsoft Graph..." -ForegroundColor Yellow
    if ($CertificateThumbprint) {
        $authResult = Get-GraphAccessToken -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint
    } else {
        $authResult = Get-GraphAccessToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
    }
    
    if ($authResult.Success) {
        Write-Host "✓ Authentication successful" -ForegroundColor Green
    } else {
        throw "Authentication failed: $($authResult.Error)"
    }

    # Step 2: Load controls
    Write-Host "[2/4] Loading security controls..." -ForegroundColor Yellow
    if (-not (Test-Path $ControlsFile)) {
        throw "Controls file not found: $ControlsFile"
    }
    
    $controls = Get-Content $ControlsFile | ConvertFrom-Json
    Write-Host "✓ Loaded $($controls.controls.Count) security controls" -ForegroundColor Green

    # Step 3: Run assessment
    Write-Host "[3/4] Running security assessment..." -ForegroundColor Yellow
    $assessmentResults = Start-SecurityAssessment -AccessToken $authResult.AccessToken -Controls $controls.controls
    Write-Host "✓ Assessment completed" -ForegroundColor Green

    # Step 4: Generate reports
    Write-Host "[4/4] Generating assessment reports..." -ForegroundColor Yellow
    
    # Ensure reports directory exists
    $reportsDir = ".\reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
        Write-Host "✓ Created reports directory" -ForegroundColor Green
    }
    
    $report = @{
        AssessmentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TenantId = $TenantId
        TotalControls = $assessmentResults.Count
        PassedControls = ($assessmentResults | Where-Object { $_.Status -eq "PASS" }).Count
        FailedControls = ($assessmentResults | Where-Object { $_.Status -eq "FAIL" }).Count
        ErrorControls = ($assessmentResults | Where-Object { $_.Status -eq "ERROR" }).Count
        Results = $assessmentResults
    }

    # Generate JSON report
    $report | ConvertTo-Json -Depth 10 | Out-File $OutputFile -Encoding UTF8
    Write-Host "✓ JSON report saved to: $OutputFile" -ForegroundColor Green
    
    # Generate HTML report
    try {
        # Use the reports directory for copying assets
        $assetsCopied = Copy-ReportAssets -OutputDirectory $reportsDir
        
        # Generate HTML content
        $htmlContent = New-HtmlReport -Report $report
        $htmlContent | Out-File $HtmlReport -Encoding UTF8
        
        Write-Host "✓ HTML report saved to: $HtmlReport" -ForegroundColor Green
        
        if ($assetsCopied.CSSCopied -and $assetsCopied.JSCopied) {
            Write-Host "✓ Report assets ready" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "⚠ HTML report generation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "JSON report is still available at: $OutputFile" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "=== Assessment Summary ===" -ForegroundColor Cyan
    Write-Host "Total Controls: $($report.TotalControls)" -ForegroundColor White
    Write-Host "Passed: $($report.PassedControls)" -ForegroundColor Green
    Write-Host "Failed: $($report.FailedControls)" -ForegroundColor Red
    Write-Host "Errors: $($report.ErrorControls)" -ForegroundColor Yellow
    
    $complianceScore = [math]::Round(($report.PassedControls / $report.TotalControls) * 100, 2)
    Write-Host "Compliance Score: $complianceScore%" -ForegroundColor $(if ($complianceScore -ge 80) { "Green" } elseif ($complianceScore -ge 60) { "Yellow" } else { "Red" })
    
    # Show simple explanations summary
    $controlsWithExplanations = $assessmentResults | Where-Object { $_.SimpleExplanation -and $_.SimpleExplanation.WhatWasChecked }
    Write-Host ""
    Write-Host "💡 Simple Explanations Available:" -ForegroundColor Cyan
    Write-Host "   $($controlsWithExplanations.Count) controls include user-friendly explanations" -ForegroundColor Gray
    Write-Host "   Click on any control in the HTML report to view detailed explanations" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "📁 Reports saved to:" -ForegroundColor Cyan
    Write-Host "   JSON: $OutputFile" -ForegroundColor Gray
    Write-Host "   HTML: $HtmlReport" -ForegroundColor Gray

} catch {
    Write-Host "❌ Assessment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Assessment completed successfully!" -ForegroundColor Green
Write-Host "Open the HTML report to view the results with simple explanations for each control." -ForegroundColor Green