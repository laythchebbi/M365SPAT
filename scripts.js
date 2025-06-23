// Enhanced Microsoft 365 Security Assessment Report Scripts
// Version: 4.0 - Technical Explanations Support

document.addEventListener('DOMContentLoaded', function() {
    initializeEnhancedReport();
});

// Enhanced initialization with technical features
function initializeEnhancedReport() {
    setupThemeToggle();
    setupScoreAnimation();
    setupCategoryToggle();
    setupFilters();
    setupSearch();
    setupTooltips();
    setupKeyboardShortcuts();
    setupScrollEffects();
    setupTechnicalFeatures();
    setupCodeBlocks();
    setupExportFeatures();
    
    console.log('Enhanced technical report initialized');
}

// Technical Features Setup
function setupTechnicalFeatures() {
    setupCodeCopyButtons();
    setupApiExampleCollapse();
    setupLicenseChecker();
    setupPermissionValidator();
    setupConfigurationPathClicks();
    setupDocumentationTracking();
}

// Enhanced Code Block Features
function setupCodeBlocks() {
    const codeBlocks = document.querySelectorAll('.code-block');
    
    codeBlocks.forEach((block, index) => {
        // Add copy button to each code block
        const copyButton = document.createElement('button');
        copyButton.className = 'code-copy-btn';
        copyButton.innerHTML = '📋 Copy';
        copyButton.style.cssText = `
            position: absolute;
            top: 10px;
            right: 45px;
            background: #4a5568;
            color: #e2e8f0;
            border: none;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 0.75rem;
            cursor: pointer;
            transition: background 0.2s ease;
            z-index: 10;
        `;
        
        copyButton.addEventListener('mouseenter', function() {
            this.style.background = '#2d3748';
        });
        
        copyButton.addEventListener('mouseleave', function() {
            this.style.background = '#4a5568';
        });
        
        copyButton.addEventListener('click', function(e) {
            e.stopPropagation();
            copyCodeToClipboard(block.textContent, this);
        });
        
        block.style.position = 'relative';
        block.appendChild(copyButton);
        
        // Add line numbers for longer code blocks
        const lines = block.textContent.split('\n');
        if (lines.length > 3) {
            addLineNumbers(block, lines.length);
        }
    });
}

function addLineNumbers(codeBlock, lineCount) {
    const lineNumbers = document.createElement('div');
    lineNumbers.className = 'line-numbers';
    lineNumbers.style.cssText = `
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        width: 40px;
        background: #1a202c;
        border-right: 1px solid #4a5568;
        font-family: 'Courier New', monospace;
        font-size: 0.75rem;
        color: #718096;
        padding: 15px 5px;
        line-height: 1.4;
        user-select: none;
        overflow: hidden;
    `;
    
    for (let i = 1; i <= lineCount; i++) {
        lineNumbers.innerHTML += i + '\n';
    }
    
    codeBlock.style.paddingLeft = '50px';
    codeBlock.appendChild(lineNumbers);
}

function copyCodeToClipboard(text, button) {
    // Clean up the text (remove line numbers if present)
    const cleanText = text.replace(/^\d+\s*/gm, '');
    
    navigator.clipboard.writeText(cleanText).then(() => {
        const originalText = button.innerHTML;
        button.innerHTML = '✅ Copied!';
        button.style.background = '#48bb78';
        
        setTimeout(() => {
            button.innerHTML = originalText;
            button.style.background = '#4a5568';
        }, 2000);
        
        showNotification('Code copied to clipboard!', 'success');
    }).catch(err => {
        console.error('Failed to copy: ', err);
        showNotification('Failed to copy code', 'error');
    });
}

// Setup Code Copy Buttons
function setupCodeCopyButtons() {
    const copyButtons = document.querySelectorAll('.code-copy-btn');
    
    copyButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            const codeBlock = this.closest('.code-block');
            if (codeBlock) {
                copyCodeToClipboard(codeBlock.textContent, this);
            }
        });
    });
}

