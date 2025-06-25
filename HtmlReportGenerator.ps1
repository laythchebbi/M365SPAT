# HtmlReportGenerator.ps1
# M365SPAT - Microsoft 365 Security Posture Assessment Tool
# HTML Dashboard Generator - PowerShell Functions Only
# Version: 6.0 - Updated with Font Awesome Icons

function New-HtmlReport {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Report
    )
    
    Write-Verbose "Starting M365SPAT dashboard generation..."
    
    # Calculate compliance score
    $complianceScore = if ($Report.TotalControls -gt 0) { 
        [math]::Round(($Report.PassedControls / $Report.TotalControls) * 100, 2) 
    } else { 0 }
    
    # Generate report ID
    $reportId = Get-Date -Format 'yyyyMMddHHmmss'
    
    # Get the script directory to find template files
    $ScriptDirectory = Split-Path -Parent $PSCommandPath
    
    # Load template files
    $htmlTemplatePath = Join-Path $ScriptDirectory "dashboard-template.html"
    $cssPath = Join-Path $ScriptDirectory "dashboard-styles.css"
    $jsPath = Join-Path $ScriptDirectory "dashboard-scripts.js"
    
    if (-not (Test-Path $htmlTemplatePath)) {
        throw "HTML template not found: $htmlTemplatePath"
    }
    if (-not (Test-Path $cssPath)) {
        throw "CSS file not found: $cssPath"
    }
    if (-not (Test-Path $jsPath)) {
        throw "JavaScript file not found: $jsPath"
    }
    
    $htmlTemplate = Get-Content $htmlTemplatePath -Raw
    $cssContent = Get-Content $cssPath -Raw
    $jsContent = Get-Content $jsPath -Raw
    
    # Generate controls content
    $controlsContent = New-ControlsDashboardContent -Results $Report.Results
    
    # Replace CSS and JS placeholders
    $htmlContent = $htmlTemplate -replace '\{\{CSS_CONTENT\}\}', $cssContent
    $htmlContent = $htmlContent -replace '\{\{JS_CONTENT\}\}', $jsContent
    
    # Replace data placeholders
    $htmlContent = $htmlContent -replace '\{\{TENANT_ID\}\}', $Report.TenantId
    $htmlContent = $htmlContent -replace '\{\{ASSESSMENT_DATE\}\}', $Report.AssessmentDate
    $htmlContent = $htmlContent -replace '\{\{TOTAL_CONTROLS\}\}', $Report.TotalControls
    $htmlContent = $htmlContent -replace '\{\{PASSED_CONTROLS\}\}', $Report.PassedControls
    $htmlContent = $htmlContent -replace '\{\{FAILED_CONTROLS\}\}', $Report.FailedControls
    $htmlContent = $htmlContent -replace '\{\{ERROR_CONTROLS\}\}', $Report.ErrorControls
    $htmlContent = $htmlContent -replace '\{\{COMPLIANCE_SCORE\}\}', $complianceScore
    $htmlContent = $htmlContent -replace '\{\{CONTROLS_CONTENT\}\}', $controlsContent
    $htmlContent = $htmlContent -replace '\{\{REPORT_ID\}\}', $reportId
    
    Write-Verbose "M365SPAT dashboard generation completed successfully"
    return $htmlContent
}

