# AssessmentEngine.ps1
# Security assessment engine for Microsoft 365 with Simple Explanations
# Version: 2.0

function Start-SecurityAssessment {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AccessToken,
        
        [Parameter(Mandatory=$true)]
        [array]$Controls
    )
    
    $results = @()
    $controlCount = 0
    
    foreach ($control in $Controls) {
        $controlCount++
        Write-Host "  Checking control $controlCount/$($Controls.Count): $($control.name)" -ForegroundColor Gray
        
        $result = Test-SecurityControl -AccessToken $AccessToken -Control $control
        $results += $result
        
        # Show immediate result
        $statusColor = switch ($result.Status) {
            "PASS" { "Green" }
            "FAIL" { "Red" }
            "ERROR" { "Yellow" }
            default { "Gray" }
        }
        Write-Host "    [$($result.Status)]" -ForegroundColor $statusColor -NoNewline
        Write-Host " $($result.Message)" -ForegroundColor Gray
    }
    
    return $results
}

function Test-SecurityControl {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AccessToken,
        
        [Parameter(Mandatory=$true)]
        [object]$Control
    )
    
    $result = @{
        ControlId = $control.id
        Name = $control.name
        Category = $control.category
        Severity = $control.severity
        Status = "ERROR"
        Message = ""
        Remediation = $control.remediation
        AffectedResources = @()
        ResourceCount = 0
        Evidence = @{
            RawResponse = $null
            QueryUsed = ""
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
            ResponseCode = $null
            Headers = @{}
            ProcessedData = $null
        }
        SimpleExplanation = @{
            WhatWasChecked = ""
            WhatWasFound = ""
            WhyItMatters = ""
            PlainEnglishResult = ""
            RiskLevel = ""
            UserImpact = ""
        }
        Details = @{}
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    try {
        # Set the base explanation info from JSON
        if ($control.simple_explanation) {
            $result.SimpleExplanation.WhatWasChecked = $control.simple_explanation.what_was_checked
            $result.SimpleExplanation.WhyItMatters = $control.simple_explanation.why_it_matters
        }
        
        # Execute the control check
        switch ($control.type) {
            "graph_api" {
                $result = Test-GraphApiControl -AccessToken $AccessToken -Control $control -Result $result
            }
            "policy_check" {
                $result = Test-PolicyControl -AccessToken $AccessToken -Control $control -Result $result
            }
            "configuration" {
                $result = Test-ConfigurationControl -AccessToken $AccessToken -Control $control -Result $result
            }
            default {
                $result.Status = "ERROR"
                $result.Message = "Unknown control type: $($control.type)"
            }
        }
        
        # Set the status-specific explanation from JSON
        $result = Set-StatusSpecificExplanation -Control $control -Result $result
        
        # Get affected resources if endpoint is specified
        if ($control.resources_endpoint) {
            $result = Get-AffectedResources -AccessToken $AccessToken -Control $control -Result $result
        }
        
    } catch {
        $result.Status = "ERROR"
        $result.Message = "Control execution failed: $($_.Exception.Message)"
        $result.Evidence.RawResponse = $_.Exception.Message
        
        # Set error explanation
        $result = Set-StatusSpecificExplanation -Control $control -Result $result
    }
    
    return $result
}

function Set-StatusSpecificExplanation {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Control,
        
        [Parameter(Mandatory=$true)]
        [object]$Result
    )
    
    if (-not $Control.simple_explanation) {
        return $Result
    }
    
    $explanation = $null
    
    # Get the appropriate explanation based on status
    switch ($Result.Status) {
        "PASS" {
            $explanation = $Control.simple_explanation.pass_explanation
        }
        "FAIL" {
            $explanation = $Control.simple_explanation.fail_explanation
        }
        "ERROR" {
            $explanation = $Control.simple_explanation.error_explanation
        }
        default {
            # Fallback to fail explanation
            $explanation = $Control.simple_explanation.fail_explanation
        }
    }
    
    if ($explanation) {
        $Result.SimpleExplanation.WhatWasFound = $explanation.what_was_found
        $Result.SimpleExplanation.PlainEnglishResult = $explanation.plain_english_result
        $Result.SimpleExplanation.RiskLevel = $explanation.risk_level
        $Result.SimpleExplanation.UserImpact = $explanation.user_impact
    }
    
    return $Result
}

