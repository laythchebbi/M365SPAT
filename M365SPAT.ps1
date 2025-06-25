# M365SPAT.ps1
# Microsoft 365 Security Posture Assessment Tool
# Main script for comprehensive Microsoft 365 security assessment with beautiful dashboard
# Author: M365SPAT Development Team
# Version: 6.0

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
    [string]$OutputFile = ".\reports\M365SPAT_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').json",
    
    [Parameter(Mandatory=$false)]
    [string]$HtmlReport = ".\reports\M365SPAT_Dashboard_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
)

# Get the script directory to ensure we can find the module files
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Import required modules with proper error handling for M365SPAT
try {
    $AuthModulePath = Join-Path $ScriptDirectory "AuthenticationModule.ps1"
    $AssessmentModulePath = Join-Path $ScriptDirectory "AssessmentEngine.ps1"
    $HtmlModulePath = Join-Path $ScriptDirectory "HtmlReportGenerator.ps1"
    
    Write-Verbose "Loading M365SPAT modules from script directory: $ScriptDirectory"
    
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
    
    # Verify template files exist
    $templateFiles = @(
        "dashboard-template.html",
        "dashboard-styles.css", 
        "dashboard-scripts.js"
    )
    
    foreach ($templateFile in $templateFiles) {
        $templatePath = Join-Path $ScriptDirectory $templateFile
        if (-not (Test-Path $templatePath)) {
            throw "Template file not found: $templatePath"
        }
        Write-Verbose "✓ Found template file: $templateFile"
    }
    
} catch {
    Write-Host "❌ Failed to load required M365SPAT modules: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure the following files are in the same directory as this script:" -ForegroundColor Yellow
    Write-Host "  - AuthenticationModule.ps1" -ForegroundColor Yellow
    Write-Host "  - AssessmentEngine.ps1" -ForegroundColor Yellow
    Write-Host "  - HtmlReportGenerator.ps1" -ForegroundColor Yellow
    Write-Host "  - dashboard-template.html" -ForegroundColor Yellow
    Write-Host "  - dashboard-styles.css" -ForegroundColor Yellow
    Write-Host "  - dashboard-scripts.js" -ForegroundColor Yellow
    exit 1
}