// API Examples Collapse/Expand
function setupApiExampleCollapse() {
    const apiExamples = document.querySelectorAll('.api-example');
    
    apiExamples.forEach(example => {
        const codeBlocks = example.querySelectorAll('.code-block');
        if (codeBlocks.length > 0) {
            const toggleButton = document.createElement('button');
            toggleButton.className = 'api-toggle';
            toggleButton.innerHTML = '▼ Show Details';
            toggleButton.style.cssText = `
                background: #3182ce;
                color: white;
                border: none;
                padding: 5px 10px;
                border-radius: 4px;
                font-size: 0.8rem;
                cursor: pointer;
                margin: 5px 0;
                transition: background 0.2s ease;
            `;
            
            toggleButton.addEventListener('click', function() {
                const isExpanded = this.textContent.includes('Hide');
                
                codeBlocks.forEach(block => {
                    block.style.display = isExpanded ? 'none' : 'block';
                });
                
                this.innerHTML = isExpanded ? '▼ Show Details' : '▲ Hide Details';
                this.style.background = isExpanded ? '#3182ce' : '#2c5282';
            });
            
            // Initially hide code blocks
            codeBlocks.forEach(block => {
                block.style.display = 'none';
            });
            
            example.insertBefore(toggleButton, codeBlocks[0]);
        }
    });
}

// License Requirement Checker
function setupLicenseChecker() {
    const licenseItems = document.querySelectorAll('.technical-list li');
    
    licenseItems.forEach(item => {
        const text = item.textContent.toLowerCase();
        if (text.includes('azure ad premium') || text.includes('microsoft 365') || text.includes('office 365')) {
            item.style.cursor = 'pointer';
            item.style.transition = 'all 0.2s ease';
            
            item.addEventListener('mouseenter', function() {
                this.style.background = '#e3f2fd';
                this.style.borderRadius = '4px';
                this.style.padding = '8px';
            });
            
            item.addEventListener('mouseleave', function() {
                this.style.background = '';
                this.style.borderRadius = '';
                this.style.padding = '';
            });
            
            item.addEventListener('click', function() {
                showLicenseInfo(this.textContent);
            });
            
            // Add license icon
            item.style.position = 'relative';
            item.innerHTML += ' <span style="font-size: 0.8em; opacity: 0.7;">ℹ️</span>';
        }
    });
}

function showLicenseInfo(licenseName) {
    const licenseMap = {
        'Azure AD Premium P1': {
            description: 'Includes Conditional Access, group-based access management, and self-service password reset for cloud users.',
            pricing: 'Approximate cost: $6/user/month',
            features: ['Conditional Access', 'Group-based licensing', 'Self-service password reset', 'Cloud app discovery']
        },
        'Azure AD Premium P2': {
            description: 'Includes all P1 features plus Identity Protection and Privileged Identity Management.',
            pricing: 'Approximate cost: $9/user/month',
            features: ['All P1 features', 'Identity Protection', 'Privileged Identity Management', 'Access reviews']
        },
        'Microsoft 365 E3': {
            description: 'Enterprise productivity suite with security and compliance tools.',
            pricing: 'Approximate cost: $32/user/month',
            features: ['Office apps', 'Exchange Online', 'SharePoint Online', 'Teams', 'Azure AD Premium P1']
        },
        'Microsoft 365 E5': {
            description: 'Advanced security, analytics, voice, and compliance capabilities.',
            pricing: 'Approximate cost: $57/user/month',
            features: ['All E3 features', 'Azure AD Premium P2', 'Advanced Threat Protection', 'Cloud App Security']
        }
    };
    
    const info = Object.keys(licenseMap).find(key => licenseName.includes(key));
    if (info && licenseMap[info]) {
        const modal = createLicenseModal(info, licenseMap[info]);
        document.body.appendChild(modal);
    }
}

