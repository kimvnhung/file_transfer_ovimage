#!/bin/bash
# Quick setup for Android device over WiFi in WSL2

echo "=========================================="
echo "Android ADB WiFi Connection Helper"
echo "=========================================="
echo ""

# Check if adb is installed
if ! command -v adb &> /dev/null; then
    echo "❌ ADB is not installed!"
    echo "Installing ADB..."
    sudo apt update
    sudo apt install -y adb
fi

echo "📱 STEP 1: Enable ADB over TCP on your Android device"
echo "----------------------------------------------"
echo "You have two options:"
echo ""
echo "Option A: Using Windows ADB (if device is connected to Windows)"
echo "  1. Open PowerShell/Command Prompt on Windows"
echo "  2. Run: cd C:\\Users\\YourUsername\\AppData\\Local\\Android\\Sdk\\platform-tools"
echo "  3. Run: adb.exe devices (verify device is connected)"
echo "  4. Run: adb.exe tcpip 5555"
echo "  5. Disconnect USB cable"
echo ""
echo "Option B: Using Android App (no Windows needed)"
echo "  1. Install 'Wireless ADB' or similar app from Play Store"
echo "  2. Enable ADB over WiFi in the app"
echo "  3. Note the IP address shown"
echo ""
read -p "Press Enter when you've completed Step 1..."

echo ""
echo "📡 STEP 2: Find your Android device IP address"
echo "----------------------------------------------"
echo "On Android device:"
echo "  Settings → About Phone → Status → IP Address"
echo "  OR"
echo "  Settings → WiFi → [Your Network] → IP Address"
echo ""
read -p "Enter your Android device IP address: " DEVICE_IP

if [ -z "$DEVICE_IP" ]; then
    echo "❌ Error: No IP address provided"
    exit 1
fi

# Validate IP format (basic check)
if ! [[ $DEVICE_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "⚠️  Warning: '$DEVICE_IP' doesn't look like a valid IP address"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "🔌 STEP 3: Connecting to $DEVICE_IP:5555..."
echo "----------------------------------------------"

# Kill any existing adb server
adb kill-server
sleep 1

# Start fresh
adb start-server
sleep 1

# Connect to device
adb connect $DEVICE_IP:5555

echo ""
echo "🔍 Checking connection status..."
echo "----------------------------------------------"
sleep 2
adb devices -l

echo ""
echo "=========================================="

# Check if device is connected
DEVICE_COUNT=$(adb devices | grep -c "device$")

if [ $DEVICE_COUNT -gt 0 ]; then
    echo "✅ SUCCESS! Device connected via WiFi"
    echo ""
    echo "Device info:"
    adb shell getprop ro.product.model
    echo "Android version: $(adb shell getprop ro.build.version.release)"
    echo ""
    echo "✨ You can now use Qt Creator to deploy apps!"
    echo ""
    echo "💡 Tips:"
    echo "  - Keep device and PC on same WiFi network"
    echo "  - Connection persists until device reboots"
    echo "  - To disconnect: adb disconnect $DEVICE_IP:5555"
    echo ""
    echo "🔧 To reconnect later, just run:"
    echo "  adb connect $DEVICE_IP:5555"
    echo ""
    
    # Save IP for future use
    echo "$DEVICE_IP" > ~/.last_android_ip
    echo "📝 IP address saved to ~/.last_android_ip"
else
    echo "❌ FAILED to connect to device"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify device and PC are on same WiFi"
    echo "  2. Check if 'adb tcpip 5555' was run successfully"
    echo "  3. Try pinging the device: ping -c 3 $DEVICE_IP"
    echo "  4. Check Android USB debugging is enabled"
    echo "  5. Some networks block ADB - try mobile hotspot"
    echo ""
    echo "Alternative: Use usbipd-win (see WSL_ANDROID_DEVICE_SETUP.md)"
fi

echo "=========================================="
