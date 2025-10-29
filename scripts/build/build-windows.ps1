# Windows PowerShell Build Script for Android APK
# Run this in PowerShell on Windows where Qt is installed

param(
    [string]$QtVersion = "6.10.0",
    [string]$BuildType = "Debug"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "║          📱 ANDROID APK BUILD (Windows) 📱                ║" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Get project root (assuming WSL path /home/hungkv/projects/file_transfer_ovimage)
$WslPath = "/home/hungkv/projects/file_transfer_ovimage"
$WindowsPath = wsl wslpath -w $WslPath

Write-Host "[BUILD] Project path: $WindowsPath" -ForegroundColor Blue

# Find Qt installation
$QtPaths = @(
    "C:\Qt\$QtVersion\android_arm64_v8a",
    "$env:USERPROFILE\Qt\$QtVersion\android_arm64_v8a"
)

$QtPath = $null
foreach ($path in $QtPaths) {
    if (Test-Path $path) {
        $QtPath = $path
        Write-Host "[BUILD] Found Qt: $QtPath" -ForegroundColor Green
        break
    }
}

if (-not $QtPath) {
    Write-Host "[ERROR] Qt $QtVersion not found" -ForegroundColor Red
    exit 1
}

# Build directory
$BuildDir = "$WindowsPath\build\Android_Qt_${QtVersion}_Clang_arm64_v8a-${BuildType}"

Write-Host "[BUILD] Build directory: $BuildDir" -ForegroundColor Blue

if (Test-Path $BuildDir) {
    Write-Host "[BUILD] Rebuilding in existing directory..." -ForegroundColor Yellow
    
    # Use Qt Creator's cmake
    $CMake = "$QtPath\bin\cmake.exe"
    if (-not (Test-Path $CMake)) {
        # Try Qt's host tools
        $CMake = "C:\Qt\$QtVersion\msvc2019_64\bin\cmake.exe"
    }
    
    if (Test-Path $CMake) {
        Set-Location $BuildDir
        Write-Host "[BUILD] Running cmake build..." -ForegroundColor Blue
        & $CMake --build . --parallel
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[BUILD] Build successful!" -ForegroundColor Green
            
            # Find APK
            $Apk = Get-ChildItem -Path $BuildDir -Recurse -Filter "*-debug.apk" | Select-Object -First 1
            
            if ($Apk) {
                Write-Host "[BUILD] APK found: $($Apk.FullName)" -ForegroundColor Green
                Write-Host "[BUILD] APK size: $([math]::Round($Apk.Length/1MB, 2)) MB" -ForegroundColor Blue
                
                # Copy to project root
                Copy-Item $Apk.FullName -Destination "$WindowsPath\app-debug.apk" -Force
                Write-Host "[BUILD] APK copied to project root" -ForegroundColor Green
                
                Write-Host ""
                Write-Host "✅ Build completed successfully!" -ForegroundColor Green
                Write-Host ""
                Write-Host "To install on device, run in WSL:" -ForegroundColor Yellow
                Write-Host "  adb install -r app-debug.apk" -ForegroundColor Cyan
                Write-Host ""
            } else {
                Write-Host "[ERROR] APK not found" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "[ERROR] Build failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "[ERROR] CMake not found" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[ERROR] Build directory not found. Please build once in Qt Creator first." -ForegroundColor Red
    exit 1
}
