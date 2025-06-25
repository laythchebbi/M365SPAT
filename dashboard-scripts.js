// M365SPAT Dashboard Scripts
// Microsoft 365 Security Posture Assessment Tool
// Version: 6.0 - Enhanced Chart and Cards

// M365SPAT Dashboard Initialization
document.addEventListener('DOMContentLoaded', function() {
    initializeM365SPATDashboard();
    initializeSecurityChart();
});

function initializeM365SPATDashboard() {
    // Animate score circle
    const scoreCircle = document.querySelector('.score-circle');
    if (scoreCircle) {
        const score = parseInt(scoreCircle.style.getPropertyValue('--score') || '0');
        animateScore(scoreCircle, score);
    }

    // Animate stat cards
    animateStatCards();

    // Setup control interactions
    setupControlInteractions();
    
    // Update theme toggle icon based on current theme
    updateThemeToggleIcon();
}

function animateScore(element, targetScore) {
    let currentScore = 0;
    const increment = targetScore / 80; // 80 frames for smoother animation
    
    function updateScore() {
        currentScore += increment;
        if (currentScore >= targetScore) {
            currentScore = targetScore;
        } else {
            requestAnimationFrame(updateScore);
        }
        
        element.style.setProperty('--score', currentScore);
        element.querySelector('.score-value').textContent = Math.round(currentScore) + '%';
        
        // Update circle color based on score
        const scoreColor = getScoreColor(currentScore);
        element.style.background = `conic-gradient(
            ${scoreColor} 0deg calc(${currentScore} * 3.6deg),
            hsl(var(--muted)) calc(${currentScore} * 3.6deg) 360deg
        )`;
    }
    
    updateScore();
}

function animateStatCards() {
    const statCards = document.querySelectorAll('.stat-card');
    statCards.forEach((card, index) => {
        setTimeout(() => {
            const numberElement = card.querySelector('.stat-number');
            const targetNumber = parseInt(numberElement.textContent);
            animateNumber(numberElement, targetNumber);
            
            // Add entrance animation
            card.style.opacity = '0';
            card.style.transform = 'translateY(20px)';
            card.style.animation = `fadeInUp 0.6s ease forwards ${index * 0.1}s`;
        }, 500 + (index * 100));
    });
}

function animateNumber(element, targetNumber) {
    let currentNumber = 0;
    const increment = targetNumber / 50; // 50 frames for number animation
    
    function updateNumber() {
        currentNumber += increment;
        if (currentNumber >= targetNumber) {
            currentNumber = targetNumber;
            element.textContent = Math.round(currentNumber);
        } else {
            element.textContent = Math.round(currentNumber);
            requestAnimationFrame(updateNumber);
        }
    }
    
    updateNumber();
}

function setupControlInteractions() {
    document.querySelectorAll('.control-header').forEach(header => {
        header.addEventListener('click', function() {
            const controlCard = this.closest('.control-card');
            const content = controlCard.querySelector('.control-content');
            const expandIcon = this.querySelector('.expand-icon i');
            const isExpanded = this.classList.contains('expanded');
            
            if (isExpanded) {
                this.classList.remove('expanded');
                content.classList.remove('show');
                expandIcon.className = 'fas fa-chevron-right';
            } else {
                this.classList.add('expanded');
                content.classList.add('show');
                expandIcon.className = 'fas fa-chevron-down';
                // Default to simple tab
                showTab(controlCard, 'simple');
            }
        });
    });

    // Setup tab switching
    document.querySelectorAll('.content-tab').forEach(tab => {
        tab.addEventListener('click', function(e) {
            e.stopPropagation();
            const controlCard = this.closest('.control-card');
            const tabType = this.dataset.tab;
            showTab(controlCard, tabType);
        });
    });
}

function showTab(controlCard, tabType) {
    // Update tab states
    controlCard.querySelectorAll('.content-tab').forEach(tab => {
        tab.classList.toggle('active', tab.dataset.tab === tabType);
    });
    
    // Update content states
    controlCard.querySelectorAll('.tab-content').forEach(content => {
        content.classList.toggle('active', content.dataset.tab === tabType);
    });
}

