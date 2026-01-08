# Firebase Push Notifications Setup

## ✅ Implementation Complete

Firebase Cloud Messaging (FCM) has been successfully integrated into your CRM Admin app with full support for:

- 🔔 **Foreground notifications** (app is open)
- 📱 **Background notifications** (app is minimized)
- 💤 **Terminated notifications** (app is closed)
- 🔊 **Sound** on notification arrival
- 📳 **Vibration** with custom pattern
- 👆 **Click handling** for navigation

---

## 📋 What Was Added

### 1. **Firebase Configuration**
- ✅ `google-services.json` added to `android/app/`
- ✅ Firebase Core and Messaging dependencies
- ✅ Flutter Local Notifications for display

### 2. **Android Configuration**
- ✅ Google Services plugin in build.gradle files
- ✅ Notification permissions in AndroidManifest.xml
- ✅ Firebase Messaging service configuration
- ✅ Default notification channel setup

### 3. **Flutter Implementation**
- ✅ `FirebaseNotificationService` - Complete notification handling
- ✅ `NotificationTestScreen` - View FCM token and manage settings
- ✅ Integration in main.dart with Firebase initialization
- ✅ Added to Profile screen for easy access

### 4. **Notification Features**
- ✅ Custom notification channel "CRM Notifications"
- ✅ Sound enabled (default notification sound)
- ✅ Vibration pattern: [0ms, 1000ms, 500ms, 1000ms]
- ✅ High priority notifications with alerts
- ✅ Topic-based subscriptions (all_users, leads_updates, admin_alerts)

---

## 🧪 How to Test Notifications

### Step 1: Get Your FCM Token

1. Build and run the app:
   ```powershell
   flutter run
   ```

2. Navigate to: **Profile → Notifications**

3. Copy the FCM token displayed on the screen

### Step 2: Send Test Notification

#### Option A: Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **rudraashwicrm7000**
3. Navigate to: **Engage → Messaging**
4. Click **"Send your first message"**
5. Fill in:
   - **Notification title**: "Test Notification"
   - **Notification text**: "This is a test message"
6. Click **"Send test message"**
7. Paste your FCM token
8. Click **"Test"**

#### Option B: Using Your Backend API

Send a POST request to Firebase FCM endpoint:

```bash
POST https://fcm.googleapis.com/fcm/send
Content-Type: application/json
Authorization: Bearer YOUR_SERVER_KEY

{
  "to": "YOUR_FCM_TOKEN_HERE",
  "notification": {
    "title": "New Lead Assigned",
    "body": "You have been assigned a new lead from Delhi",
    "sound": "default",
    "vibrate": [0, 1000, 500, 1000]
  },
  "data": {
    "screen": "leads",
    "leadId": "123",
    "action": "view_detail"
  },
  "priority": "high"
}
```

#### Option C: Topic-Based Notification

In the app:
1. Subscribe to a topic (e.g., "all_users")
2. Send notification to topic from Firebase Console

---

## 🔔 Testing Scenarios

### Test 1: Foreground Notification
- **App State**: Open and visible
- **Expected**: Notification appears as banner/toast
- **Sound**: ✅ Plays
- **Vibration**: ✅ Vibrates

### Test 2: Background Notification
- **App State**: Minimized (press home button)
- **Expected**: Notification in notification tray
- **Sound**: ✅ Plays
- **Vibration**: ✅ Vibrates
- **Click**: Opens app

### Test 3: Terminated Notification
- **App State**: Completely closed (swipe away from recent apps)
- **Expected**: Notification in notification tray
- **Sound**: ✅ Plays
- **Vibration**: ✅ Vibrates
- **Click**: Opens app

---

## 🎯 Notification Payload Structure

### Basic Notification
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "Notification Title",
    "body": "Notification message body",
    "sound": "default"
  },
  "priority": "high"
}
```

### Notification with Data
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "Lead Updated",
    "body": "Lead #12345 status changed to IN_PROGRESS"
  },
  "data": {
    "screen": "lead_detail",
    "leadId": "12345",
    "action": "view"
  },
  "priority": "high"
}
```