function createLicenseModal(licenseName, info) {
    const modal = document.createElement('div');
    modal.className = 'license-modal';
    modal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
    `;
    
    const content = document.createElement('div');
    content.style.cssText = `
        background: white;
        border-radius: 8px;
        padding: 20px;
        max-width: 500px;
        max-height: 80vh;
        overflow-y: auto;
        position: relative;
    `;
    
    content.innerHTML = `
        <button onclick="this.closest('.license-modal').remove()" style="position: absolute; top: 10px; right: 15px; background: none; border: none; font-size: 1.5rem; cursor: pointer;">&times;</button>
        <h3 style="color: #0078d4; margin-bottom: 15px;">${licenseName}</h3>
        <p style="margin-bottom: 15px; color: #555;">${info.description}</p>
        <div style="background: #f8f9fa; padding: 15px; border-radius: 6px; margin-bottom: 15px;">
            <strong style="color: #0078d4;">${info.pricing}</strong>
        </div>
        <h4 style="margin-bottom: 10px;">Key Features:</h4>
        <ul style="margin: 0; padding-left: 20px;">
            ${info.features.map(feature => `<li style="margin-bottom: 5px;">${feature}</li>`).join('')}
        </ul>
        <div style="text-align: right; margin-top: 20px;">
            <button onclick="this.closest('.license-modal').remove()" style="background: #0078d4; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer;">Close</button>
        </div>
    `;
    
    modal.appendChild(content);
    
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            modal.remove();
        }
    });
    
    return modal;
}

// Permission Validator
function setupPermissionValidator() {
    const permissionItems = document.querySelectorAll('.technical-list li');
    
    permissionItems.forEach(item => {
        const text = item.textContent;
        if (text.includes('.Read.') || text.includes('.ReadWrite.') || text.includes('.All')) {
            item.style.cursor = 'help';
            item.title = 'Click for permission details';
            
            item.addEventListener('click', function() {
                showPermissionDetails(text);
            });
        }
    });
}

function showPermissionDetails(permission) {
    const permissionInfo = {
        'Policy.Read.All': 'Read your organization\'s policies',
        'Policy.ReadWrite.ConditionalAccess': 'Read and write your organization\'s conditional access policies',
        'Directory.Read.All': 'Read directory data',
        'RoleManagement.Read.Directory': 'Read role management data for your directory',
        'User.Read.All': 'Read all users\' full profiles',
        'Reports.Read.All': 'Read all usage reports',
        'UserAuthenticationMethod.Read.All': 'Read all users\' authentication methods',
        'AuditLog.Read.All': 'Read audit log data',
        'Application.Read.All': 'Read applications',
        'DeviceManagementConfiguration.Read.All': 'Read Microsoft Intune device configuration and policies'
    };
    
    const cleanPermission = permission.replace(/^▸\s*/, '').split(' - ')[0].trim();
    const description = permissionInfo[cleanPermission] || 'Microsoft Graph permission';
    
    showNotification(`${cleanPermission}: ${description}`, 'info', 4000);
}

// Configuration Path Clicks
function setupConfigurationPathClicks() {
    const pathItems = document.querySelectorAll('.technical-list li');
    
    pathItems.forEach(item => {
        const text = item.textContent;
        if (text.includes('Azure Portal') || text.includes('Microsoft 365 Admin Center') || text.includes('PowerShell')) {
            item.style.cursor = 'pointer';
            item.style.color = '#0078d4';
            
            item.addEventListener('click', function() {
                copyToClipboard(text.replace(/^▸\s*/, ''));
                showNotification('Configuration path copied to clipboard', 'success');
            });
            
            item.addEventListener('mouseenter', function() {
                this.style.textDecoration = 'underline';
            });
            
            item.addEventListener('mouseleave', function() {
                this.style.textDecoration = 'none';
            });
        }
    });
}

// Documentation Link Tracking
function setupDocumentationTracking() {
    const docLinks = document.querySelectorAll('.doc-link');
    
    docLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const linkText = this.textContent;
            console.log(`Documentation clicked: ${linkText}`);
            
            // Add visual feedback
            this.style.background = '#e3f2fd';
            setTimeout(() => {
                this.style.background = '';
            }, 200);
        });
    });
}

// Enhanced Export Features
function setupExportFeatures() {
    addExportButtons();
}

function addExportButtons() {
    const toggleSection = document.querySelector('.toggle-all');
    if (toggleSection) {
        const exportTechnicalBtn = document.createElement('button');
        exportTechnicalBtn.className = 'btn btn-secondary';
        exportTechnicalBtn.innerHTML = '📊 Export Technical Summary';
        exportTechnicalBtn.onclick = exportTechnicalSummary;
        
        const exportCodeBtn = document.createElement('button');
        exportCodeBtn.className = 'btn btn-secondary';
        exportCodeBtn.innerHTML = '💻 Export All Code';
        exportCodeBtn.onclick = exportAllCode;
        
        toggleSection.appendChild(exportTechnicalBtn);
        toggleSection.appendChild(exportCodeBtn);
    }
}

function exportTechnicalSummary() {
    const controls = document.querySelectorAll('.control-item');
    let summary = 'Microsoft 365 Security Assessment - Technical Summary\n';
    summary += '=' + '='.repeat(60) + '\n\n';
    
    controls.forEach(control => {
        const title = control.querySelector('.control-title')?.textContent || 'Unknown Control';
        const status = control.querySelector('.badge-success, .badge-danger, .badge-warning')?.textContent || 'Unknown';
        const severity = control.querySelector('.badge-critical, .badge-danger, .badge-warning, .badge-success')?.textContent || 'Unknown';
        
        summary += `Control: ${title}\n`;
        summary += `Status: ${status}\n`;
        summary += `Severity: ${severity}\n`;
        
        // Extract technical details
        const technicalSections = control.querySelectorAll('.technical-section');
        technicalSections.forEach(section => {
            const heading = section.querySelector('h4')?.textContent || '';
            if (heading.includes('Required Licenses')) {
                const licenses = Array.from(section.querySelectorAll('li')).map(li => li.textContent.replace(/^▸\s*/, '')).join(', ');
                summary += `Required Licenses: ${licenses}\n`;
            }
            if (heading.includes('Required Permissions')) {
                const permissions = Array.from(section.querySelectorAll('li')).map(li => li.textContent.replace(/^▸\s*/, '')).join(', ');
                summary += `Required Permissions: ${permissions}\n`;
            }
            if (heading.includes('Implementation Details')) {
                const complexity = section.querySelector('.complexity-badge')?.textContent || 'Unknown';
                const timeEstimate = section.querySelector('.time-estimate')?.textContent?.replace('⏱️ Estimated Time: ', '') || 'Unknown';
                summary += `Complexity: ${complexity}\n`;
                summary += `Estimated Time: ${timeEstimate}\n`;
            }
        });
        
        summary += '\n' + '-'.repeat(80) + '\n\n';
    });
    
    downloadAsFile(summary, 'M365-Security-Technical-Summary.txt', 'text/plain');
}

function exportAllCode() {
    const codeBlocks = document.querySelectorAll('.code-block');
    let codeExport = 'Microsoft 365 Security Assessment - Code Export\n';
    codeExport += '=' + '='.repeat(50) + '\n\n';
    
    codeBlocks.forEach((block, index) => {
        const language = block.getAttribute('data-lang') || 'Code';
        const controlTitle = block.closest('.control-item')?.querySelector('.control-title')?.textContent || 'Unknown Control';
        
        codeExport += `Control: ${controlTitle}\n`;
        codeExport += `Language: ${language}\n`;
        codeExport += '-'.repeat(40) + '\n';
        codeExport += block.textContent.replace(/^\d+\s*/gm, '') + '\n'; // Remove line numbers
        codeExport += '\n' + '='.repeat(80) + '\n\n';
    });
    
    downloadAsFile(codeExport, 'M365-Security-Code-Export.txt', 'text/plain');
}

function downloadAsFile(content, filename, mimeType) {
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    link.style.display = 'none';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
    
    showNotification(`${filename} downloaded successfully!`, 'success');
}

// Enhanced Notification System
function showNotification(message, type = 'info', duration = 3000) {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    
    const icon = getNotificationIcon(type);
    
    notification.innerHTML = `
        <span class="notification-icon">${icon}</span>
        <span class="notification-message">${message}</span>
        <button class="notification-close" onclick="this.parentElement.remove()">×</button>
    `;
    
    // Styling
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${getNotificationColor(type)};
        color: white;
        padding: 15px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        z-index: 1000;
        transform: translateX(100%);
        transition: transform 0.3s ease;
        max-width: 400px;
        display: flex;
        align-items: center;
        gap: 10px;
        font-size: 0.9rem;
    `;
    
    document.body.appendChild(notification);
    
    // Slide in
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Auto-remove
    setTimeout(() => {
        if (notification.parentElement) {
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (notification.parentElement) {
                    notification.remove();
                }
            }, 300);
        }
    }, duration);
    
    // Stack notifications
    stackNotifications();
}