function expandAllControls() {
    document.querySelectorAll('.control-header').forEach(header => {
        const content = header.closest('.control-card').querySelector('.control-content');
        const expandIcon = header.querySelector('.expand-icon i');
        header.classList.add('expanded');
        content.classList.add('show');
        expandIcon.className = 'fas fa-chevron-down';
        showTab(header.closest('.control-card'), 'simple');
    });
}

function collapseAllControls() {
    document.querySelectorAll('.control-header').forEach(header => {
        const content = header.closest('.control-card').querySelector('.control-content');
        const expandIcon = header.querySelector('.expand-icon i');
        header.classList.remove('expanded');
        content.classList.remove('show');
        expandIcon.className = 'fas fa-chevron-right';
    });
}

function toggleTheme() {
    const body = document.body;
    const themeToggle = document.querySelector('.theme-toggle i');
    
    if (body.classList.contains('light')) {
        body.classList.remove('light');
        themeToggle.className = 'fas fa-moon';
        localStorage.setItem('m365spat-theme', 'dark');
    } else {
        body.classList.add('light');
        themeToggle.className = 'fas fa-sun';
        localStorage.setItem('m365spat-theme', 'light');
    }
}

function updateThemeToggleIcon() {
    const savedTheme = localStorage.getItem('m365spat-theme');
    const themeToggle = document.querySelector('.theme-toggle i');
    
    if (savedTheme === 'light') {
        document.body.classList.add('light');
        if (themeToggle) themeToggle.className = 'fas fa-sun';
    } else {
        if (themeToggle) themeToggle.className = 'fas fa-moon';
    }
}

function initializeSecurityChart() {
    const canvas = document.getElementById('securityChart');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    
    // Make the canvas responsive and larger
    function resizeCanvas() {
        const container = canvas.parentElement;
        const containerRect = container.getBoundingClientRect();
        
        // Set canvas size to fill container with some padding
        const size = Math.min(containerRect.width - 40, containerRect.height - 40);
        canvas.width = size;
        canvas.height = size;
        canvas.style.width = size + 'px';
        canvas.style.height = size + 'px';
        
        // Redraw chart after resize
        drawChart();
    }
    
    function drawChart() {
        // Clear canvas
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        // M365SPAT security domains data with enhanced styling
        const domains = [
            { name: 'Identity & Access', score: 85, color: 'hsl(263, 70%, 50%)', icon: '🔐' },
            { name: 'Device Security', score: 78, color: 'hsl(197, 37%, 24%)', icon: '📱' },
            { name: 'Data Protection', score: 92, color: 'hsl(142, 71%, 45%)', icon: '🛡️' },
            { name: 'Email Security', score: 73, color: 'hsl(38, 92%, 50%)', icon: '📧' },
            { name: 'Network Security', score: 88, color: 'hsl(217, 91%, 60%)', icon: '🌐' },
            { name: 'Compliance', score: 81, color: 'hsl(339, 82%, 62%)', icon: '📋' }
        ];

        drawEnhancedSecurityRadarChart(ctx, domains, canvas.width, canvas.height);
    }
    
    // Initial draw
    resizeCanvas();
    
    // Redraw on window resize
    let resizeTimeout;
    window.addEventListener('resize', () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(resizeCanvas, 250);
    });
}