function New-ControlsDashboardContent {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )
    
    # Group results by category for M365SPAT dashboard
    $categoryResults = $Results | Group-Object Category
    $controlsHtml = ""
    
    foreach ($category in $categoryResults) {
        foreach ($control in $category.Group) {
            $statusClass = switch ($control.Status) {
                "PASS" { "status-pass" }
                "FAIL" { "status-fail" }
                "ERROR" { "status-error" }
                default { "status-error" }
            }
            
            $badgeClass = switch ($control.Status) {
                "PASS" { "badge-success" }
                "FAIL" { "badge-error" }
                "ERROR" { "badge-warning" }
                default { "badge-warning" }
            }
            
            $severityClass = switch ($control.Severity) {
                "Critical" { "badge-error" }
                "High" { "badge-warning" }
                "Medium" { "badge-secondary" }
                "Low" { "badge-success" }
                default { "badge-secondary" }
            }
            
            # Clean control ID for HTML IDs
            $cleanControlId = $control.ControlId -replace '[^a-zA-Z0-9]', '-'
            
            # Build simple explanation content for M365SPAT with Font Awesome icons
            $simpleExplanationHtml = ""
            if ($control.SimpleExplanation -and $control.SimpleExplanation.WhatWasChecked) {
                $riskClass = switch -Wildcard ($control.SimpleExplanation.RiskLevel) {
                    "*Very High*" { "risk-critical" }
                    "*High*" { "risk-high" }
                    "*Medium*" { "risk-medium" }
                    "*Low*" { "risk-low" }
                    "*Unknown*" { "risk-unknown" }
                    default { "risk-medium" }
                }
                
                $simpleExplanationHtml = @"
                <div class="tab-content active" data-tab="simple">
                    <div class="explanation-grid">
                        <div class="explanation-item">
                            <div class="explanation-label"><i class="fas fa-search"></i> What We Checked</div>
                            <div class="explanation-text">$(Get-SafeHtml $control.SimpleExplanation.WhatWasChecked)</div>
                        </div>
                        <div class="explanation-item">
                            <div class="explanation-label"><i class="fas fa-clipboard-list"></i> What We Found</div>
                            <div class="explanation-text">$(Get-SafeHtml $control.SimpleExplanation.WhatWasFound)</div>
                        </div>
                        <div class="explanation-item">
                            <div class="explanation-label"><i class="fas fa-shield-alt"></i> Why This Matters</div>
                            <div class="explanation-text">$(Get-SafeHtml $control.SimpleExplanation.WhyItMatters)</div>
                        </div>
                        <div class="explanation-item">
                            <div class="explanation-label"><i class="fas fa-users"></i> Impact on Users</div>
                            <div class="explanation-text">$(Get-SafeHtml $control.SimpleExplanation.UserImpact)</div>
                        </div>
                    </div>
                    <div class="result-box">
                        <div class="result-text">$(Get-SafeHtml $control.SimpleExplanation.PlainEnglishResult)</div>
                        <div class="risk-badge $riskClass">$(Get-SafeHtml $control.SimpleExplanation.RiskLevel)</div>
                    </div>
                </div>
"@
            }
            
            # Build technical explanation content for M365SPAT with Font Awesome icons
            $technicalExplanationHtml = Build-TechnicalExplanationHtml -Control $control -CleanControlId $cleanControlId
            
            # Build main explanation section with tabs for M365SPAT
            $explanationHtml = ""
            if ($simpleExplanationHtml -or $technicalExplanationHtml) {
                $explanationHtml = @"
                <div class="control-content">
                    <div class="content-tabs">
                        <button class="content-tab active" data-tab="simple">
                            <i class="fas fa-book-open"></i> Simple Explanation
                        </button>
                        <button class="content-tab" data-tab="technical">
                            <i class="fas fa-cogs"></i> Technical Details
                        </button>
                    </div>
                    $simpleExplanationHtml
                    $technicalExplanationHtml
                </div>
"@
            }
            
            # Add remediation if failed for M365SPAT with Font Awesome icons
            $remediationHtml = ""
            if ($control.Status -eq "FAIL" -and $control.Remediation) {
                $remediationHtml = @"
                <div style="background: hsl(var(--warning) / 0.1); border: 1px solid hsl(var(--warning) / 0.2); border-radius: calc(var(--radius) - 2px); padding: 1rem; margin: 1rem 2rem;">
                    <div style="font-weight: 600; color: hsl(var(--warning)); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.5rem;">
                        <i class="fas fa-tools"></i>
                        <span>Recommended Action</span>
                    </div>
                    <div style="color: hsl(var(--warning)); font-size: 0.875rem; line-height: 1.5;">$(Get-SafeHtml $control.Remediation)</div>
                </div>
"@
            }
            
            $controlsHtml += @"
            <div class="control-card $statusClass">
                <div class="control-header">
                    <div class="control-main">
                        <div class="control-info">
                            <h3 class="control-title">$(Get-SafeHtml $control.Name)</h3>
                            <div class="control-meta">
                                <span class="control-id">$(Get-SafeHtml $control.ControlId)</span>
                                <span class="control-category">$(Get-SafeHtml $control.Category)</span>
                            </div>
                            <p class="control-message">$(Get-SafeHtml $control.Message)</p>
                        </div>
                        <div class="control-badges">
                            <span class="badge $badgeClass">$($control.Status)</span>
                            <span class="badge $severityClass">$($control.Severity)</span>
                        </div>
                    </div>
                    <div class="expand-icon"><i class="fas fa-chevron-right"></i></div>
                </div>
                $explanationHtml
                $remediationHtml
            </div>
"@
        }
    }
    
    return $controlsHtml
}

