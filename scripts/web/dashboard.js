// Test Results Dashboard JavaScript

let testData = null;
let currentFilter = 'all';
let refreshInterval = null;
let countdown = 30;

// Initialize dashboard
document.addEventListener('DOMContentLoaded', () => {
    loadTestData();
    setupEventListeners();
    startAutoRefresh();
});

// Load test data from JSON
async function loadTestData() {
    try {
        const response = await fetch('test-data.json?t=' + Date.now());
        testData = await response.json();
        
        updateStats();
        renderBuilds();
        updateGeneratedTime();
    } catch (error) {
        console.error('Failed to load test data:', error);
        document.getElementById('builds-container').innerHTML = 
            '<div class="error">Failed to load test data. Make sure the server is running.</div>';
    }
}

// Update statistics
function updateStats() {
    if (!testData || !testData.builds) return;
    
    const total = testData.builds.length;
    const passed = testData.builds.filter(b => b.status === 'success').length;
    const failed = total - passed;
    const successRate = total > 0 ? Math.round((passed / total) * 100) : 0;
    
    document.getElementById('total-builds').textContent = total;
    document.getElementById('passed-builds').textContent = passed;
    document.getElementById('failed-builds').textContent = failed;
    document.getElementById('success-rate').textContent = successRate + '%';
}

// Render build cards
function renderBuilds() {
    if (!testData || !testData.builds) return;
    
    const container = document.getElementById('builds-container');
    const searchTerm = document.getElementById('search').value.toLowerCase();
    
    let filteredBuilds = testData.builds.filter(build => {
        // Apply type filter
        if (currentFilter === 'runtime' && build.type !== 'runtime') return false;
        if (currentFilter === 'build' && build.type !== 'build') return false;
        if (currentFilter === 'success' && build.status !== 'success') return false;
        if (currentFilter === 'failed' && build.status !== 'failed') return false;
        
        // Apply search filter
        if (searchTerm) {
            const searchableText = `
                ${build.buildId} 
                ${build.version} 
                ${build.date} 
                ${build.type}
                ${JSON.stringify(build.errors)}
            `.toLowerCase();
            
            if (!searchableText.includes(searchTerm)) return false;
        }
        
        return true;
    });
    
    if (filteredBuilds.length === 0) {
        container.innerHTML = '<div class="empty">No test results found matching your criteria.</div>';
        return;
    }
    
    container.innerHTML = filteredBuilds.map(build => createBuildCard(build)).join('');
}

// Create build card HTML
function createBuildCard(build) {
    const statusClass = build.status === 'success' ? 'success' : 'failed';
    const statusIcon = build.status === 'success' ? '✅' : '❌';
    const typeIcon = build.type === 'runtime' ? '📱' : '🔨';
    
    let errorsHtml = '';
    if (build.errors && build.errors.total > 0) {
        const errorBreakdown = [];
        if (build.errors.qml) errorBreakdown.push(`QML: ${build.errors.qml}`);
        if (build.errors.qt) errorBreakdown.push(`Qt: ${build.errors.qt}`);
        if (build.errors.fatal) errorBreakdown.push(`Fatal: ${build.errors.fatal}`);
        if (build.errors.compile) errorBreakdown.push(`Compile: ${build.errors.compile}`);
        if (build.errors.cmake) errorBreakdown.push(`CMake: ${build.errors.cmake}`);
        
        errorsHtml = `
            <div class="error-summary">
                <strong>Errors:</strong> ${errorBreakdown.join(', ')}
            </div>
        `;
    }
    
    let screenshotHtml = '';
    if (build.screenshot) {
        screenshotHtml = `
            <div class="screenshot-preview">
                <img src="../${build.screenshot}" alt="Screenshot" 
                     onclick="showScreenshot('../${build.screenshot}', '${build.version}')">
                <span class="screenshot-label">📸 View Screenshot</span>
            </div>
        `;
    }
    
    return `
        <div class="build-card ${statusClass}">
            <div class="build-header">
                <div class="build-title">
                    <span class="type-icon">${typeIcon}</span>
                    <h3>${build.version}</h3>
                    <span class="status-badge ${statusClass}">${statusIcon} ${build.status.toUpperCase()}</span>
                </div>
                <div class="build-meta">
                    <span class="build-id">#${build.buildId}</span>
                    <span class="build-date">🕒 ${build.date}</span>
                </div>
            </div>
            
            ${errorsHtml}
            ${screenshotHtml}
            
            <div class="build-actions">
                ${build.logs.logcat ? `<button onclick="viewLog('${build.logs.logcat}', 'Logcat')">📋 View Logcat</button>` : ''}
                ${build.logs.build ? `<button onclick="viewLog('${build.logs.build}', 'Build Log')">📋 View Build Log</button>` : ''}
                ${build.logs.fixes ? `<button onclick="showFixes('${build.buildId}')">🔧 View Fixes</button>` : ''}
            </div>
        </div>
    `;
}