# Verify that required functions are loaded for M365SPAT
$requiredFunctions = @('Get-GraphAccessToken', 'Start-SecurityAssessment', 'New-HtmlReport')
foreach ($function in $requiredFunctions) {
    if (-not (Get-Command $function -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Required M365SPAT function '$function' not found. Module loading failed." -ForegroundColor Red
        exit 1
    }
}

# Main execution for M365SPAT
try {
    Write-Host "=== Microsoft 365 Security Posture Assessment Tool (M365SPAT) ===" -ForegroundColor Cyan
    Write-Host "🛡️  Comprehensive Security Analysis Dashboard" -ForegroundColor Cyan
    Write-Host ""
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

    # Step 1: Authenticate to Microsoft Graph
    Write-Host "[1/4] 🔐 Authenticating to Microsoft Graph..." -ForegroundColor Yellow
    if ($CertificateThumbprint) {
        $authResult = Get-GraphAccessToken -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint
    } else {
        $authResult = Get-GraphAccessToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
    }
    
    if ($authResult.Success) {
        Write-Host "✅ Authentication successful using $($authResult.AuthMethod)" -ForegroundColor Green
    } else {
        throw "Authentication failed: $($authResult.Error)"
    }

    # Step 2: Load security controls
    Write-Host "[2/4] 📋 Loading M365SPAT security controls..." -ForegroundColor Yellow
    if (-not (Test-Path $ControlsFile)) {
        throw "Controls file not found: $ControlsFile"
    }
    
    $controls = Get-Content $ControlsFile | ConvertFrom-Json
    Write-Host "✅ Loaded $($controls.controls.Count) security controls for M365SPAT assessment" -ForegroundColor Green

    # Step 3: Run security assessment
    Write-Host "[3/4] 🔍 Running M365SPAT security assessment..." -ForegroundColor Yellow
    $assessmentResults = Start-SecurityAssessment -AccessToken $authResult.AccessToken -Controls $controls.controls
    Write-Host "✅ M365SPAT assessment completed successfully" -ForegroundColor Green

    # Step 4: Generate beautiful dashboard reports
    Write-Host "[4/4] 📊 Generating M365SPAT dashboard reports..." -ForegroundColor Yellow
    
    # Ensure reports directory exists
    $reportsDir = ".\reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
        Write-Host "✅ Created reports directory" -ForegroundColor Green
    }
    
    $report = @{
        AssessmentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TenantId = $TenantId
        TotalControls = $assessmentResults.Count
        PassedControls = ($assessmentResults | Where-Object { $_.Status -eq "PASS" }).Count
        FailedControls = ($assessmentResults | Where-Object { $_.Status -eq "FAIL" }).Count
        ErrorControls = ($assessmentResults | Where-Object { $_.Status -eq "ERROR" }).Count
        Results = $assessmentResults
        Tool = "M365SPAT"
        Version = "6.0"
    }

    # Generate JSON report
    $report | ConvertTo-Json -Depth 10 | Out-File $OutputFile -Encoding UTF8
    Write-Host "✅ M365SPAT JSON report saved to: $OutputFile" -ForegroundColor Green
    
    # Generate beautiful HTML dashboard
    try {
        # Use the reports directory for copying assets
        $assetsCopied = Copy-ReportAssets -OutputDirectory $reportsDir
        
        # Generate M365SPAT HTML dashboard content
        $htmlContent = New-HtmlReport -Report $report
        $htmlContent | Out-File $HtmlReport -Encoding UTF8
        
        Write-Host "✅ M365SPAT Dashboard saved to: $HtmlReport" -ForegroundColor Green
        
        if ($assetsCopied.CSSCopied -and $assetsCopied.JSCopied) {
            Write-Host "✅ M365SPAT dashboard assets ready" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "⚠️  M365SPAT dashboard generation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "JSON report is still available at: $OutputFile" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "=== M365SPAT Assessment Summary ===" -ForegroundColor Cyan
    Write-Host "🛡️  Microsoft 365 Security Posture Assessment Tool Results" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Controls: $($report.TotalControls)" -ForegroundColor White
    Write-Host "✅ Passed: $($report.PassedControls)" -ForegroundColor Green
    Write-Host "❌ Failed: $($report.FailedControls)" -ForegroundColor Red
    Write-Host "⚠️  Errors: $($report.ErrorControls)" -ForegroundColor Yellow
    
    $complianceScore = [math]::Round(($report.PassedControls / $report.TotalControls) * 100, 2)
    $scoreColor = if ($complianceScore -ge 80) { "Green" } elseif ($complianceScore -ge 60) { "Yellow" } else { "Red" }
    Write-Host "📊 Compliance Score: $complianceScore%" -ForegroundColor $scoreColor
    
    # Show M365SPAT simple explanations summary
    $controlsWithExplanations = $assessmentResults | Where-Object { $_.SimpleExplanation -and $_.SimpleExplanation.WhatWasChecked }
    Write-Host ""
    Write-Host "💡 M365SPAT Enhanced Features:" -ForegroundColor Cyan
    Write-Host "   📖 $($controlsWithExplanations.Count) controls include user-friendly explanations" -ForegroundColor Gray
    Write-Host "   🎨 Beautiful interactive dashboard with modern UI" -ForegroundColor Gray
    Write-Host "   📱 Responsive design for all devices" -ForegroundColor Gray
    Write-Host "   🌙 Dark/Light theme support" -ForegroundColor Gray
    Write-Host "   📊 Interactive security domains chart" -ForegroundColor Gray
    Write-Host "   ⌨️  Keyboard shortcuts (Ctrl+E, Ctrl+H, Ctrl+T)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "📁 M365SPAT Reports saved to:" -ForegroundColor Cyan
    Write-Host "   📄 JSON Data: $OutputFile" -ForegroundColor Gray
    Write-Host "   🎨 Dashboard: $HtmlReport" -ForegroundColor Gray

} catch {
    Write-Host "❌ M365SPAT assessment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 M365SPAT assessment completed successfully!" -ForegroundColor Green
Write-Host "🌐 Open the HTML dashboard to view your beautiful M365SPAT security assessment results." -ForegroundColor Green
Write-Host "💡 Click on any control card to view detailed explanations and technical guidance." -ForegroundColor Green
Write-Host ""
Write-Host "🔗 For support and updates, visit: https://github.com/your-org/M365SPAT" -ForegroundColor Blue