# RudraCRM Admin - Permission Explanation for Play Store Review

## ✅ MANAGE_EXTERNAL_STORAGE PERMISSION REMOVED

We have **REMOVED** the `android.permission.MANAGE_EXTERNAL_STORAGE` permission from our app.

---

## 📋 Current Permissions & Justification

### 1. **READ_CALL_LOG** ✅
- **Usage**: Reading user's call history to automatically create leads from calls
- **Core Feature**: Yes - CRM apps need to track customer interactions including phone calls
- **Technical Reason**: Used to import call logs and match them with existing leads/customers
- **Privacy**: Only reads call logs when user explicitly uses the "Import from Call Log" feature

### 2. **READ_PHONE_STATE** ✅
- **Usage**: Detecting incoming/outgoing calls to log customer interactions
- **Core Feature**: Yes - Essential for CRM call tracking functionality
- **Technical Reason**: Required to detect phone state changes for automatic call logging
- **Privacy**: No data is sent to external servers without user consent

### 3. **POST_NOTIFICATIONS** ✅
- **Usage**: Send Firebase Cloud Messaging notifications for:
  - New lead assignments
  - Follow-up reminders
  - Admin announcements
  - Subscription expiry alerts
- **Core Feature**: Yes - Critical for real-time team communication
- **Technical Reason**: Android 13+ requires explicit permission for notifications
- **Privacy**: Only app-related notifications, no spam

### 4. **INTERNET** ✅
- **Usage**: API communication with CRM backend server
- **Core Feature**: Yes - App is unusable without internet (cloud-based CRM)
- **Technical Reason**: Required for all CRUD operations on leads, users, reports
- **Privacy**: All communication uses HTTPS encryption

### 5. **WRITE_EXTERNAL_STORAGE** (maxSdkVersion="32") ✅
- **Usage**: Downloading Excel/CSV reports to device storage
- **Core Feature**: No - Optional feature for offline report access
- **Technical Reason**: 
  - Only needed for Android 10, 11, 12 (SDK 29-32)
  - Android 13+ uses scoped storage (no permission needed)
  - Uses `getExternalStorageDirectory()` to save reports in Downloads folder
- **Privacy**: Only writes app-generated reports, no access to user files
- **Alternative Used**: Scoped storage for Android 13+, MediaStore API for downloads

### 6. **READ_EXTERNAL_STORAGE** (maxSdkVersion="32") ✅
- **Usage**: 
  - File picker to select Excel files for bulk lead import
  - Reading downloaded reports
- **Core Feature**: No - Optional feature for bulk operations
- **Technical Reason**:
  - Uses Storage Access Framework (SAF) via `file_picker` package
  - Only accesses files explicitly selected by user through system picker
  - Android 13+ doesn't need this permission
- **Privacy**: Only reads files user explicitly selects, uses SAF

---

## 🔧 Technical Implementation Details

### File Operations:
1. **Excel Upload** (Upload Leads):
   - Uses `FilePicker.platform.pickFiles()` with SAF
   - User explicitly selects file from system picker
   - Privacy-friendly: No broad storage access
   
2. **Report Download**:
   - Android 10-12: Uses `Permission.storage` (READ/WRITE_EXTERNAL_STORAGE)
   - Android 13+: Uses scoped storage (no permission needed)
   - Downloads to public Downloads folder using `path_provider`
   - No MANAGE_EXTERNAL_STORAGE required

### Why We DON'T Need MANAGE_EXTERNAL_STORAGE:
- ❌ Not a file manager app
- ❌ Not a backup/restore app
- ❌ Not an antivirus app
- ✅ Uses SAF for file picking
- ✅ Uses scoped storage for downloads
- ✅ Follows Android best practices for privacy

---

## 📱 App Core Functionality

**RudraCRM Admin is a customer relationship management application for business administrators.**

### Core Features (App is broken without these):
1. ✅ Lead management (create, update, assign, track)
2. ✅ User/employee management
3. ✅ Real-time notifications for assignments
4. ✅ Dashboard analytics
5. ✅ Call log integration for CRM tracking
6. ✅ Follow-up reminders
7. ✅ Subscription management

### Optional Features (App works without these):
1. 📊 Excel report generation (can use email delivery instead)
2. 📤 Bulk lead import via Excel (can add leads manually)
3. 📞 Call log import (can log calls manually)

---

## 🔒 Privacy & Security

- All API communication uses HTTPS
- Firebase Crashlytics for error tracking (anonymized)
- No user data sold or shared with third parties
- Permissions requested only when needed
- Clear user consent for sensitive features

---

## ✅ Compliance Summary

| Permission | Core Feature? | Alternatives Used | Compliant? |
|-----------|--------------|-------------------|------------|
| READ_CALL_LOG | Yes | None (core CRM feature) | ✅ Yes |
| READ_PHONE_STATE | Yes | None (core CRM feature) | ✅ Yes |
| POST_NOTIFICATIONS | Yes | None (critical for team) | ✅ Yes |
| INTERNET | Yes | None (cloud-based app) | ✅ Yes |
| READ/WRITE_STORAGE | No | SAF, Scoped Storage | ✅ Yes |
| ~~MANAGE_EXTERNAL_STORAGE~~ | ❌ REMOVED | SAF + Scoped Storage | ✅ Yes |

---

## 📝 Changes Made (Version 1.0.1+2)

### Removed:
- ❌ `MANAGE_EXTERNAL_STORAGE` permission from AndroidManifest.xml

### Updated:
- ✅ Report download logic to use scoped storage
- ✅ Added SDK version check (Android 13+ no permission needed)
- ✅ Uses `device_info_plus` to detect Android version
- ✅ Only requests storage permission for Android 10-12
- ✅ File picker already uses SAF (Storage Access Framework)

### Files Modified:
1. `android/app/src/main/AndroidManifest.xml` - Removed MANAGE_EXTERNAL_STORAGE
2. `lib/ui/screens/reports/generate_report_screen.dart` - Updated download logic
3. `pubspec.yaml` - Added device_info_plus dependency

---

## 🎯 For Play Store Reviewers

**Your app uses android.permission.MANAGE_EXTERNAL_STORAGE:**
- ✅ **RESOLVED**: This permission has been completely removed from our app.

**Alternative Approach:**
- We now use Storage Access Framework (SAF) for file selection
- We use scoped storage for report downloads
- Android 13+ requires no storage permissions
- Android 10-12 uses standard READ/WRITE_EXTERNAL_STORAGE (maxSdkVersion=32)

**App Description on Play Store:**
RudraCRM Admin is a customer relationship management platform for businesses. Key features include:
- Lead tracking and assignment
- Employee performance monitoring
- Real-time notification system
- Call log integration for sales teams
- Subscription and tenant management
- Excel report generation and bulk import

Contact: support@rudraashwicrm.com

---

## 📦 Build Information

- App Version: 1.0.1+2
- Package Name: com.crm.admin.crm_admin
- Build Date: February 3, 2026
- Target SDK: 34 (Android 14)
- Min SDK: 21 (Android 5.0)

---

**This app fully complies with Google Play's storage permission policies.**