function drawEnhancedSecurityRadarChart(ctx, domains, width, height) {
    const centerX = width / 2;
    const centerY = height / 2;
    const radius = Math.min(width, height) / 2 - 80; // Increased padding for larger chart
    const angleStep = (2 * Math.PI) / domains.length;

    // Enhanced background with better styling
    ctx.strokeStyle = 'hsl(240, 3.7%, 25%)';
    ctx.lineWidth = 1;
    
    // Draw concentric circles with labels
    for (let i = 1; i <= 5; i++) {
        ctx.beginPath();
        ctx.arc(centerX, centerY, (radius * i) / 5, 0, 2 * Math.PI);
        ctx.stroke();
        
        // Add percentage labels on circles
        ctx.fillStyle = 'hsl(240, 5%, 64.9%)';
        ctx.font = 'bold 14px Geist';
        ctx.textAlign = 'center';
        const percentage = (i * 20) + '%';
        ctx.fillText(percentage, centerX, centerY - (radius * i) / 5 - 8);
    }

    // Draw radial lines
    ctx.strokeStyle = 'hsl(240, 3.7%, 25%)';
    ctx.lineWidth = 1;
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

    // Draw the data area with gradient
    const gradient = ctx.createRadialGradient(centerX, centerY, 0, centerX, centerY, radius);
    gradient.addColorStop(0, 'hsl(263, 70%, 50%, 0.3)');
    gradient.addColorStop(1, 'hsl(263, 70%, 50%, 0.1)');
    
    ctx.fillStyle = gradient;
    ctx.strokeStyle = 'hsl(263, 70%, 50%)';
    ctx.lineWidth = 4;
    ctx.beginPath();

    // Plot the actual data
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

    // Draw target line (100%) with animation effect
    ctx.strokeStyle = 'hsl(142, 71%, 45%)';
    ctx.lineWidth = 3;
    ctx.setLineDash([8, 8]);
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

    // Draw enhanced data points and labels
    domains.forEach((domain, index) => {
        const angle = index * angleStep - Math.PI / 2;
        const scoreRadius = (radius * domain.score) / 100;
        const labelRadius = radius + 50;
        
        // Enhanced data point with glow effect
        const x = centerX + Math.cos(angle) * scoreRadius;
        const y = centerY + Math.sin(angle) * scoreRadius;
        
        // Glow effect
        ctx.shadowColor = domain.color;
        ctx.shadowBlur = 15;
        ctx.fillStyle = domain.color;
        ctx.beginPath();
        ctx.arc(x, y, 6, 0, 2 * Math.PI);
        ctx.fill();
        
        // Inner white dot
        ctx.shadowBlur = 0;
        ctx.fillStyle = 'white';
        ctx.beginPath();
        ctx.arc(x, y, 3, 0, 2 * Math.PI);
        ctx.fill();
        
        // Enhanced labels with background
        const labelX = centerX + Math.cos(angle) * labelRadius;
        const labelY = centerY + Math.sin(angle) * labelRadius;
        
        // Label background
        ctx.fillStyle = 'hsl(var(--card))';
        ctx.strokeStyle = domain.color;
        ctx.lineWidth = 2;
        const textWidth = ctx.measureText(domain.name).width + 20;
        const textHeight = 40;
        
        ctx.fillRect(labelX - textWidth/2, labelY - textHeight/2, textWidth, textHeight);
        ctx.strokeRect(labelX - textWidth/2, labelY - textHeight/2, textWidth, textHeight);
        
        // Domain name
        ctx.fillStyle = 'hsl(0, 0%, 98%)';
        ctx.font = 'bold 14px Geist';
        ctx.textAlign = 'center';
        ctx.fillText(domain.name, labelX, labelY - 2);
        
        // Score with color
        ctx.font = 'bold 12px Geist';
        ctx.fillStyle = domain.color;
        ctx.fillText(domain.score + '%', labelX, labelY + 12);
    });
    
    // Reset shadow
    ctx.shadowBlur = 0;
    
    // Add center label
    ctx.fillStyle = 'hsl(var(--foreground))';
    ctx.font = 'bold 16px Geist';
    ctx.textAlign = 'center';
    ctx.fillText('Security', centerX, centerY - 5);
    ctx.fillText('Domains', centerX, centerY + 15);
}

// Enhanced M365SPAT Features
function getScoreColor(score) {
    if (score >= 90) return 'hsl(142, 71%, 45%)'; // success
    if (score >= 75) return 'hsl(38, 92%, 50%)'; // warning  
    if (score >= 60) return 'hsl(38, 92%, 50%)'; // warning
    if (score >= 40) return 'hsl(0, 72%, 51%)'; // error
    return 'hsl(0, 72%, 51%)'; // error
}

