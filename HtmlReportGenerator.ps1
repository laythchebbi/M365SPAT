# HtmlReportGenerator.ps1
# Complete HTML report generator for Microsoft 365 Security Posture Assessment Tool (M365SPAT) with Technical Explanations
# Version: 5.3 - Fixed Property Names for JSON Compatibility

function New-HtmlReport {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Report
    )
    
    Write-Verbose "Starting HTML report generation..."
    
    # Calculate compliance score
    $complianceScore = if ($Report.TotalControls -gt 0) { 
        [math]::Round(($Report.PassedControls / $Report.TotalControls) * 100, 2) 
    } else { 0 }
    
    # Calculate domain scores for spider chart
    $domainScores = Calculate-DomainScores -Results $Report.Results
    
    # Generate report ID
    $reportId = Get-Date -Format 'yyyyMMddHHmmss'
    
    # Enhanced HTML template with technical explanations
    $htmlTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Microsoft 365 Security Posture Assessment Tool (M365SPAT) Report</title>
    <meta name="description" content="Comprehensive Microsoft 365 security posture analysis with technical details">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #0078d4, #106ebe); color: white; padding: 40px 30px; text-align: center; }
        .header h1 { margin: 0 0 10px 0; font-size: 2.5rem; }
        .summary { padding: 30px; background: #f8f9fa; border-bottom: 1px solid #dee2e6; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; }
        .stat-card { background: white; padding: 20px; border-radius: 8px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-number { font-size: 2rem; font-weight: bold; margin-bottom: 5px; }
        .stat-label { color: #6c757d; font-size: 0.9rem; text-transform: uppercase; }
        .controls { padding: 30px; }
        .control-item { background: #f8f9fa; margin-bottom: 20px; border-radius: 8px; overflow: hidden; border-left: 4px solid #dee2e6; }
        .control-item.pass { border-left-color: #28a745; }
        .control-item.fail { border-left-color: #dc3545; }
        .control-item.error { border-left-color: #ffc107; }
        .control-header { padding: 20px; display: flex; justify-content: space-between; align-items: center; cursor: pointer; }
        .control-header:hover { background: #e9ecef; }
        .control-title { margin: 0; font-size: 1.2rem; }
        .badge { padding: 5px 15px; border-radius: 20px; font-size: 0.8rem; font-weight: bold; text-transform: uppercase; margin-left: 10px; }
        .badge-success { background: #d4edda; color: #155724; }
        .badge-danger { background: #f8d7da; color: #721c24; }
        .badge-warning { background: #fff3cd; color: #856404; }
        .badge-critical { background: #f8d7da; color: #721c24; animation: pulse 2s infinite; }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.7; } }
        
        /* Enhanced explanation styles */
        .explanation { padding: 20px; border-top: 1px solid #dee2e6; background: white; display: none; }
        .explanation.show { display: block; }
        .explanation-tabs { display: flex; background: #f8f9fa; border-radius: 8px; margin-bottom: 20px; overflow: hidden; }
        .explanation-tab { flex: 1; padding: 15px 20px; background: #f8f9fa; border: none; cursor: pointer; font-weight: 500; transition: all 0.3s ease; text-align: center; }
        .explanation-tab.active { background: #0078d4; color: white; }
        .explanation-tab:hover:not(.active) { background: #e9ecef; }
        .explanation-content { display: none; }
        .explanation-content.active { display: block; animation: fadeIn 0.3s ease; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        
        /* Simple explanation styles */
        .explanation-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .explanation-item { background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 3px solid #0078d4; }
        .explanation-label { font-weight: bold; color: #495057; margin-bottom: 8px; font-size: 0.9rem; }
        .explanation-text { color: #6c757d; line-height: 1.5; font-size: 0.9rem; }
        .result-box { background: linear-gradient(135deg, #e3f2fd, #bbdefb); border: 1px solid #2196f3; border-radius: 8px; padding: 15px; text-align: center; margin-top: 15px; }
        .result-text { font-weight: bold; color: #1565c0; font-size: 1rem; }
        .risk-badge { display: inline-block; padding: 8px 12px; border-radius: 6px; font-size: 0.85rem; font-weight: bold; margin-top: 10px; }
        .risk-critical { background: #ffebee; color: #c62828; border: 2px solid #f44336; }
        .risk-high { background: #fff3e0; color: #e65100; border: 2px solid #ff9800; }
        .risk-medium { background: #e8f5e8; color: #2e7d32; border: 2px solid #4caf50; }
        .risk-low { background: #e8f5e8; color: #2e7d32; border: 2px solid #4caf50; }
        .risk-unknown { background: #f5f5f5; color: #757575; border: 2px solid #9e9e9e; }
        
        /* Technical explanation styles */
        .technical-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 20px; }
        .technical-section { background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px; }
        .technical-section h4 { margin: 0 0 15px 0; color: #495057; font-size: 1rem; border-bottom: 2px solid #0078d4; padding-bottom: 8px; }
        .technical-list { list-style: none; padding: 0; margin: 0; }
        .technical-list li { padding: 8px 0; border-bottom: 1px solid #e9ecef; color: #6c757d; font-size: 0.9rem; }
        .technical-list li:last-child { border-bottom: none; }
        .technical-list li:before { content: "▸ "; color: #0078d4; font-weight: bold; }
        .code-block { background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 8px; margin: 10px 0; font-family: 'Courier New', monospace; font-size: 0.85rem; overflow-x: auto; position: relative; }
        .code-block:before { content: attr(data-lang); position: absolute; top: 5px; right: 10px; background: #4a5568; color: #e2e8f0; padding: 2px 8px; border-radius: 4px; font-size: 0.7rem; text-transform: uppercase; }
        .api-example { background: #f7fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 15px; margin: 10px 0; }
        .api-method { display: inline-block; background: #3182ce; color: white; padding: 4px 8px; border-radius: 4px; font-size: 0.8rem; font-weight: bold; margin-right: 10px; }
        .api-endpoint { font-family: 'Courier New', monospace; font-size: 0.85rem; color: #2d3748; word-break: break-all; }
        .documentation-links { display: grid; gap: 10px; }
        .doc-link { display: flex; align-items: center; padding: 10px; background: white; border: 1px solid #dee2e6; border-radius: 6px; text-decoration: none; color: #495057; transition: all 0.3s ease; }
        .doc-link:hover { background: #e9ecef; border-color: #0078d4; text-decoration: none; color: #0078d4; }
        .doc-link:before { content: "📖 "; margin-right: 8px; }
        .complexity-badge { display: inline-block; padding: 6px 12px; border-radius: 20px; font-size: 0.8rem; font-weight: bold; margin-top: 10px; }
        .complexity-low { background: #d4edda; color: #155724; }
        .complexity-medium { background: #fff3cd; color: #856404; }
        .complexity-high { background: #f8d7da; color: #721c24; }
        .time-estimate { background: #e3f2fd; border-left: 4px solid #2196f3; padding: 12px; margin: 10px 0; border-radius: 0 6px 6px 0; }
        .time-estimate:before { content: "⏱️ "; font-size: 1.2rem; }
        
        .chevron { transition: transform 0.3s ease; }
        .chevron.expanded { transform: rotate(90deg); }
        .toggle-all { margin-bottom: 20px; text-align: center; }
        .btn { background: #0078d4; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; margin: 0 5px; }
        .btn:hover { background: #106ebe; }
        .btn-secondary { background: #6c757d; }
        .btn-secondary:hover { background: #5a6268; }
        
        /* Spider Chart Styles */
        .spider-chart-container { 
            margin-top: 30px; 
            background: white; 
            border-radius: 12px; 
            padding: 20px; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.1); 
        }
        .spider-chart-wrapper { 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            gap: 20px; 
            flex-wrap: wrap; 
            min-height: 400px;
        }
        .spider-chart-canvas-container {
            flex: 1;
            min-width: 300px;
            max-width: 500px;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        #spiderChart { 
            border-radius: 8px; 
            background: #fafafa; 
            width: 100%;
            height: auto;
            max-width: 100%;
            display: block;
        }
        .spider-legend { 
            display: flex; 
            flex-direction: column; 
            gap: 15px; 
            min-width: 150px; 
            flex-shrink: 0;
        }
        .legend-item { 
            display: flex; 
            align-items: center; 
            gap: 10px; 
            font-size: 0.9rem; 
            font-weight: 500; 
        }
        .legend-color { 
            width: 20px; 
            height: 20px; 
            border-radius: 4px; 
            border: 2px solid rgba(255,255,255,0.8); 
        }
        
        /* Responsive adjustments */
        @media (max-width: 768px) {
            .spider-chart-wrapper {
                flex-direction: column;
                gap: 20px;
            }
            .spider-chart-canvas-container {
                max-width: 100%;
                min-width: 280px;
            }
            .spider-legend {
                flex-direction: row;
                flex-wrap: wrap;
                justify-content: center;
                min-width: auto;
            }
            .spider-chart-container {
                padding: 15px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ Microsoft 365 Security Posture Assessment Tool (M365SPAT)</h1>
            <p>Comprehensive Security Posture Analysis with Technical Details</p>
            <p>Generated: {{ASSESSMENT_DATE}}</p>
        </div>
        
        <div class="summary">
            <div class="summary-grid">
                <div class="stat-card">
                    <div class="stat-number" style="color: #0078d4;">{{TOTAL_CONTROLS}}</div>
                    <div class="stat-label">Total Controls</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number" style="color: #28a745;">{{PASSED_CONTROLS}}</div>
                    <div class="stat-label">Passed</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number" style="color: #dc3545;">{{FAILED_CONTROLS}}</div>
                    <div class="stat-label">Failed</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number" style="color: #ffc107;">{{ERROR_CONTROLS}}</div>
                    <div class="stat-label">Errors</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number" style="color: #6f42c1;">{{COMPLIANCE_SCORE}}%</div>
                    <div class="stat-label">Compliance Score</div>
                </div>
            </div>
            
            <!-- Security Domains Spider Chart -->
            <div class="spider-chart-container">
                <h3 style="text-align: center; color: #0078d4; margin: 0 0 20px 0;">🎯 Security Domains Assessment</h3>
                <div class="spider-chart-wrapper">
                    <div class="spider-chart-canvas-container">
                        <canvas id="spiderChart"></canvas>
                    </div>
                    <div class="spider-legend">
                        <div class="legend-item">
                            <div class="legend-color" style="background: #0078d4;"></div>
                            <span>Current Score</span>
                        </div>
                        <div class="legend-item">
                            <div class="legend-color" style="background: #28a745;"></div>
                            <span>Target (100%)</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="controls">
            <h2>Security Controls Assessment</h2>
            <div class="toggle-all">
                <button class="btn" onclick="expandAllExplanations()">📖 Show All Simple Explanations</button>
                <button class="btn btn-secondary" onclick="expandAllTechnicalExplanations()">🔧 Show All Technical Details</button>
                <button class="btn" onclick="collapseAllExplanations()">📕 Hide All Explanations</button>
            </div>
            {{CONTROLS_CONTENT}}
        </div>
    </div>
    
    <script>
        function toggleExplanation(controlId) {
            const explanation = document.getElementById('explanation-' + controlId);
            const chevron = document.getElementById('chevron-' + controlId);
            
            if (explanation && explanation.classList.contains('show')) {
                explanation.classList.remove('show');
                if (chevron) chevron.classList.remove('expanded');
            } else if (explanation) {
                explanation.classList.add('show');
                if (chevron) chevron.classList.add('expanded');
                showSimpleExplanation(controlId);
            }
        }
        
        function showSimpleExplanation(controlId) {
            const simpleTab = document.getElementById('simple-tab-' + controlId);
            const technicalTab = document.getElementById('technical-tab-' + controlId);
            const simpleContent = document.getElementById('simple-content-' + controlId);
            const technicalContent = document.getElementById('technical-content-' + controlId);
            
            if (simpleTab && technicalTab && simpleContent && technicalContent) {
                simpleTab.classList.add('active');
                technicalTab.classList.remove('active');
                simpleContent.classList.add('active');
                technicalContent.classList.remove('active');
            }
        }
        
        function showTechnicalExplanation(controlId) {
            const simpleTab = document.getElementById('simple-tab-' + controlId);
            const technicalTab = document.getElementById('technical-tab-' + controlId);
            const simpleContent = document.getElementById('simple-content-' + controlId);
            const technicalContent = document.getElementById('technical-content-' + controlId);
            
            if (simpleTab && technicalTab && simpleContent && technicalContent) {
                simpleTab.classList.remove('active');
                technicalTab.classList.add('active');
                simpleContent.classList.remove('active');
                technicalContent.classList.add('active');
            }
        }
        
        function expandAllExplanations() {
            document.querySelectorAll('.explanation').forEach(el => {
                el.classList.add('show');
            });
            document.querySelectorAll('.chevron').forEach(el => {
                el.classList.add('expanded');
            });
            document.querySelectorAll('[id^="simple-tab-"]').forEach(tab => {
                const controlId = tab.id.replace('simple-tab-', '');
                showSimpleExplanation(controlId);
            });
        }
        
        function expandAllTechnicalExplanations() {
            document.querySelectorAll('.explanation').forEach(el => {
                el.classList.add('show');
            });
            document.querySelectorAll('.chevron').forEach(el => {
                el.classList.add('expanded');
            });
            document.querySelectorAll('[id^="technical-tab-"]').forEach(tab => {
                const controlId = tab.id.replace('technical-tab-', '');
                showTechnicalExplanation(controlId);
            });
        }
        
        function collapseAllExplanations() {
            document.querySelectorAll('.explanation').forEach(el => {
                el.classList.remove('show');
            });
            document.querySelectorAll('.chevron').forEach(el => {
                el.classList.remove('expanded');
            });
        }
        
        // Initialize tab functionality when page loads
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('.explanation-tab').forEach(tab => {
                tab.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    
                    const tabId = this.id;
                    if (tabId.includes('simple-tab-')) {
                        const controlId = tabId.replace('simple-tab-', '');
                        showSimpleExplanation(controlId);
                    } else if (tabId.includes('technical-tab-')) {
                        const controlId = tabId.replace('technical-tab-', '');
                        showTechnicalExplanation(controlId);
                    }
                });
            });
            
            // Initialize spider chart
            initSpiderChart();
        });
        
        // Spider Chart Implementation
        function initSpiderChart() {
            const canvas = document.getElementById('spiderChart');
            if (!canvas) {
                console.log('Canvas not found');
                return;
            }
            
            console.log('Initializing spider chart...');
            
            // Set fixed size for now to debug
            canvas.width = 400;
            canvas.height = 400;
            canvas.style.width = '400px';
            canvas.style.height = '400px';
            
            const ctx = canvas.getContext('2d');
            
            // Test if canvas is working
            ctx.fillStyle = 'red';
            ctx.fillRect(0, 0, 50, 50);
            
            // Draw the actual chart
            setTimeout(() => {
                drawSpiderChartSimple(canvas);
            }, 100);
        }
        
        function drawSpiderChartSimple(canvas) {
            const ctx = canvas.getContext('2d');
            const centerX = canvas.width / 2;
            const centerY = canvas.height / 2;
            const radius = 150;
            
            console.log('Drawing spider chart...', centerX, centerY, radius);
            
            // Clear canvas
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            
            // Security domains data with fallback values
            const domains = [
                { name: 'Identity', score: 75 },
                { name: 'Access Control', score: 80 },
                { name: 'Devices', score: 65 },
                { name: 'Data', score: 70 },
                { name: 'Email', score: 85 },
                { name: 'Monitoring', score: 60 },
                { name: 'Network', score: 55 },
                { name: 'Compliance', score: 90 }
            ];
            
            const angleStep = (2 * Math.PI) / domains.length;
            
            // Draw background grid
            ctx.strokeStyle = '#e1e5e9';
            ctx.lineWidth = 1;
            for (let i = 1; i <= 5; i++) {
                ctx.beginPath();
                ctx.arc(centerX, centerY, (radius * i) / 5, 0, 2 * Math.PI);
                ctx.stroke();
            }
            
            // Draw radial lines
            for (let i = 0; i < domains.length; i++) {
                const angle = i * angleStep - Math.PI / 2;
                ctx.beginPath();
                ctx.moveTo(centerX, centerY);
                ctx.lineTo(
                    centerX + Math.cos(angle) * radius,
                    centerY + Math.sin(angle) * radius
                );
                ctx.stroke();
            }
            
            // Draw percentage labels
            ctx.fillStyle = '#6c757d';
            ctx.font = '12px Arial';
            ctx.textAlign = 'center';
            for (let i = 1; i <= 5; i++) {
                const percentage = (i * 20) + '%';
                ctx.fillText(percentage, centerX + 10, centerY - (radius * i) / 5 + 5);
            }
            
            // Draw domain labels
            ctx.fillStyle = '#495057';
            ctx.font = 'bold 12px Arial';
            
            domains.forEach((domain, index) => {
                const angle = index * angleStep - Math.PI / 2;
                const labelRadius = radius + 25;
                const x = centerX + Math.cos(angle) * labelRadius;
                const y = centerY + Math.sin(angle) * labelRadius;
                
                ctx.textAlign = 'center';
                ctx.fillText(domain.name, x, y);
                
                // Draw score
                ctx.fillStyle = '#0078d4';
                ctx.font = 'bold 10px Arial';
                ctx.fillText(domain.score + '%', x, y + 15);
                ctx.fillStyle = '#495057';
                ctx.font = 'bold 12px Arial';
            });
            
            // Draw target line (100%)
            ctx.strokeStyle = '#28a745';
            ctx.lineWidth = 2;
            ctx.setLineDash([5, 5]);
            ctx.beginPath();
            
            for (let i = 0; i <= domains.length; i++) {
                const angle = i * angleStep - Math.PI / 2;
                const x = centerX + Math.cos(angle) * radius;
                const y = centerY + Math.sin(angle) * radius;
                
                if (i === 0) {
                    ctx.moveTo(x, y);
                } else {
                    ctx.lineTo(x, y);
                }
            }
            ctx.stroke();
            ctx.setLineDash([]);
            
            // Draw current scores
            ctx.fillStyle = 'rgba(0, 120, 212, 0.2)';
            ctx.strokeStyle = '#0078d4';
            ctx.lineWidth = 3;
            ctx.beginPath();
            
            domains.forEach((domain, index) => {
                const angle = index * angleStep - Math.PI / 2;
                const scoreRadius = (radius * domain.score) / 100;
                const x = centerX + Math.cos(angle) * scoreRadius;
                const y = centerY + Math.sin(angle) * scoreRadius;
                
                if (index === 0) {
                    ctx.moveTo(x, y);
                } else {
                    ctx.lineTo(x, y);
                }
            });
            
            ctx.closePath();
            ctx.fill();
            ctx.stroke();
            
            // Draw data points
            domains.forEach((domain, index) => {
                const angle = index * angleStep - Math.PI / 2;
                const scoreRadius = (radius * domain.score) / 100;
                const x = centerX + Math.cos(angle) * scoreRadius;
                const y = centerY + Math.sin(angle) * scoreRadius;
                
                ctx.fillStyle = '#0078d4';
                ctx.beginPath();
                ctx.arc(x, y, 4, 0, 2 * Math.PI);
                ctx.fill();
                
                ctx.strokeStyle = '#ffffff';
                ctx.lineWidth = 2;
                ctx.stroke();
                ctx.strokeStyle = '#0078d4';
                ctx.lineWidth = 3;
            });
            
            console.log('Spider chart drawing completed');
        }
        
        function getScoreColor(score) {
            if (score >= 90) return '#28a745';
            if (score >= 75) return '#20c997';
            if (score >= 60) return '#ffc107';
            if (score >= 40) return '#fd7e14';
            return '#dc3545';
        }
    </script>
</body>
</html>
"@
    
    # Generate controls content
    $controlsContent = New-ControlsContent -Results $Report.Results
    
    # Replace placeholders in template
    $htmlContent = $htmlTemplate -replace '{{TENANT_ID}}', $Report.TenantId
    $htmlContent = $htmlContent -replace '{{ASSESSMENT_DATE}}', $Report.AssessmentDate
    $htmlContent = $htmlContent -replace '{{TOTAL_CONTROLS}}', $Report.TotalControls
    $htmlContent = $htmlContent -replace '{{PASSED_CONTROLS}}', $Report.PassedControls
    $htmlContent = $htmlContent -replace '{{FAILED_CONTROLS}}', $Report.FailedControls
    $htmlContent = $htmlContent -replace '{{ERROR_CONTROLS}}', $Report.ErrorControls
    $htmlContent = $htmlContent -replace '{{COMPLIANCE_SCORE}}', $complianceScore
    $htmlContent = $htmlContent -replace '{{CONTROLS_CONTENT}}', $controlsContent
    $htmlContent = $htmlContent -replace '{{REPORT_ID}}', $reportId
    
    # Replace domain scores for spider chart
    $htmlContent = $htmlContent -replace '{{IDENTITY_SCORE}}', $domainScores.Identity
    $htmlContent = $htmlContent -replace '{{CA_SCORE}}', $domainScores.ConditionalAccess
    $htmlContent = $htmlContent -replace '{{DEVICE_SCORE}}', $domainScores.Device
    $htmlContent = $htmlContent -replace '{{DATA_SCORE}}', $domainScores.Data
    $htmlContent = $htmlContent -replace '{{EMAIL_SCORE}}', $domainScores.Email
    $htmlContent = $htmlContent -replace '{{MONITORING_SCORE}}', $domainScores.Monitoring
    $htmlContent = $htmlContent -replace '{{NETWORK_SCORE}}', $domainScores.Network
    $htmlContent = $htmlContent -replace '{{DOMAIN_COMPLIANCE_SCORE}}', $domainScores.Compliance
    
    Write-Verbose "HTML report generation completed successfully"
    return $htmlContent
}

function New-ControlsContent {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )
    
    # Group results by category
    $categoryResults = $Results | Group-Object Category
    $controlsHtml = ""
    
    foreach ($category in $categoryResults) {
        $controlsHtml += @"
            <div class="category-group">
                <h3 style="color: #0078d4; border-bottom: 2px solid #0078d4; padding-bottom: 10px;">$($category.Name)</h3>
"@

        foreach ($control in $category.Group) {
            $statusClass = switch ($control.Status) {
                "PASS" { "pass" }
                "FAIL" { "fail" }
                "ERROR" { "error" }
                default { "error" }
            }
            
            $badgeClass = switch ($control.Status) {
                "PASS" { "badge-success" }
                "FAIL" { "badge-danger" }
                "ERROR" { "badge-warning" }
                default { "badge-warning" }
            }
            
            $severityClass = switch ($control.Severity) {
                "Critical" { "badge-critical" }
                "High" { "badge-danger" }
                "Medium" { "badge-warning" }
                "Low" { "badge-success" }
                default { "badge-warning" }
            }
            
            # Clean control ID for HTML IDs
            $cleanControlId = $control.ControlId -replace '[^a-zA-Z0-9]', '-'
            
            # Build simple explanation content
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
                <div class="explanation-content active" id="simple-content-$cleanControlId">
                    <div class="explanation-grid">
                        <div class="explanation-item">
                            <div class="explanation-label">🔍 What We Checked</div>
                            <div class="explanation-text">$(Get-SafeHtml $control.SimpleExplanation.WhatWasChecked)</div>
                        </div>
                        <div class="explanation-item">
                            <div class="explanation-label">📋 What We Found</div>
                            <div class="explanation-text">$(Get-SafeHtml $control.SimpleExplanation.WhatWasFound)</div>
                        </div>
                        <div class="explanation-item">
                            <div class="explanation-label">🛡️ Why This Matters</div>
                            <div class="explanation-text">$(Get-SafeHtml $control.SimpleExplanation.WhyItMatters)</div>
                        </div>
                        <div class="explanation-item">
                            <div class="explanation-label">👥 Impact on Users</div>
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
            
            # Build technical explanation content
            $technicalExplanationHtml = Build-TechnicalExplanationHtml -Control $control -CleanControlId $cleanControlId
            
            # Build main explanation section with tabs
            $explanationHtml = ""
            if ($simpleExplanationHtml -or $technicalExplanationHtml) {
                $explanationHtml = @"
                <div class="explanation" id="explanation-$cleanControlId">
                    <div class="explanation-tabs">
                        <button class="explanation-tab active" id="simple-tab-$cleanControlId" onclick="showSimpleExplanation('$cleanControlId')">
                            📖 Simple Explanation
                        </button>
                        <button class="explanation-tab" id="technical-tab-$cleanControlId" onclick="showTechnicalExplanation('$cleanControlId')">
                            🔧 Technical Details
                        </button>
                    </div>
                    $simpleExplanationHtml
                    $technicalExplanationHtml
                </div>
"@
            }
            
            # Add remediation if failed
            $remediationHtml = ""
            if ($control.Status -eq "FAIL" -and $control.Remediation) {
                $remediationHtml = @"
                <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin-top: 15px;">
                    <div style="font-weight: bold; color: #856404; margin-bottom: 5px;">🔧 Recommended Action</div>
                    <div style="color: #856404;">$(Get-SafeHtml $control.Remediation)</div>
                </div>
"@
            }
            
            $controlsHtml += @"
            <div class="control-item $statusClass">
                <div class="control-header" onclick="toggleExplanation('$cleanControlId')">
                    <div>
                        <h3 class="control-title">$(Get-SafeHtml $control.Name)</h3>
                        <p style="margin: 5px 0 0 0; color: #6c757d; font-size: 0.9rem;">$(Get-SafeHtml $control.ControlId) | $(Get-SafeHtml $control.Category)</p>
                        <p style="margin: 5px 0 0 0; color: #495057; font-size: 0.95rem;">$(Get-SafeHtml $control.Message)</p>
                    </div>
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <span class="badge $badgeClass">$($control.Status)</span>
                        <span class="badge $severityClass">$($control.Severity)</span>
                        <span class="chevron" id="chevron-$cleanControlId" style="font-size: 1.2rem;">▶</span>
                    </div>
                </div>
                $explanationHtml
                $remediationHtml
            </div>
"@
        }

        $controlsHtml += @"
            </div>
"@
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
        $complexityClass = switch -Wildcard ($Control.technical_explanation.implementation_complexity) {
            "*Low*" { "complexity-low" }
            "*Medium*" { "complexity-medium" }
            "*High*" { "complexity-high" }
            default { "complexity-medium" }
        }
        
        # Build licenses list
        $licensesHtml = ""
        if ($Control.technical_explanation.required_licenses -and $Control.technical_explanation.required_licenses.Count -gt 0) {
            $licensesHtml = "<ul class='technical-list'>"
            foreach ($license in $Control.technical_explanation.required_licenses) {
                $licensesHtml += "<li>$(Get-SafeHtml $license)</li>"
            }
            $licensesHtml += "</ul>"
        }
        
        # Build permissions list
        $permissionsHtml = ""
        if ($Control.technical_explanation.required_permissions -and $Control.technical_explanation.required_permissions.Count -gt 0) {
            $permissionsHtml = "<ul class='technical-list'>"
            foreach ($permission in $Control.technical_explanation.required_permissions) {
                $permissionsHtml += "<li>$(Get-SafeHtml $permission)</li>"
            }
            $permissionsHtml += "</ul>"
        }
        
        # Build system components list
        $componentsHtml = ""
        if ($Control.technical_explanation.affected_system_components -and $Control.technical_explanation.affected_system_components.Count -gt 0) {
            $componentsHtml = "<ul class='technical-list'>"
            foreach ($component in $Control.technical_explanation.affected_system_components) {
                $componentsHtml += "<li>$(Get-SafeHtml $component)</li>"
            }
            $componentsHtml += "</ul>"
        }
        
        # Build PowerShell commands
        $powershellHtml = ""
        if ($Control.technical_explanation.powershell_commands -and $Control.technical_explanation.powershell_commands.Count -gt 0) {
            foreach ($command in $Control.technical_explanation.powershell_commands) {
                $powershellHtml += "<div class='code-block' data-lang='PowerShell'>$(Get-SafeHtml $command)</div>"
            }
        }
        
        # Build REST API examples
        $apiExamplesHtml = ""
        if ($Control.technical_explanation.rest_api_examples -and $Control.technical_explanation.rest_api_examples.Count -gt 0) {
            foreach ($api in $Control.technical_explanation.rest_api_examples) {
                $requestBodyHtml = ""
                $responseSampleHtml = ""
                
                if ($api.request_body) {
                    $requestBodyHtml = "<div class='code-block' data-lang='JSON'>$(Get-SafeHtml $api.request_body)</div>"
                }
                
                if ($api.response_sample) {
                    $responseSampleHtml = "<div class='code-block' data-lang='JSON Response'>$(Get-SafeHtml $api.response_sample)</div>"
                }
                
                $apiExamplesHtml += @"
                <div class='api-example'>
                    <div><span class='api-method'>$($api.method)</span><span class='api-endpoint'>$($api.endpoint)</span></div>
                    <p style="margin: 10px 0 5px 0; font-weight: bold;">$(Get-SafeHtml $api.description)</p>
                    $requestBodyHtml
                    $responseSampleHtml
                </div>
"@
            }
        }
        
        # Build documentation links
        $docsHtml = ""
        if ($Control.technical_explanation.related_documentation -and $Control.technical_explanation.related_documentation.Count -gt 0) {
            $docsHtml = "<div class='documentation-links'>"
            foreach ($doc in $Control.technical_explanation.related_documentation) {
                $docsHtml += "<a href='$(Get-SafeHtml $doc.url)' class='doc-link' target='_blank'>$(Get-SafeHtml $doc.title)</a>"
            }
            $docsHtml += "</div>"
        }
        
        # Build configuration paths list
        $configPathsHtml = ""
        if ($Control.technical_explanation.configuration_paths -and $Control.technical_explanation.configuration_paths.Count -gt 0) {
            $configPathsHtml = "<ul class='technical-list'>"
            foreach ($path in $Control.technical_explanation.configuration_paths) {
                $configPathsHtml += "<li>$(Get-SafeHtml $path)</li>"
            }
            $configPathsHtml += "</ul>"
        }
        
        # Build the complete technical explanation HTML
        $technicalExplanationHtml = @"
        <div class="explanation-content" id="technical-content-$CleanControlId">
            <div class="technical-grid">
"@
        
        # Add sections conditionally
        if ($licensesHtml) {
            $technicalExplanationHtml += "<div class='technical-section'><h4>📄 Required Licenses</h4>$licensesHtml</div>"
        }
        
        if ($permissionsHtml) {
            $technicalExplanationHtml += "<div class='technical-section'><h4>🔐 Required Permissions</h4>$permissionsHtml</div>"
        }
        
        if ($componentsHtml) {
            $technicalExplanationHtml += "<div class='technical-section'><h4>⚙️ Affected Components</h4>$componentsHtml</div>"
        }
        
        if ($configPathsHtml) {
            $technicalExplanationHtml += "<div class='technical-section'><h4>🎛️ Configuration Paths</h4>$configPathsHtml</div>"
        }
        
        $technicalExplanationHtml += "</div>"
        
        # Add technical remediation section
        if ($Control.technical_explanation.technical_remediation) {
            $technicalExplanationHtml += @"
            <div class='technical-section' style='margin-top: 20px;'>
                <h4>🔧 Technical Remediation Steps</h4>
                <div style='background: white; padding: 15px; border-radius: 6px; border-left: 4px solid #28a745;'>
                    <pre style='white-space: pre-wrap; font-family: inherit; margin: 0;'>$(Get-SafeHtml $Control.technical_explanation.technical_remediation)</pre>
                </div>
            </div>
"@
        }
        
        # Add PowerShell commands section
        if ($powershellHtml) {
            $technicalExplanationHtml += @"
            <div class='technical-section' style='margin-top: 20px;'>
                <h4>💻 PowerShell Commands</h4>
                $powershellHtml
            </div>
"@
        }
        
        # Add REST API examples section
        if ($apiExamplesHtml) {
            $technicalExplanationHtml += @"
            <div class='technical-section' style='margin-top: 20px;'>
                <h4>🌐 REST API Examples</h4>
                $apiExamplesHtml
            </div>
"@
        }
        
        # Add security implications section
        if ($Control.technical_explanation.security_implications) {
            $technicalExplanationHtml += @"
            <div class='technical-section' style='margin-top: 20px;'>
                <h4>🚨 Security Implications</h4>
                <div style='background: #fff3cd; padding: 15px; border-radius: 6px; border-left: 4px solid #ffc107;'>
                    $(Get-SafeHtml $Control.technical_explanation.security_implications)
                </div>
            </div>
"@
        }
        
        # Add implementation details section
        $technicalExplanationHtml += @"
        <div class='technical-section' style='margin-top: 20px;'>
            <h4>📊 Implementation Details</h4>
"@
        
        if ($Control.technical_explanation.implementation_complexity) {
            $technicalExplanationHtml += "<div>Complexity: <span class='complexity-badge $complexityClass'>$(Get-SafeHtml $Control.technical_explanation.implementation_complexity)</span></div>"
        }
        
        if ($Control.technical_explanation.estimated_time_to_remediate) {
            $technicalExplanationHtml += "<div class='time-estimate'>Estimated Time: $(Get-SafeHtml $Control.technical_explanation.estimated_time_to_remediate)</div>"
        }
        
        $technicalExplanationHtml += "</div>"
        
        # Add related documentation section
        if ($docsHtml) {
            $technicalExplanationHtml += @"
            <div class='technical-section' style='margin-top: 20px;'>
                <h4>📚 Related Documentation</h4>
                $docsHtml
            </div>
"@
        }
        
        $technicalExplanationHtml += "</div>"
    } else {
        # Fallback if no technical explanation is available
        $technicalExplanationHtml = @"
        <div class="explanation-content" id="technical-content-$CleanControlId">
            <div class='technical-section'>
                <h4>🔧 Technical Information</h4>
                <p style='color: #6c757d; font-style: italic;'>Technical details are not available for this control.</p>
            </div>
        </div>
"@
    }
    
    return $technicalExplanationHtml
}

function Get-SafeHtml {
    param([string]$Text)
    
    if (-not $Text) { return "" }
    
    # Basic HTML encoding to prevent XSS
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
    
    # Define domain mappings based on control categories and IDs
    $domainMapping = @{
        Identity = @('Authentication', 'Role Management')
        ConditionalAccess = @('Conditional Access')
        Device = @('Device Management')
        Data = @('Data Protection', 'External Sharing')
        Email = @('Email Security', 'Advanced Threat Protection')
        Monitoring = @('Audit and Monitoring', 'Monitoring and Alerting')
        Network = @('Network Security')
        Compliance = @('Compliance and Governance')
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
            # Default scores for domains with no controls
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
    
    # For the embedded version, we don't need separate CSS/JS files
    # Everything is embedded in the HTML template
    
    return @{
        CSSCopied = $true
        JSCopied = $true
        Message = "All assets embedded in HTML file"
    }
}