function Test-GraphApiControl {
    param(
        [string]$AccessToken,
        [object]$Control,
        [object]$Result
    )
    
    try {
        # Store evidence of the API call
        $Result.Evidence.QueryUsed = $Control.endpoint
        $Result.Evidence.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        
        $graphResponse = Invoke-GraphRequest -AccessToken $AccessToken -Uri $control.endpoint
        
        # Capture response details for evidence
        $Result.Evidence.ResponseCode = if ($graphResponse.Success) { 200 } else { $graphResponse.StatusCode }
        
        if (-not $graphResponse.Success) {
            $Result.Status = "ERROR"
            $Result.Message = "Graph API call failed: $($graphResponse.Error)"
            $Result.Evidence.RawResponse = @{
                Error = $graphResponse.Error
                StatusCode = $graphResponse.StatusCode
                Success = $false
            }
            return $Result
        }
        
        $data = $graphResponse.Data
        $Result.Details.RawData = $data
        
        # Store raw response as evidence (truncated for large responses)
        $Result.Evidence.RawResponse = if ($data -is [string] -and $data.Length -gt 5000) {
            $data.Substring(0, 5000) + "... [truncated]"
        } else {
            $data
        }
        
        # Execute the evaluation logic
        $evaluation = Invoke-Expression $control.evaluation
        
        # Store evaluation details as evidence
        $Result.Evidence.ProcessedData = @{
            EvaluationExpression = $control.evaluation
            EvaluationResult = $evaluation
            DataSample = if ($data.value -and $data.value.Count -gt 0) {
                # Show first few items as sample
                $sampleCount = [Math]::Min(3, $data.value.Count)
                $data.value[0..($sampleCount-1)]
            } else {
                $data
            }
        }
        
        # Add specific metrics for MFA registration
        if ($control.id -eq "IAM-AUTH-003" -and $data.value) {
            $mfaRegistered = $data.value | Where-Object { $_.isMfaRegistered -eq $true }
            $totalUsers = $data.value.Count
            if ($totalUsers -gt 0) {
                $Result.Evidence.ProcessedData.MfaRegistrationPercentage = [math]::Round(($mfaRegistered.Count / $totalUsers) * 100, 2)
                $Result.Evidence.ProcessedData.TotalUsers = $totalUsers
                $Result.Evidence.ProcessedData.MfaRegisteredUsers = $mfaRegistered.Count
                
                # Update the explanation with actual numbers
                $percentage = $Result.Evidence.ProcessedData.MfaRegistrationPercentage
                if ($Result.SimpleExplanation.WhatWasFound) {
                    $Result.SimpleExplanation.WhatWasFound = $Result.SimpleExplanation.WhatWasFound -replace "Currently.*authentication\.", "Currently $percentage% of users ($($mfaRegistered.Count) out of $totalUsers) have set up multi-factor authentication."
                }
            }
        }
        
        # Add specific metrics for role assignments
        if ($control.id -eq "IAM-ROL-001" -and $data.value) {
            $globalAdmins = $data.value | Where-Object { $_.displayName -eq 'Global Administrator' } | Select-Object -First 1
            if ($globalAdmins -and $globalAdmins.members) {
                $adminCount = $globalAdmins.members.Count
                $Result.Evidence.ProcessedData.GlobalAdminCount = $adminCount
                
                # Update the explanation with actual numbers
                if ($Result.SimpleExplanation.WhatWasFound) {
                    $Result.SimpleExplanation.WhatWasFound = $Result.SimpleExplanation.WhatWasFound -replace "Your organization has.*administrators\.", "Your organization has $adminCount global administrator$(if($adminCount -ne 1){'s'}). The recommended range is 2-5 administrators."
                }
            }
        }
        
        if ($evaluation) {
            $Result.Status = "PASS"
            $Result.Message = $control.pass_message
        } else {
            $Result.Status = "FAIL"  
            $Result.Message = $control.fail_message
        }
        
    } catch {
        $Result.Status = "ERROR"
        $Result.Message = "Control evaluation failed: $($_.Exception.Message)"
        $Result.Evidence.RawResponse = @{
            Error = $_.Exception.Message
            StackTrace = $_.ScriptStackTrace
            Success = $false
        }
    }
    
    return $Result
}

