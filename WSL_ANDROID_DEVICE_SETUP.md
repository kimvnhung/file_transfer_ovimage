# Android Device Setup for WSL2 Ubuntu

WSL2 cannot directly access USB devices. You need to forward USB from Windows to WSL2 using `usbipd-win`.

## Method 1: Using usbipd-win (Recommended)

### Step 1: Install usbipd-win on Windows

1. Open **PowerShell as Administrator** on Windows
2. Install usbipd-win:
   ```powershell
   winget install --interactive --exact dorssel.usbipd-win
   ```
   
   Or download from: https://github.com/dorssel/usbipd-win/releases

3. Restart your computer after installation

### Step 2: Install USBIP tools in WSL2 Ubuntu

Run these commands in your WSL2 Ubuntu terminal:

```bash
sudo apt update
sudo apt install -y linux-tools-generic hwdata
sudo update-alternatives --install /usr/local/bin/usbip usbip /usr/lib/linux-tools/*-generic/usbip 20
```

### Step 3: Connect Android Device

1. **On Windows PowerShell (as Administrator):**

   List USB devices:
   ```powershell
   usbipd list
   ```
   
   You should see your Android device (look for your phone manufacturer name).
   
   Note the **BUS ID** (e.g., `2-3`)

2. **Bind the device** (first time only):
   ```powershell
   usbipd bind --busid 2-3
   ```
   Replace `2-3` with your actual BUS ID.

3. **Attach the device to WSL:**
   ```powershell
   usbipd attach --wsl --busid 2-3
   ```

### Step 4: Verify in WSL2

In your WSL2 Ubuntu terminal:

```bash
# Check if device is connected
lsusb

# Check ADB devices
adb devices
```

You should see your Android device listed!

### Step 5: Detach When Done

**On Windows PowerShell (as Administrator):**
```powershell
usbipd detach --busid 2-3
```

## Method 2: Use ADB over WiFi (Easier Alternative)

This method doesn't require USB forwarding!

### Step 1: Enable ADB over TCP on Device

**Connect device via USB to Windows first:**

1. Open **Command Prompt** or **PowerShell** on Windows
2. Navigate to Android SDK platform-tools:
   ```cmd
   cd C:\Users\YourUsername\AppData\Local\Android\Sdk\platform-tools
   ```
   
3. Enable ADB over TCP:
   ```cmd
   adb tcpip 5555
   ```

4. Find your phone's IP address:
   - Android: Settings → About Phone → Status → IP Address
   - Or run: `adb shell ip addr show wlan0`

5. Disconnect USB cable

### Step 2: Connect from WSL2

In WSL2 Ubuntu terminal:

```bash
# Connect to device over WiFi (replace with your phone's IP)
adb connect 192.168.1.100:5555

# Verify connection
adb devices
```

You should see:
```
192.168.1.100:5555    device
```

### Step 3: Deploy from Qt Creator

Now Qt Creator in WSL2 can detect the device via ADB over WiFi!

**Important:** Keep your device and computer on the same WiFi network.

### To Disconnect:
```bash
adb disconnect 192.168.1.100:5555
```

## Method 3: Use ADB from Windows + Qt Creator Remote Build

### Option A: Build in WSL, Deploy from Windows

1. Build APK in WSL:
   ```bash
   cd /home/hungkv/projects/file_transfer_ovimage
   # Build using Qt Creator or command line
   ```

2. Copy APK to Windows:
   ```bash
   cp build/Android_Qt_6_10_0_Clang_arm64_v8a-Debug/android-build/*.apk /mnt/c/Users/YourUsername/Desktop/
   ```

3. Install from Windows:
   ```cmd
   cd C:\Users\YourUsername\Desktop
   adb install -r app.apk
   ```

## Quick Setup Script for ADB over WiFi

Create this script to automate WiFi connection:

```bash
#!/bin/bash
# save as: connect_android_wifi.sh

echo "Android ADB over WiFi Connection"
echo "================================"
echo ""
echo "Make sure you've run 'adb tcpip 5555' on Windows first!"
echo ""
read -p "Enter your Android device IP address: " DEVICE_IP

if [ -z "$DEVICE_IP" ]; then
    echo "Error: No IP address provided"
    exit 1
fi

echo "Connecting to $DEVICE_IP:5555..."
adb connect $DEVICE_IP:5555

echo ""
echo "Checking connection..."
adb devices

echo ""
echo "If you see your device listed above, you're ready!"
echo "To disconnect later, run: adb disconnect $DEVICE_IP:5555"
```

Make it executable:
```bash
chmod +x connect_android_wifi.sh
```

## Troubleshooting

### Issue: "no permissions" in adb devices

**Solution:**
```bash
# Create/edit udev rules
sudo nano /etc/udev/rules.d/51-android.rules

# Add this line:
SUBSYSTEM=="usb", ATTR{idVendor}=="[YOUR_VENDOR_ID]", MODE="0666", GROUP="plugdev"

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Restart adb
adb kill-server
adb start-server
```

Common vendor IDs:
- Samsung: `04e8`
- Google: `18d1`
- Xiaomi: `2717`
- Huawei: `12d1`
- OnePlus: `2a70`

Find your vendor ID with `lsusb` after connecting the device.

### Issue: "device offline" after connecting

**Solution:**
```bash
adb kill-server
adb start-server
adb devices
```

Check if USB debugging authorization popup appears on your phone.

### Issue: usbipd attach fails

**Solution:**
1. Make sure WSL2 is running: `wsl --list --running`
2. Check Windows Firewall isn't blocking
3. Try running PowerShell as Administrator
4. Update WSL: `wsl --update`

### Issue: ADB over WiFi disconnects frequently

**Solution:**
1. Disable WiFi power saving on Android
2. Keep device plugged into charger
3. Add static IP for device in router settings

## Recommended Approach

**For development, I recommend Method 2 (ADB over WiFi)** because:
- ✅ No Windows admin privileges needed repeatedly
- ✅ No USB cable required
- ✅ Simpler setup
- ✅ Works reliably with Qt Creator in WSL2
- ❌ Slightly slower than USB (but acceptable for development)

**For production/frequent deployments, use Method 1 (usbipd-win)** because:
- ✅ Faster transfer speeds
- ✅ More stable connection
- ❌ Requires admin privileges on Windows
- ❌ More complex setup

## Qt Creator Configuration

Once ADB can see your device, Qt Creator will automatically detect it:

1. Open Qt Creator
2. Go to **Tools** → **Options** → **Devices** → **Android**
3. Check that ADB path is set: `/usr/bin/adb` or SDK path
4. Your device should appear in the device list

When you click **Run** (Ctrl+R), Qt Creator will show your connected device in the deployment dialog.

---

**Need help?** 
- Check ADB version: `adb --version`
- Check devices: `adb devices -l` (verbose mode)
- ADB logs: `adb logcat`
