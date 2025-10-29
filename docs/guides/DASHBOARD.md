# Test Results Dashboard

## Overview

A web-based dashboard for visualizing test logs and build results from the self-healing CI/CD system. Provides a comprehensive view of all build and runtime tests with interactive log viewing, screenshot galleries, and error tracking.

## 🎯 Features

### Visual Test Results
- 📊 **Statistics Overview** - Total tests, pass/fail rate, success percentage
- 🔍 **Searchable Results** - Filter by test type, status, or search terms
- 📱 **Screenshot Gallery** - View device screenshots from runtime tests
- 📋 **Log Viewer** - View logcat, build logs, and fix logs in-browser
- 🔄 **Auto-Refresh** - Updates every 30 seconds with latest results

### Test Categories
- **Runtime Tests** - APK deployment, logcat analysis, error detection
- **Build Tests** - CMake configuration, compilation, self-healing fixes

### Interactive Features
- Click on test cards to view details
- View full logs in modal windows
- See applied fixes for each cycle
- Zoom into device screenshots
- Filter and search across all tests

## 🚀 Quick Start

### Start Dashboard Server

```bash
# From project root
./dashboard.sh

# Or directly
./scripts/test/dashboard-server.sh
```

The dashboard will:
1. Generate test data from logs
2. Start HTTP server on port 8080
3. Open browser automatically
4. Auto-refresh every 30 seconds

### Access Dashboard

Open your browser to:
```
http://localhost:8080/dashboard/
```

### Custom Port

```bash
DASHBOARD_PORT=9000 ./dashboard.sh
```

## 📂 Data Sources

The dashboard reads from:

### Runtime Test Logs
Location: `ci-reports/runtime-test/`

Files:
- `logcat-attempt-N.txt` - Captured logcat output
- `screenshot-attempt-N.png` - Device screenshots
- `screenshot-attempt-N-launched.png` - Launch screenshots
- `runtime-fix-TIMESTAMP.txt` - Applied fixes
- `crash-N.txt` - Crash logs

### Build Logs
Location: `ci-reports/self-heal/`

Files:
- `build-N.log` - Build output
- `cmake-N.log` - CMake configuration
- `fix-log-TIMESTAMP.txt` - Applied fixes

## 🎨 Dashboard Interface

### Main View

```
┌─────────────────────────────────────────────────┐
│         📊 Test Results Dashboard               │
├─────────────────────────────────────────────────┤
│  Total: 15  │ Passed: 12 │ Failed: 3 │ 80%     │
├─────────────────────────────────────────────────┤
│ [All] [Runtime] [Build] [Passed] [Failed]      │
│ [                Search...                   ]  │
├─────────────────────────────────────────────────┤
│ ┌────────────┐  ┌────────────┐  ┌────────────┐ │
│ │ 📱 Runtime │  │ 📱 Runtime │  │ 🔨 Build   │ │
│ │ Test #1    │  │ Test #2    │  │ Test #1    │ │
│ │ ✅ SUCCESS │  │ ❌ FAILED  │  │ ✅ SUCCESS │ │
│ │            │  │            │  │            │ │
│ │ [View Log] │  │ [View Log] │  │ [View Log] │ │
│ └────────────┘  └────────────┘  └────────────┘ │
└─────────────────────────────────────────────────┘
```

### Test Card Details

Each card shows:
- 📱/🔨 Test type icon (Runtime/Build)
- ✅/❌ Status badge
- Test version/cycle number
- Timestamp
- Error summary (if failed)
- Screenshot preview (if available)
- Action buttons (View Log, View Fixes)

### Log Viewer

Click "View Log" to see:
- Full log content
- Syntax highlighting for errors/warnings
- Scrollable view
- Copy-friendly format

### Screenshot Viewer

Click screenshot to:
- View full-size image
- See device state at test time
- Compare before/after fixes

## 📊 Statistics Cards

### Total Tests
- Count of all test runs
- Includes both build and runtime tests

### Passed
- Number of successful tests
- Green highlight

### Failed
- Number of failed tests
- Red highlight

### Success Rate
- Percentage of passing tests
- Calculated in real-time

