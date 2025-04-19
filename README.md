# MyQRCode

**MyQRCode** is a modern Flutter app that allows users to scan and generate QR codes. The app intelligently detects the content type (such as links, emails, phone numbers, contacts, events, and addresses) and provides relevant actions. It also maintains a history of scans for easy reference.

![App Logo](assets/logo.png) <!-- Optional: place logo image path here -->

## ✨ Features

- 🔍 QR Code Scanner with real-time detection
- 🧠 Smart content type detection:
  - URL → Open in browser
  - Email → Compose mail
  - Phone → Call
  - vCard → Save contact
  - Address → Open in Google Maps
  - Calendar event → Add to calendar
- 🧾 Scan History with timestamp
- ♻️ Scan again easily
- 📤 QR Code Generator for links (upcoming)

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  qr_code_scanner: ^1.0.1
  url_launcher: ^6.1.7
  contacts_service: ^0.6.3
  permission_handler: ^11.3.1
  add_2_calendar: ^2.2.3
  shared_preferences: ^2.2.2

git clone https://github.com/yourusername/MyQRCode.git
cd MyQRCode
lib/
├── main.dart
├── qr_code_scanner.dart
├── qr_history_screen.dart
├── scan_history_item.dart
├── utils/
│   └── detection_helper.dart (optional helper for content type)
assets/
└── logo.png