function Build-TechnicalExplanationHtml {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Control,
        
        [Parameter(Mandatory=$true)]
        [string]$CleanControlId
    )
    
    $technicalExplanationHtml = ""
    
    if ($Control.technical_explanation) {
        # Build licenses list for M365SPAT
        $licensesHtml = ""
        if ($Control.technical_explanation.required_licenses -and $Control.technical_explanation.required_licenses.Count -gt 0) {
            $licensesItems = ($Control.technical_explanation.required_licenses | ForEach-Object { "• $(Get-SafeHtml $_)" }) -join "<br>"
            $licensesHtml = $licensesItems
        }
        
        # Build permissions list for M365SPAT
        $permissionsHtml = ""
        if ($Control.technical_explanation.required_permissions -and $Control.technical_explanation.required_permissions.Count -gt 0) {
            $permissionsItems = ($Control.technical_explanation.required_permissions | ForEach-Object { "• $(Get-SafeHtml $_)" }) -join "<br>"
            $permissionsHtml = $permissionsItems
        }
        
        # Build the complete technical explanation HTML for M365SPAT dashboard with Font Awesome icons
        $technicalExplanationHtml = @"
        <div class="tab-content" data-tab="technical">
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1rem;">
"@
        
        # Add sections conditionally for M365SPAT
        if ($licensesHtml) {
            $technicalExplanationHtml += @"
                <div style="background: hsl(var(--card)); border: 1px solid hsl(var(--border)); border-radius: 8px; padding: 1rem;">
                    <h4 style="color: hsl(var(--primary)); margin-bottom: 0.5rem; font-size: 0.875rem; display: flex; align-items: center; gap: 0.5rem;"><i class="fas fa-file-contract"></i> Required Licenses</h4>
                    <div style="font-size: 0.8rem; line-height: 1.4; color: hsl(var(--muted-foreground));">$licensesHtml</div>
                </div>
"@
        }
        
        if ($permissionsHtml) {
            $technicalExplanationHtml += @"
                <div style="background: hsl(var(--card)); border: 1px solid hsl(var(--border)); border-radius: 8px; padding: 1rem;">
                    <h4 style="color: hsl(var(--primary)); margin-bottom: 0.5rem; font-size: 0.875rem; display: flex; align-items: center; gap: 0.5rem;"><i class="fas fa-key"></i> Required Permissions</h4>
                    <div style="font-size: 0.8rem; line-height: 1.4; color: hsl(var(--muted-foreground));">$permissionsHtml</div>
                </div>
"@
        }
        
        # Add implementation details section for M365SPAT
        $technicalExplanationHtml += @"
                <div style="background: hsl(var(--card)); border: 1px solid hsl(var(--border)); border-radius: 8px; padding: 1rem;">
                    <h4 style="color: hsl(var(--primary)); margin-bottom: 0.5rem; font-size: 0.875rem; display: flex; align-items: center; gap: 0.5rem;"><i class="fas fa-chart-line"></i> Implementation Details</h4>
"@
        
        if ($Control.technical_explanation.implementation_complexity) {
            $technicalExplanationHtml += "<div style='margin-bottom: 0.5rem;'><strong>Complexity:</strong> <span style='background: hsl(var(--muted)); padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.75rem;'>$(Get-SafeHtml $Control.technical_explanation.implementation_complexity)</span></div>"
        }
        
        if ($Control.technical_explanation.estimated_time_to_remediate) {
            $technicalExplanationHtml += "<div style='font-size: 0.8rem; color: hsl(var(--muted-foreground));'><strong>Estimated Time:</strong> $(Get-SafeHtml $Control.technical_explanation.estimated_time_to_remediate)</div>"
        }
        
        $technicalExplanationHtml += @"
                </div>
            </div>
"@
        
        # Add technical remediation section for M365SPAT
        if ($Control.technical_explanation.technical_remediation) {
            $technicalExplanationHtml += @"
            <div style="margin-top: 1.5rem; background: hsl(var(--card)); border: 1px solid hsl(var(--border)); border-radius: 8px; padding: 1rem;">
                <h4 style="color: hsl(var(--primary)); margin-bottom: 0.75rem; font-size: 0.875rem; display: flex; align-items: center; gap: 0.5rem;"><i class="fas fa-tools"></i> Technical Remediation Steps</h4>
                <div style="background: hsl(var(--muted) / 0.3); padding: 1rem; border-radius: 6px; border-left: 4px solid hsl(var(--success));">
                    <pre style="white-space: pre-wrap; font-family: 'Geist Mono', monospace; margin: 0; font-size: 0.8rem; line-height: 1.4;">$(Get-SafeHtml $Control.technical_explanation.technical_remediation)</pre>
                </div>
            </div>
"@
        }
        
        # Add PowerShell commands section for M365SPAT
        if ($Control.technical_explanation.powershell_commands -and $Control.technical_explanation.powershell_commands.Count -gt 0) {
            $technicalExplanationHtml += @"
            <div style="margin-top: 1.5rem; background: hsl(var(--card)); border: 1px solid hsl(var(--border)); border-radius: 8px; padding: 1rem;">
                <h4 style="color: hsl(var(--primary)); margin-bottom: 0.75rem; font-size: 0.875rem; display: flex; align-items: center; gap: 0.5rem;"><i class="fas fa-terminal"></i> PowerShell Commands</h4>
"@
            foreach ($command in $Control.technical_explanation.powershell_commands) {
                $technicalExplanationHtml += @"
                <div style="background: hsl(var(--muted)); padding: 1rem; border-radius: 6px; margin-bottom: 0.75rem; border: 1px solid hsl(var(--border));">
                    <pre style="white-space: pre-wrap; font-family: 'Geist Mono', monospace; margin: 0; font-size: 0.8rem; line-height: 1.4; color: hsl(var(--foreground));">$(Get-SafeHtml $command)</pre>
                </div>
"@
            }
            $technicalExplanationHtml += "</div>"
        }
        
        $technicalExplanationHtml += "</div>"
    } else {
        # Fallback if no technical explanation is available for M365SPAT
        $technicalExplanationHtml = @"
        <div class="tab-content" data-tab="technical">
            <div style="background: hsl(var(--card)); border: 1px solid hsl(var(--border)); border-radius: 8px; padding: 1rem; text-align: center;">
                <h4 style="color: hsl(var(--muted-foreground)); margin-bottom: 0.5rem; display: flex; align-items: center; justify-content: center; gap: 0.5rem;"><i class="fas fa-info-circle"></i> Technical Information</h4>
                <p style="color: hsl(var(--muted-foreground)); font-style: italic; margin: 0;">Technical details are not available for this control in M365SPAT.</p>
            </div>
        </div>
"@
    }
    
    return $technicalExplanationHtml
}