function Get-AffectedResources {
    param(
        [string]$AccessToken,
        [object]$Control,
        [object]$Result
    )
    
    try {
        $resourceResponse = Invoke-GraphRequest -AccessToken $AccessToken -Uri $Control.resources_endpoint
        
        if ($resourceResponse.Success) {
            $resources = @()
            
            if ($resourceResponse.Data.value) {
                # Handle paginated results
                foreach ($resource in $resourceResponse.Data.value) {
                    $resourceInfo = @{
                        Id = $resource.id
                        DisplayName = if ($resource.displayName) { $resource.displayName } elseif ($resource.userPrincipalName) { $resource.userPrincipalName } elseif ($resource.webUrl) { $resource.webUrl } else { "Unknown" }
                        Type = Get-ResourceType -Resource $resource -ControlId $Control.id
                        Details = @{}
                    }
                    
                    # Add relevant details based on resource type
                    if ($resource.userPrincipalName) { $resourceInfo.Details.UserPrincipalName = $resource.userPrincipalName }
                    if ($resource.mail) { $resourceInfo.Details.Email = $resource.mail }
                    if ($resource.webUrl) { $resourceInfo.Details.WebUrl = $resource.webUrl }
                    if ($resource.operatingSystem) { $resourceInfo.Details.OperatingSystem = $resource.operatingSystem }
                    if ($resource.state) { $resourceInfo.Details.State = $resource.state }
                    if ($resource.isVerified) { $resourceInfo.Details.IsVerified = $resource.isVerified }
                    if ($resource.createdDateTime) { $resourceInfo.Details.CreatedDateTime = $resource.createdDateTime }
                    
                    $resources += $resourceInfo
                }
            } elseif ($resourceResponse.Data.id) {
                # Handle single resource response
                $resource = $resourceResponse.Data
                $resourceInfo = @{
                    Id = $resource.id
                    DisplayName = if ($resource.displayName) { $resource.displayName } elseif ($resource.userPrincipalName) { $resource.userPrincipalName } else { "Unknown" }
                    Type = Get-ResourceType -Resource $resource -ControlId $Control.id
                    Details = @{}
                }
                $resources += $resourceInfo
            }
            
            $Result.AffectedResources = $resources
            $Result.ResourceCount = $resources.Count
            
        } else {
            Write-Verbose "Failed to retrieve affected resources: $($resourceResponse.Error)"
            $Result.AffectedResources = @()
            $Result.ResourceCount = 0
        }
        
    } catch {
        Write-Verbose "Error retrieving affected resources: $($_.Exception.Message)"
        $Result.AffectedResources = @()
        $Result.ResourceCount = 0
    }
    
    return $Result
}

function Get-ResourceType {
    param(
        [object]$Resource,
        [string]$ControlId
    )
    
    # Determine resource type based on properties and control context
    if ($Resource.userPrincipalName) { return "User" }
    if ($Resource.webUrl -and $Resource.webUrl -like "*sharepoint*") { return "SharePoint Site" }
    if ($Resource.displayName -and $ControlId -like "TEA-*") { return "Teams" }
    if ($Resource.displayName -and $ControlId -like "APP-*") { return "Application" }
    if ($Resource.operatingSystem) { return "Device" }
    if ($Resource.authenticationType) { return "Domain" }
    if ($Resource.state -and $ControlId -like "CAP-*") { return "Conditional Access Policy" }
    if ($Resource.activityDisplayName) { return "Audit Log" }
    if ($ControlId -like "GOV-*") { return "Compliance Object" }
    
    return "Resource"
}

