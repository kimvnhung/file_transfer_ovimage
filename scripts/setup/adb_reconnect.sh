#!/bin/bash
# Quick reconnect script - uses saved IP address

SAVED_IP_FILE="$HOME/.last_android_ip"

if [ -f "$SAVED_IP_FILE" ]; then
    DEVICE_IP=$(cat "$SAVED_IP_FILE")
    echo "🔌 Connecting to saved device: $DEVICE_IP:5555"
    adb connect $DEVICE_IP:5555
    sleep 1
    adb devices
else
    echo "❌ No saved IP address found"
    echo "Run ./connect_android_wifi.sh first"
    exit 1
fi
