# Quick Start Guide - Firebase Push Notifications

## 🎯 What's Working

Your CRM Admin app now has **fully functional push notifications** with:

✅ **Foreground notifications** - Appears when app is open  
✅ **Background notifications** - Shows in notification tray when app is minimized  
✅ **Terminated notifications** - Receives notifications even when app is completely closed  
✅ **Sound & Vibration** - Custom vibration pattern and notification sound  
✅ **Click Handling** - Navigate to specific screens when notification is clicked  

---

## 🚀 How to Access

1. **Run the app**: `flutter run`
2. **Navigate to**: Home → Profile (bottom nav) → Notifications
3. **Copy your FCM Token** displayed on the screen

---

## 📬 Send Your First Test Notification

### Using Firebase Console (Easiest Way):

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select project: **rudraashwicrm7000**
3. Go to: **Engage** → **Cloud Messaging**
4. Click **"Create your first campaign"** or **"New campaign"**
5. Select **"Firebase Notification messages"**
6. Fill in:
   - **Title**: "Test Notification"
   - **Text**: "Hello from Firebase!"
7. Click **"Send test message"**
8. **Paste your FCM token** (from the app)
9. Click **"Test"**

---

## 🔔 Test All States

### Test 1: App Open (Foreground)
- App is **visible on screen**
- Send notification from Firebase Console
- ✅ Should see banner notification with sound & vibration

### Test 2: App Minimized (Background)
- Press **Home button** (app still running in background)
- Send notification from Firebase Console
- ✅ Should appear in notification tray with sound & vibration
- Tap notification → App opens

### Test 3: App Closed (Terminated)
- **Swipe away** the app from recent apps
- Send notification from Firebase Console
- ✅ Should appear in notification tray with sound & vibration
- Tap notification → App launches

---

## 📱 Features Included

- **Custom Notification Channel**: "CRM Notifications"
- **High Priority**: Ensures notifications appear immediately
- **Sound**: Default system notification sound
- **Vibration Pattern**: Short-long-short (1000ms-500ms-1000ms)
- **Large Icon**: App icon appears in notification
- **Topic Subscriptions**: Subscribe to group notifications
  - `all_users`
  - `leads_updates`
  - `admin_alerts`

---

## 🔧 Integration with Backend

To send notifications from your backend:

```javascript
// Example using Firebase Admin SDK (Node.js)
const message = {
  token: 'USER_FCM_TOKEN_HERE',
  notification: {
    title: 'New Lead Assigned',
    body: 'You have a new lead from Mumbai'
  },
  data: {
    screen: 'lead_detail',
    leadId: '12345'
  },
  android: {
    priority: 'high',
    notification: {
      sound: 'default',
      vibrationPattern: [0, 1000, 500, 1000]
    }
  }
};

await admin.messaging().send(message);
```

---

## ✨ Key Implementation Details

### Files Added/Modified:

1. **`android/app/google-services.json`** - Firebase configuration
2. **`lib/core/services/firebase_notification_service.dart`** - Complete notification service
3. **`lib/ui/screens/notifications/notification_test_screen.dart`** - Settings screen
4. **`lib/main.dart`** - Firebase initialization
5. **Android build files** - Google Services plugin
6. **AndroidManifest.xml** - Notification permissions

### Permissions Added:

- `POST_NOTIFICATIONS` - Android 13+ notification permission
- `VIBRATE` - Vibration support
- `WAKE_LOCK` - Wake device on notification
- `RECEIVE_BOOT_COMPLETED` - Persist after reboot

---

## 🎨 Customization Options

### Change Vibration Pattern:
Edit `firebase_notification_service.dart`:
```dart
vibrationPattern: Int64List.fromList([0, 500, 250, 500])
```

### Handle Notification Clicks:
Update `_handleNotificationClick()` to navigate to specific screens based on notification data.

### Add Custom Sound:
1. Add sound file to `android/app/src/main/res/raw/`
2. Update: `sound: RawResourceAndroidNotificationSound('your_sound')`

---

## ⚠️ Important Notes

- **FCM Token**: Changes when app is reinstalled - save it to your backend
- **Permissions**: Android 13+ requires runtime notification permission
- **Testing**: Use Firebase Console for quick testing before backend integration
- **Production**: Implement proper token management in your backend

---

## 📞 Need Help?

- Check `FIREBASE_NOTIFICATIONS_SETUP.md` for detailed documentation
- Review logs in Android Studio/VS Code for debugging
- Test with Firebase Console before integrating with backend
- Ensure app has notification permissions enabled in device settings

---

**🎉 You're all set! Try sending a test notification now!**