function getNotificationIcon(type) {
    switch (type) {
        case 'success': return '✅';
        case 'error': return '❌';
        case 'warning': return '⚠️';
        case 'info': return 'ℹ️';
        default: return 'ℹ️';
    }
}

function getNotificationColor(type) {
    switch (type) {
        case 'success': return '#28a745';
        case 'error': return '#dc3545';
        case 'warning': return '#ffc107';
        case 'info': return '#17a2b8';
        default: return '#6c757d';
    }
}

function stackNotifications() {
    const notifications = document.querySelectorAll('.notification');
    notifications.forEach((notification, index) => {
        notification.style.top = `${20 + (index * 80)}px`;
    });
}

// Utility Functions
function copyToClipboard(text) {
    return navigator.clipboard.writeText(text);
}

// Original functions from base report (preserved for compatibility)
function setupThemeToggle() {
    const themeToggle = document.createElement('button');
    themeToggle.className = 'theme-toggle';
    themeToggle.innerHTML = '🌙';
    themeToggle.setAttribute('aria-label', 'Toggle theme');
    themeToggle.setAttribute('title', 'Toggle dark/light mode');
    themeToggle.style.cssText = `
        position: fixed;
        top: 20px;
        left: 20px;
        z-index: 1000;
        background: white;
        border: 1px solid #dee2e6;
        border-radius: 8px;
        padding: 10px;
        cursor: pointer;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        transition: all 0.2s ease;
    `;
    document.body.appendChild(themeToggle);

    const savedTheme = localStorage.getItem('theme') || 'light';
    if (savedTheme === 'dark') {
        document.documentElement.classList.add('dark');
        themeToggle.innerHTML = '☀️';
        themeToggle.style.background = '#2d3748';
        themeToggle.style.color = 'white';
    }

    themeToggle.addEventListener('click', function() {
        const isDark = document.documentElement.classList.contains('dark');
        
        if (isDark) {
            document.documentElement.classList.remove('dark');
            themeToggle.innerHTML = '🌙';
            themeToggle.style.background = 'white';
            themeToggle.style.color = 'black';
            localStorage.setItem('theme', 'light');
        } else {
            document.documentElement.classList.add('dark');
            themeToggle.innerHTML = '☀️';
            themeToggle.style.background = '#2d3748';
            themeToggle.style.color = 'white';
            localStorage.setItem('theme', 'dark');
        }
    });
}