function Get-SafeHtml {
    param([string]$Text)
    
    if (-not $Text) { return "" }
    
    # Basic HTML encoding to prevent XSS in M365SPAT
    $Text = $Text -replace '&', '&amp;'
    $Text = $Text -replace '<', '&lt;'
    $Text = $Text -replace '>', '&gt;'
    $Text = $Text -replace '"', '&quot;'
    $Text = $Text -replace "'", '&#x27;'
    
    return $Text
}

function Calculate-DomainScores {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )
    
    # Define M365SPAT domain mappings based on control categories and IDs
    $domainMapping = @{
        Identity = @('Authentication', 'Role Management', 'Identity Protection')
        AccessControl = @('Conditional Access', 'Privileged Access')
        Device = @('Device Management', 'Device Compliance')
        Data = @('Data Protection', 'External Sharing', 'Information Protection')
        Email = @('Email Security', 'Advanced Threat Protection', 'Anti-malware')
        Monitoring = @('Audit and Monitoring', 'Monitoring and Alerting', 'Security Operations')
        Network = @('Network Security', 'Firewall', 'Network Access')
        Compliance = @('Compliance and Governance', 'Data Loss Prevention', 'Records Management')
    }
    
    $domainScores = @{}
    
    foreach ($domain in $domainMapping.Keys) {
        $categories = $domainMapping[$domain]
        $domainControls = $Results | Where-Object { $_.Category -in $categories }
        
        if ($domainControls.Count -gt 0) {
            $passedControls = ($domainControls | Where-Object { $_.Status -eq "PASS" }).Count
            $score = [math]::Round(($passedControls / $domainControls.Count) * 100, 0)
            $domainScores[$domain] = $score
        } else {
            # Default scores for domains with no controls in M365SPAT
            $domainScores[$domain] = 75
        }
    }
    
    return $domainScores
}

function Copy-ReportAssets {
    param(
        [Parameter(Mandatory=$true)]
        [string]$OutputDirectory
    )
    
    # For the M365SPAT embedded version, we don't need separate CSS/JS files
    # Everything is embedded in the HTML template
    
    return @{
        CSSCopied = $true
        JSCopied = $true
        Message = "All M365SPAT assets embedded in HTML file"
    }
}