function Test-PolicyControl {
    param(
        [string]$AccessToken,
        [object]$Control,
        [object]$Result
    )
    
    try {
        # Store evidence
        $Result.Evidence.QueryUsed = $Control.endpoint
        $Result.Evidence.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        
        $graphResponse = Invoke-GraphRequest -AccessToken $AccessToken -Uri $control.endpoint
        
        $Result.Evidence.ResponseCode = if ($graphResponse.Success) { 200 } else { $graphResponse.StatusCode }
        
        if (-not $graphResponse.Success) {
            $Result.Status = "ERROR"
            $Result.Message = "Graph API call failed: $($graphResponse.Error)"
            $Result.Evidence.RawResponse = @{
                Error = $graphResponse.Error
                Success = $false
            }
            return $Result
        }
        
        $policies = $graphResponse.Data.value
        $Result.Details.PoliciesFound = $policies.Count
        $Result.Details.Policies = $policies
        
        # Store policy evidence
        $Result.Evidence.RawResponse = $graphResponse.Data
        $Result.Evidence.ProcessedData = @{
            TotalPolicies = $policies.Count
            TargetPolicyName = $control.policy_name
            PolicyNames = $policies | ForEach-Object { $_.displayName }
        }
        
        # Check if required policy exists and is configured correctly
        $targetPolicy = $policies | Where-Object { $_.displayName -eq $control.policy_name }
        
        if ($targetPolicy) {
            # Store found policy as evidence
            $Result.Evidence.ProcessedData.FoundPolicy = $targetPolicy
            $Result.Evidence.ProcessedData.PolicyConfiguration = @{}
            
            # Evaluate policy configuration
            $evaluation = $true
            foreach ($requirement in $control.requirements) {
                $propertyValue = $targetPolicy.$($requirement.property)
                $Result.Evidence.ProcessedData.PolicyConfiguration[$requirement.property] = $propertyValue
                
                $requirementMet = switch ($requirement.operator) {
                    "equals" { $propertyValue -eq $requirement.value }
                    "contains" { $propertyValue -contains $requirement.value }
                    "greater_than" { $propertyValue -gt $requirement.value }
                    "less_than" { $propertyValue -lt $requirement.value }
                }
                
                $Result.Evidence.ProcessedData.PolicyConfiguration["$($requirement.property)_RequirementMet"] = $requirementMet
                $evaluation = $evaluation -and $requirementMet
            }
            
            $Result.Evidence.ProcessedData.OverallCompliance = $evaluation
            
            if ($evaluation) {
                $Result.Status = "PASS"
                $Result.Message = $control.pass_message
            } else {
                $Result.Status = "FAIL"
                $Result.Message = $control.fail_message
            }
        } else {
            $Result.Status = "FAIL"
            $Result.Message = "Required policy '$($control.policy_name)' not found"
            $Result.Evidence.ProcessedData.FoundPolicy = $null
            $Result.Evidence.ProcessedData.AvailablePolicies = $policies | Select-Object displayName, state, id
        }
        
    } catch {
        $Result.Status = "ERROR"
        $Result.Message = "Policy evaluation failed: $($_.Exception.Message)"
        $Result.Evidence.RawResponse = @{
            Error = $_.Exception.Message
            Success = $false
        }
    }
    
    return $Result
}

function Test-ConfigurationControl {
    param(
        [string]$AccessToken,
        [object]$Control,
        [object]$Result
    )
    
    try {
        # Store evidence
        $Result.Evidence.QueryUsed = $Control.endpoint
        $Result.Evidence.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        
        $graphResponse = Invoke-GraphRequest -AccessToken $AccessToken -Uri $control.endpoint
        
        $Result.Evidence.ResponseCode = if ($graphResponse.Success) { 200 } else { $graphResponse.StatusCode }
        
        if (-not $graphResponse.Success) {
            $Result.Status = "ERROR"
            $Result.Message = "Graph API call failed: $($graphResponse.Error)"
            $Result.Evidence.RawResponse = @{
                Error = $graphResponse.Error
                Success = $false
            }
            return $Result
        }
        
        $config = $graphResponse.Data
        $Result.Details.Configuration = $config
        
        # Store configuration evidence
        $Result.Evidence.RawResponse = $config
        $Result.Evidence.ProcessedData = @{
            ConfigurationFound = $true
            Requirements = @{}
        }
        
        # Evaluate configuration against requirements
        $evaluation = $true
        foreach ($requirement in $control.requirements) {
            $configValue = $config.$($requirement.property)
            $Result.Evidence.ProcessedData.Requirements[$requirement.property] = @{
                CurrentValue = $configValue
                RequiredValue = $requirement.value
                Operator = $requirement.operator
                Met = $false
            }
            
            $requirementMet = switch ($requirement.operator) {
                "equals" { $configValue -eq $requirement.value }
                "not_equals" { $configValue -ne $requirement.value }
                "contains" { $configValue -contains $requirement.value }
                "enabled" { $configValue -eq $true }
                "disabled" { $configValue -eq $false }
            }
            
            $Result.Evidence.ProcessedData.Requirements[$requirement.property].Met = $requirementMet
            $evaluation = $evaluation -and $requirementMet
        }
        
        $Result.Evidence.ProcessedData.OverallCompliance = $evaluation
        
        if ($evaluation) {
            $Result.Status = "PASS"
            $Result.Message = $control.pass_message
        } else {
            $Result.Status = "FAIL"
            $Result.Message = $control.fail_message
        }
        
    } catch {
        $Result.Status = "ERROR"
        $Result.Message = "Configuration evaluation failed: $($_.Exception.Message)"
        $Result.Evidence.RawResponse = @{
            Error = $_.Exception.Message
            Success = $false
        }
    }
    
    return $Result
}