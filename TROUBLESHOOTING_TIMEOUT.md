# 🔴 TIMEOUT ERROR - Troubleshooting Guide

## The Problem
```
🧠 [AiService] ❌ Timeout Error: TimeoutException after 0:00:30.000000
```

**What this means:** The Android app is trying to connect to the Flask server but **not getting a response within 30 seconds**.

---

## 🔍 Diagnostic Checklist

Follow these steps IN ORDER to identify the issue:

### Step 1: Verify Flask Server is Running ⚠️ CRITICAL
```
Check YOUR FLASK TERMINAL WINDOW:
```

**You should see:**
```
* Running on http://0.0.0.0:5000
* Debug mode: on
```

**If you DON'T see this:**
- ❌ Flask server is NOT running
- ✅ **ACTION:** Start it:
  ```bash
  cd C:\Users\DELL\Desktop\lifely_backend
  python app.py
  ```
- **IMPORTANT:** Keep the terminal OPEN (never close it)

---

### Step 2: Verify IP Address is Correct

**Check what IP you're using in the app:**
1. Open: `lib/utils/constants.dart`
2. Look at: `static const String serverIp = '10.43.110.145';`

**The IP MUST match your actual PC WiFi IP:**

Get your actual IP:
```powershell
# Open Command Prompt and run:
ipconfig

# Look for: "IPv4 Address" under "Wireless LAN adapter WiFi"
# Example output:
# IPv4 Address . . . : 192.168.1.100
```

**If they DON'T match:**
- ❌ You're using the wrong IP
- ✅ **ACTION:** Update `lib/utils/constants.dart` with your actual IP
- **Then:** Rebuild the app: `flutter clean && flutter pub get`

---

### Step 3: Verify Both Devices on Same WiFi

**On your Android device:**
- Go to: **Settings → WiFi**
- Check the network name (SSID)

**On your Windows PC:**
- Bottom right tray → WiFi icon
- Check the network name (SSID)

**If they're DIFFERENT networks:**
- ❌ Device and PC not on same WiFi
- ✅ **ACTION:** Connect Android device to the SAME WiFi network as your PC

---

### Step 4: Test Connectivity from Windows

**Before debugging Android, test from your PC:**

#### Test 1: Ping the Flask Server
```cmd
# Open Command Prompt
ping 10.43.110.145
```

**Expected output:**
```
Reply from 10.43.110.145: bytes=32 time=10ms TTL=64
```

**If you get:**
```
Request timed out
Destination host unreachable
```

❌ **PC cannot reach Flask server**
- Check Flask is running
- Check IP is correct
- Check Windows Firewall

---

#### Test 2: Test with curl
```cmd
# Open Command Prompt
curl http://10.43.110.145:5000/
```

**Expected output:**
```
<!DOCTYPE html>...
```
OR any response from Flask

**If you get:**
```
curl: (7) Failed to connect
curl: (28) Timeout was reached
```

❌ **Network offline or Flask not reachable**

---

#### Test 3: Test with Browser
```
Open browser → Navigate to: http://10.43.110.145:5000/
```

**Expected:**
- Flask welcome page appears
- OR error response from Flask

**If browser hangs/times out:**
❌ **Server not reachable**

---

### Step 5: Check Windows Firewall

If Tests 1-3 fail:

#### Quick Test (TEMPORARY - Re-enable after!)
```powershell
# Run PowerShell as Administrator:

# DISABLE firewall (testing only)
netsh advfirewall set allprofiles state off

# Then test: curl http://10.43.110.145:5000/

# RE-ENABLE firewall (DON'T forget!)
netsh advfirewall set allprofiles state on
```

If curl works when firewall is OFF:
❌ **Firewall is blocking port 5000**

#### Proper Fix: Add Firewall Rule
```powershell
# Run PowerShell as Administrator:
New-NetFirewallRule -DisplayName "Flask Dev Port 5000" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

Verify rule was added:
```powershell
netsh advfirewall firewall show rule name="Flask Dev Port 5000"
```

---

### Step 6: Check Flask Error Logs

Look at your **Flask terminal window** while the Android app tries to connect:

**If you see request logs:**
```
192.168.1.50 - - [01/Jun/2026 10:35:22] "POST /scan/cbc HTTP/1.1" 200 -
```
✅ **Flask received the request!** (Problem is Flask response processing)

**If you see NOTHING:**
❌ **Flask never received the request** (Network issue)

---

## 🔧 Common Causes & Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| **Timeout every time** | Flask not running | Start Flask: `python app.py` |
| **Timeout every time** | Wrong IP address | Update `constants.dart` with correct IP |
| **Timeout every time** | Different WiFi networks | Connect to same WiFi |
| **Timeout every time** | Firewall blocking | Add port 5000 inbound rule |
| **Timeout, then works** | Slow network/server | Increase timeout: `networkTimeoutSeconds = 60` |
| **Timeout on all requests** | Flask crashed | Restart Flask, check error logs |

---

## 🎯 Quick Fix Checklist

Copy/paste this checklist and go through it:

- [ ] **Flask Running Check:**
  ```powershell
  # In PowerShell, run:
  netstat -ano | findstr :5000
  # Should show LISTENING
  ```

- [ ] **IP Address Correct:**
  ```powershell
  ipconfig
  # Note WiFi IPv4 Address
  # Compare with constants.dart line 27
  ```

- [ ] **WiFi Connected:**
  - [ ] PC: Connected to WiFi (check Settings)
  - [ ] Android: Connected to same WiFi (check WiFi name)

- [ ] **Firewall Rule Added:**
  ```powershell
  netsh advfirewall firewall show rule name="Flask Dev Port 5000"
  ```

- [ ] **Test from PC:**
  ```powershell
  curl http://10.43.110.145:5000/
  ```

- [ ] **Flask Terminal Logs:**
  - [ ] Flask running shows: `* Running on http://0.0.0.0:5000`
  - [ ] When app tries request, new log appears

---

## 🚀 After Fixing

1. **Restart Flask server** (close and reopen terminal)
2. **Rebuild Flutter app:**
   ```bash
   cd "C:\Users\DELL\Desktop\Apps\Lifely App\lifely_app"
   flutter clean
   flutter pub get
   flutter run
   ```
3. **Try the scan again in app**
4. **Watch Logcat for new logs:**
   ```
   🧠 [AiService] 📤 Sending cbc scan to: ...
   🧠 [AiService] 📥 Response Status: 200
   ```

---

## 📞 Still Having Issues?

Provide this info:

1. **Flask terminal output** (paste the entire terminal window)
2. **Result of:** `curl http://10.43.110.145:5000/`
3. **Result of:** `ipconfig` (your WiFi IPv4)
4. **`constants.dart` serverIp value** (line 27)
5. **Connected WiFi name** (both PC and Android)

---

## 🔗 Related Documentation

- `ANDROID_WIFI_SETUP.md` - Full setup guide
- `QUICK_REFERENCE.md` - Quick commands
- `SETUP_CHECKLIST.md` - Interactive checklist

**Last Updated:** June 1, 2026