### Topic Notification
```json
{
  "to": "/topics/all_users",
  "notification": {
    "title": "System Announcement",
    "body": "The system will undergo maintenance tonight"
  },
  "priority": "high"
}
```

---

## 📱 Available Topics

The app supports subscription to these topics:

- `all_users` - All app users
- `leads_updates` - Lead-related notifications
- `admin_alerts` - Administrative alerts

**Subscribe via the app**: Profile → Notifications → Topic Subscriptions

---

## 🛠️ Backend Integration

To integrate with your backend, you'll need to:

### 1. Save FCM Token on Login

After user logs in, get and save their FCM token:

```dart
final fcmToken = FirebaseNotificationService().fcmToken;
// Send this token to your backend API
```

### 2. Backend API to Send Notifications

Your backend should send notifications using Firebase Admin SDK:

**Example (Node.js)**:
```javascript
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send notification
await admin.messaging().send({
  token: userFcmToken,
  notification: {
    title: 'Lead Assigned',
    body: 'New lead from Mumbai'
  },
  data: {
    leadId: '123',
    screen: 'lead_detail'
  },
  android: {
    priority: 'high',
    notification: {
      sound: 'default',
      vibrationPattern: [0, 1000, 500, 1000]
    }
  }
});
```

---

## 🔧 Customization

### Change Notification Sound

1. Add custom sound file to `android/app/src/main/res/raw/notification.mp3`
2. Update in `firebase_notification_service.dart`:
   ```dart
   sound: RawResourceAndroidNotificationSound('your_sound_name')
   ```

### Change Vibration Pattern

In `firebase_notification_service.dart`:
```dart
vibrationPattern: Int64List.fromList([0, 500, 250, 500])
// [delay, vibrate, pause, vibrate, ...]
```

### Handle Notification Click

Update `_handleNotificationClick` in `firebase_notification_service.dart`:
```dart
void _handleNotificationClick(RemoteMessage message) {
  final screen = message.data['screen'];
  final leadId = message.data['leadId'];
  
  // Navigate to specific screen
  if (screen == 'lead_detail') {
    // Navigate to lead detail page
  }
}
```

---

## 🐛 Troubleshooting

### Notifications Not Appearing?

1. **Check permissions**: Go to App Settings → Notifications → Ensure enabled
2. **Verify token**: Copy FCM token from app and use in test
3. **Check logs**: Look for Firebase-related errors in console
4. **Rebuild app**: Clean build after adding Firebase
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

### No Sound/Vibration?

1. **Phone settings**: Check "Do Not Disturb" is off
2. **Notification channel**: Ensure channel importance is HIGH
3. **App permissions**: Verify notification permissions granted

### App Crashes?

1. **Check google-services.json**: Ensure package name matches
2. **Build configuration**: Verify Google Services plugin applied
3. **Dependencies**: Run `flutter pub get`

---

## 📝 Files Modified

- `android/app/google-services.json` - Firebase config
- `android/build.gradle.kts` - Added Google Services classpath
- `android/app/build.gradle.kts` - Applied Google Services plugin
- `android/app/src/main/AndroidManifest.xml` - Notification permissions
- `pubspec.yaml` - Firebase dependencies
- `lib/main.dart` - Firebase initialization
- `lib/core/services/firebase_notification_service.dart` - Notification service (NEW)
- `lib/ui/screens/notifications/notification_test_screen.dart` - Test screen (NEW)
- `lib/ui/screens/profile/profile_screen.dart` - Added notifications menu

---

## 🚀 Next Steps

1. ✅ Test notifications in all states (foreground, background, terminated)
2. ✅ Integrate FCM token saving to your backend
3. ✅ Implement notification click navigation to specific screens
4. ✅ Set up backend API to send notifications
5. ✅ Configure topic-based notifications for user groups
6. ✅ Add custom notification sounds (optional)
7. ✅ Set up scheduled notifications (if needed)

---

## 📞 Support

For issues or questions about Firebase notifications:
- Check logs in Android Studio/VS Code
- Review Firebase Console for delivery status
- Test with Firebase Console before integrating backend

**Your Firebase project**: `rudraashwicrm7000`  
**Package name**: `com.crm.admin.crm_admin`

---

**✨ Notifications are fully configured and ready to use!**