// View log in modal
async function viewLog(logPath, title) {
    try {
        const response = await fetch('../' + logPath);
        const logContent = await response.text();
        
        const highlighted = highlightLog(logContent);
        
        showModal(`
            <h2>📄 ${title}</h2>
            <div class="log-viewer">
                <pre>${highlighted}</pre>
            </div>
        `);
    } catch (error) {
        showModal(`
            <h2>❌ Error</h2>
            <p>Failed to load log file: ${logPath}</p>
        `);
    }
}

// Highlight log content
function highlightLog(content) {
    return content
        .replace(/error:/gi, '<span class="log-error">error:</span>')
        .replace(/warning:/gi, '<span class="log-warning">warning:</span>')
        .replace(/\[SUCCESS\]/g, '<span class="log-success">[SUCCESS]</span>')
        .replace(/\[ERROR\]/g, '<span class="log-error">[ERROR]</span>')
        .replace(/\[WARNING\]/g, '<span class="log-warning">[WARNING]</span>')
        .replace(/FATAL/g, '<span class="log-error">FATAL</span>');
}

// Show fixes
function showFixes(buildId) {
    const build = testData.builds.find(b => b.buildId === buildId);
    if (!build || !build.logs.fixes) {
        showModal('<h2>No Fixes Applied</h2><p>No automatic fixes were applied for this build.</p>');
        return;
    }
    
    showModal(`
        <h2>🔧 Applied Fixes</h2>
        <div class="log-viewer">
            <pre>${build.logs.fixes}</pre>
        </div>
    `);
}

// Show screenshot in modal
function showScreenshot(path, title) {
    showModal(`
        <h2>📸 ${title}</h2>
        <div class="screenshot-full">
            <img src="${path}" alt="${title}">
        </div>
    `);
}

// Show modal
function showModal(content) {
    const modal = document.getElementById('modal');
    const modalBody = document.getElementById('modal-body');
    
    modalBody.innerHTML = content;
    modal.style.display = 'block';
}

// Setup event listeners
function setupEventListeners() {
    // Filter buttons
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
            currentFilter = e.target.dataset.filter;
            renderBuilds();
        });
    });
    
    // Search
    document.getElementById('search').addEventListener('input', () => {
        renderBuilds();
    });
    
    // Refresh button
    document.getElementById('refresh-btn').addEventListener('click', () => {
        manualRefresh();
    });
    
    // Modal close
    document.querySelector('.close').addEventListener('click', () => {
        document.getElementById('modal').style.display = 'none';
    });
    
    window.addEventListener('click', (e) => {
        const modal = document.getElementById('modal');
        if (e.target === modal) {
            modal.style.display = 'none';
        }
    });
}

// Update generated time
function updateGeneratedTime() {
    if (testData && testData.generated) {
        document.getElementById('generated-time').textContent = 
            new Date(testData.generated).toLocaleString();
    }
}

// Auto-refresh functionality
function startAutoRefresh() {
    updateCountdown();
    
    refreshInterval = setInterval(() => {
        countdown--;
        updateCountdown();
        
        if (countdown <= 0) {
            countdown = 30;
            loadTestData();
        }
    }, 1000);
}

function updateCountdown() {
    document.getElementById('refresh-countdown').textContent = countdown;
}

// Manual refresh
function manualRefresh() {
    const btn = document.getElementById('refresh-btn');
    btn.classList.add('refreshing');
    btn.textContent = '🔄 Refreshing...';
    
    countdown = 30; // Reset countdown
    loadTestData().then(() => {
        btn.classList.remove('refreshing');
        btn.textContent = '🔄 Refresh';
        
        // Show success feedback
        btn.classList.add('success');
        setTimeout(() => {
            btn.classList.remove('success');
        }, 1000);
    });
}

// Expose functions to global scope
window.viewLog = viewLog;
window.showFixes = showFixes;
window.showScreenshot = showScreenshot;
