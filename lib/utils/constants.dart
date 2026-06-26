// ══════════════════════════════════════════════════════════════════
// 🗂️ LIFELY APP CONSTANTS
// ══════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────
// 🖥️ FLASK BACKEND SERVER CONFIGURATION
// ─────────────────────────────────────────────────────────────────
// Instructions for Setup:
// 1. Find your PC's local WiFi IP using: ipconfig (command prompt)
//    Look for "IPv4 Address" in Wireless LAN adapter section
//    Example: 192.168.1.100
// 
// 2. Update SERVER_IP below with your actual PC WiFi IP
//
// 3. For Android Emulator (not physical device):
//    Use "10.0.2.2" instead of your PC's IP
//
// 4. Make sure:
//    - Flask server is running: python app.py
//    - Both your PC and device are on the same WiFi network
//    - Windows firewall allows port 5000 (see setup guide)
// ─────────────────────────────────────────────────────────────────

class ServerConfig {
  // Production Backend URL
  static const String baseUrl = 'https://lifely-backend.onrender.com';

  // 🧠 Flask AI Service Endpoints
  static const String cbcScanEndpoint = '$baseUrl/scan/cbc';
  static const String lftScanEndpoint = '$baseUrl/scan/lft';
  static const String diabetesScanEndpoint = '$baseUrl/scan/diabetes';
  static const String analyzeEndpoint = '$baseUrl/analyze';
  
  // 🔐 Debug Logging
  static const bool enableNetworkLogging = true;
  static const int networkTimeoutSeconds = 30;
}

// ─────────────────────────────────────────────────────────────────
// 📋 APP VERSION & METADATA
// ─────────────────────────────────────────────────────────────────
class AppMetadata {
  static const String appName = 'Lifely Healthcare';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';
}

// ─────────────────────────────────────────────────────────────────
// 🎨 UI CONSTANTS (Reusable values for theming & layout)
// ─────────────────────────────────────────────────────────────────
class UIConstants {
  // Color palette (same as in main.dart theme)
  static const int primaryBlue = 0xFF1565C0;
  static const int successGreen = 0xFF2E7D32;
  static const int backgroundLight = 0xFFF0F4FF;
  
  // Spacing/Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Border radius
  static const double borderRadius = 12.0;
}

// ─────────────────────────────────────────────────────────────────
// 📱 PANEL TYPES (Medical Report Categories)
// ─────────────────────────────────────────────────────────────────
class MedicalPanelTypes {
  static const String cbc = 'cbc';           // Complete Blood Count
  static const String lft = 'lft';           // Liver Function Tests
  static const String diabetes = 'diabetes'; // Metabolic/Diabetes Panel
}