// M365SPAT Utility Functions
function showNotification(message, type = 'info', duration = 3000) {
    const notification = document.createElement('div');
    notification.className = `m365spat-notification notification-${type}`;
    
    const icon = getNotificationIcon(type);
    
    notification.innerHTML = `
        <span class="notification-icon">${icon}</span>
        <span class="notification-message">${message}</span>
        <button class="notification-close" onclick="this.parentElement.remove()"><i class="fas fa-times"></i></button>
    `;
    
    // M365SPAT notification styling
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${getNotificationColor(type)};
        color: white;
        padding: 15px 20px;
        border-radius: 8px;
        box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        z-index: 1000;
        transform: translateX(100%);
        transition: transform 0.3s ease;
        max-width: 400px;
        display: flex;
        align-items: center;
        gap: 10px;
        font-size: 0.9rem;
        font-family: 'Geist', sans-serif;
        backdrop-filter: blur(10px);
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
}

function getNotificationIcon(type) {
    switch (type) {
        case 'success': return '<i class="fas fa-check-circle"></i>';
        case 'error': return '<i class="fas fa-exclamation-circle"></i>';
        case 'warning': return '<i class="fas fa-exclamation-triangle"></i>';
        case 'info': return '<i class="fas fa-info-circle"></i>';
        default: return '<i class="fas fa-info-circle"></i>';
    }
}

function getNotificationColor(type) {
    switch (type) {
        case 'success': return 'hsl(142, 71%, 45%)';
        case 'error': return 'hsl(0, 72%, 51%)';
        case 'warning': return 'hsl(38, 92%, 50%)';
        case 'info': return 'hsl(199, 89%, 48%)';
        default: return 'hsl(240, 5%, 64.9%)';
    }
}

// M365SPAT Export Functions
function exportM365SPATData() {
    const data = {
        tool: 'M365SPAT',
        version: '6.0',
        exportDate: new Date().toISOString(),
        tenantId: document.querySelector('.meta-item span:contains("Tenant:")'),
        controls: []
    };
    
    document.querySelectorAll('.control-card').forEach(card => {
        const title = card.querySelector('.control-title')?.textContent;
        const id = card.querySelector('.control-id')?.textContent;
        const status = card.querySelector('.badge-success, .badge-error, .badge-warning')?.textContent;
        
        if (title && id && status) {
            data.controls.push({
                id: id,
                title: title,
                status: status
            });
        }
    });
    
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `M365SPAT-Export-${new Date().toISOString().split('T')[0]}.json`;
    link.style.display = 'none';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
    
    showNotification('M365SPAT data exported successfully!', 'success');
}

// M365SPAT Keyboard Shortcuts
document.addEventListener('keydown', function(e) {
    // Ctrl/Cmd + E for expand all
    if ((e.ctrlKey || e.metaKey) && e.key === 'e') {
        e.preventDefault();
        expandAllControls();
        showNotification('Expanded all controls', 'info', 2000);
    }
    
    // Ctrl/Cmd + H for hide all
    if ((e.ctrlKey || e.metaKey) && e.key === 'h') {
        e.preventDefault();
        collapseAllControls();
        showNotification('Collapsed all controls', 'info', 2000);
    }
    
    // Ctrl/Cmd + T for theme toggle
    if ((e.ctrlKey || e.metaKey) && e.key === 't') {
        e.preventDefault();
        toggleTheme();
    }
    
    // Escape to collapse all
    if (e.key === 'Escape') {
        collapseAllControls();
    }
});

// M365SPAT Performance Monitoring
const M365SPAT = {
    version: '6.0',
    initialized: false,
    
    init: function() {
        if (this.initialized) return;
        
        console.log(`%c🛡️ M365SPAT Dashboard v${this.version} Initialized`, 
                   'color: #8b5cf6; font-weight: bold; font-size: 14px;');
        
        this.initialized = true;
        this.trackPerformance();
    },
    
    trackPerformance: function() {
        window.addEventListener('load', () => {
            const loadTime = performance.now();
            console.log(`M365SPAT Dashboard loaded in ${Math.round(loadTime)}ms`);
        });
    }
};

// Initialize M365SPAT tracking
M365SPAT.init();