function setupScoreAnimation() {
    const scoreText = document.querySelector('.stat-number');
    if (scoreText && scoreText.textContent.includes('%')) {
        const scoreValue = parseFloat(scoreText.textContent);
        animateCountUp(scoreText, 0, scoreValue, 2000);
    }
}

function animateCountUp(element, start, end, duration) {
    const startTime = performance.now();
    const suffix = element.textContent.replace(/[\d.]/g, '');
    
    function update(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const easeOut = 1 - Math.pow(1 - progress, 3);
        const current = start + (end - start) * easeOut;
        
        element.textContent = Math.round(current) + suffix;
        
        if (progress < 1) {
            requestAnimationFrame(update);
        }
    }
    
    requestAnimationFrame(update);
}

function setupCategoryToggle() {
    const categoryHeaders = document.querySelectorAll('.category-group h3');
    
    categoryHeaders.forEach(header => {
        header.style.cursor = 'pointer';
        header.style.userSelect = 'none';
        header.addEventListener('click', function() {
            const categoryGroup = this.parentElement;
            const controls = categoryGroup.querySelectorAll('.control-item');
            const isCollapsed = categoryGroup.classList.contains('collapsed');
            
            if (isCollapsed) {
                categoryGroup.classList.remove('collapsed');
                controls.forEach(control => {
                    control.style.display = 'block';
                });
                this.style.opacity = '1';
            } else {
                categoryGroup.classList.add('collapsed');
                controls.forEach(control => {
                    control.style.display = 'none';
                });
                this.style.opacity = '0.7';
            }
        });
    });
}

function setupFilters() {
    // Add filter controls if not already present
    const controlsSection = document.querySelector('.controls');
    if (controlsSection && !document.querySelector('.filters-section')) {
        const filtersHtml = `
            <div class="filters-section" style="background: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 8px;">
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; align-items: end;">
                    <div>
                        <label for="statusFilter" style="display: block; margin-bottom: 5px; font-weight: 500;">Status</label>
                        <select id="statusFilter" style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                            <option value="">All Statuses</option>
                            <option value="PASS">PASS</option>
                            <option value="FAIL">FAIL</option>
                            <option value="ERROR">ERROR</option>
                        </select>
                    </div>
                    <div>
                        <label for="severityFilter" style="display: block; margin-bottom: 5px; font-weight: 500;">Severity</label>
                        <select id="severityFilter" style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                            <option value="">All Severities</option>
                            <option value="Critical">Critical</option>
                            <option value="High">High</option>
                            <option value="Medium">Medium</option>
                            <option value="Low">Low</option>
                        </select>
                    </div>
                    <div>
                        <button onclick="clearAllFilters()" style="background: #6c757d; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer;">Clear Filters</button>
                    </div>
                </div>
            </div>
        `;
        
        const sectionTitle = controlsSection.querySelector('h2');
        sectionTitle.insertAdjacentHTML('afterend', filtersHtml);
        
        document.getElementById('statusFilter').addEventListener('change', applyFilters);
        document.getElementById('severityFilter').addEventListener('change', applyFilters);
    }
}