## 🔍 Filtering & Search

### Filter Buttons
- **All Tests** - Show everything
- **Runtime Tests** - Only APK deployment tests
- **Build Tests** - Only compilation tests
- **Passed Only** - Filter successes
- **Failed Only** - Filter failures

### Search Box
Search across:
- Build IDs
- Version numbers
- Dates
- Error messages
- Log content

## 🔄 Auto-Refresh

Dashboard automatically:
- Refreshes every 30 seconds
- Shows countdown timer
- Loads latest test results
- Maintains current filter/search

Manual refresh: Press F5 or reload page

## 📁 File Structure

```
scripts/
├── web/
│   ├── index.html       # Dashboard HTML
│   ├── dashboard.js     # Frontend logic
│   └── styles.css       # Styling
├── test/
│   ├── dashboard-server.sh      # HTTP server
│   └── generate-test-data.sh    # JSON generator
dashboard.sh             # Wrapper script
```

## 🛠️ Technical Details

### Technology Stack
- **Backend**: Python HTTP server
- **Frontend**: Vanilla JavaScript (no frameworks)
- **Data Format**: JSON
- **Styling**: CSS3 with animations
- **Compatibility**: Modern browsers

### Data Flow

```
Test Logs → generate-test-data.sh → test-data.json → Dashboard UI
```

### JSON Structure

```json
{
  "generated": "2025-10-29T12:00:00Z",
  "project": "file_transfer_ovimage",
  "builds": [
    {
      "buildId": "runtime-1-attempt-1",
      "version": "Runtime Test Cycle 1",
      "date": "2025-10-29 12:00:00",
      "status": "success",
      "type": "runtime",
      "attempt": 1,
      "errors": {
        "qml": 0,
        "qt": 0,
        "fatal": 0,
        "total": 0
      },
      "logs": {
        "logcat": "runtime-test/logcat-attempt-1.txt"
      },
      "screenshot": "runtime-test/screenshot-attempt-1.png"
    }
  ]
}
```

## 💡 Usage Tips

### Development Workflow

1. Run tests:
   ```bash
   ./build.sh
   ./test.sh
   ```

2. Start dashboard:
   ```bash
   ./dashboard.sh
   ```

3. View results in browser
4. Dashboard auto-updates as tests run

### CI/CD Integration

Dashboard works with:
- Local builds
- GitHub Actions artifacts
- Docker builds
- Manual testing

### Troubleshooting

**Dashboard won't start:**
- Check Python is installed: `python3 --version`
- Check port is available: `lsof -i :8080`

**No data shown:**
- Run some tests first: `./test.sh`
- Check `ci-reports/` directory exists
- Verify logs are being generated

**Screenshots not loading:**
- Check file permissions
- Verify screenshot files exist
- Ensure relative paths are correct

**Auto-refresh not working:**
- Check browser console for errors
- Verify test-data.json is updating
- Try manual refresh (F5)

## 🎯 Use Cases

### Development
- Monitor test results during development
- Debug failing tests visually
- Track error patterns over time

### CI/CD
- Review build history
- Analyze failure trends
- Share test results with team

### Documentation
- Screenshot gallery of app states
- Error documentation
- Fix history tracking

## 🔮 Future Enhancements

Potential additions:
- [ ] Historical trend graphs
- [ ] Error pattern analysis
- [ ] Comparison between builds
- [ ] Export reports as PDF
- [ ] Email notifications
- [ ] GitHub integration
- [ ] Real-time websocket updates
- [ ] Custom dashboard themes

## 📞 Support

For issues with the dashboard:
1. Check logs in browser console (F12)
2. Verify Python server is running
3. Check file permissions in ci-reports/
4. Review generated test-data.json

---

**Quick Commands:**

```bash
# Start dashboard
./dashboard.sh

# Custom port
DASHBOARD_PORT=9000 ./dashboard.sh

# Generate test data only
./scripts/test/generate-test-data.sh

# View generated JSON
cat ci-reports/dashboard/test-data.json | jq
```

The dashboard provides a professional way to visualize and analyze your test results! 📊✨