function applyFilters() {
    const statusFilter = document.getElementById('statusFilter')?.value || '';
    const severityFilter = document.getElementById('severityFilter')?.value || '';
    
    const controls = document.querySelectorAll('.control-item');
    let visibleCount = 0;
    
    controls.forEach(control => {
        const statusBadge = control.querySelector('.badge-success, .badge-danger, .badge-warning');
        const severityBadge = control.querySelector('.badge-critical, .badge-danger, .badge-warning, .badge-success');
        
        const status = statusBadge ? statusBadge.textContent.trim() : '';
        const severity = severityBadge ? severityBadge.textContent.trim() : '';
        
        const matchesStatus = !statusFilter || status === statusFilter;
        const matchesSeverity = !severityFilter || severity === severityFilter;
        
        if (matchesStatus && matchesSeverity) {
            control.style.display = 'block';
            visibleCount++;
        } else {
            control.style.display = 'none';
        }
    });
    
    showNotification(`Showing ${visibleCount} controls`, 'info', 2000);
}

function clearAllFilters() {
    const statusFilter = document.getElementById('statusFilter');
    const severityFilter = document.getElementById('severityFilter');
    
    if (statusFilter) statusFilter.value = '';
    if (severityFilter) severityFilter.value = '';
    
    document.querySelectorAll('.control-item').forEach(control => {
        control.style.display = 'block';
    });
    
    showNotification('Filters cleared', 'info', 2000);
}

function setupSearch() {
    // Search functionality could be enhanced here
    console.log('Search setup completed');
}

function setupTooltips() {
    // Enhanced tooltip functionality
    console.log('Tooltips setup completed');
}

function setupKeyboardShortcuts() {
    document.addEventListener('keydown', function(e) {
        // Ctrl/Cmd + T for technical view
        if ((e.ctrlKey || e.metaKey) && e.key === 't') {
            e.preventDefault();
            expandAllTechnicalExplanations();
        }
        
        // Ctrl/Cmd + S for simple view
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            expandAllExplanations();
        }
        
        // Escape to collapse all
        if (e.key === 'Escape') {
            collapseAllExplanations();
        }
    });
}

function setupScrollEffects() {
    // Add smooth scrolling and intersection observer effects
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, { threshold: 0.1 });
    
    document.querySelectorAll('.control-item').forEach(item => {
        item.style.opacity = '0';
        item.style.transform = 'translateY(20px)';
        item.style.transition = 'all 0.6s ease';
        observer.observe(item);
    });
}

// Global functions for HTML onclick handlers
window.toggleExplanation = function(controlId) {
    const explanation = document.getElementById('explanation-' + controlId);
    const chevron = document.getElementById('chevron-' + controlId);
    
    if (explanation.classList.contains('show')) {
        explanation.classList.remove('show');
        chevron.classList.remove('expanded');
    } else {
        explanation.classList.add('show');
        chevron.classList.add('expanded');
        // Default to simple explanation
        showSimpleExplanation(controlId);
    }
};

window.showSimpleExplanation = function(controlId) {
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
};

window.showTechnicalExplanation = function(controlId) {
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
};

window.expandAllExplanations = function() {
    document.querySelectorAll('.explanation').forEach(el => {
        el.classList.add('show');
    });
    document.querySelectorAll('.chevron').forEach(el => {
        el.classList.add('expanded');
    });
    // Default to simple explanations
    document.querySelectorAll('[id^="simple-tab-"]').forEach(tab => {
        const controlId = tab.id.replace('simple-tab-', '');
        showSimpleExplanation(controlId);
    });
};

window.expandAllTechnicalExplanations = function() {
    document.querySelectorAll('.explanation').forEach(el => {
        el.classList.add('show');
    });
    document.querySelectorAll('.chevron').forEach(el => {
        el.classList.add('expanded');
    });
    // Show technical explanations
    document.querySelectorAll('[id^="technical-tab-"]').forEach(tab => {
        const controlId = tab.id.replace('technical-tab-', '');
        showTechnicalExplanation(controlId);
    });
};

window.collapseAllExplanations = function() {
    document.querySelectorAll('.explanation').forEach(el => {
        el.classList.remove('show');
    });
    document.querySelectorAll('.chevron').forEach(el => {
        el.classList.remove('expanded');
    });
};