#!/usr/bin/env python3
"""
Firebase Test Notification Sender

This script sends a test notification to a specific FCM token.
Usage:
    python send_test_notification.py YOUR_FCM_TOKEN

You'll need:
1. Firebase Server Key from Firebase Console
2. FCM token from the app
"""

import sys
import json
import requests

def send_notification(fcm_token, title="Test Notification", body="This is a test from Firebase"):
    """Send a test notification to the given FCM token"""
    
    # Get your server key from Firebase Console > Project Settings > Cloud Messaging
    # TODO: Replace with your actual Firebase Server Key
    SERVER_KEY = "YOUR_FIREBASE_SERVER_KEY_HERE"
    
    url = "https://fcm.googleapis.com/fcm/send"
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {SERVER_KEY}"
    }
    
    payload = {
        "to": fcm_token,
        "priority": "high",
        "notification": {
            "title": title,
            "body": body,
            "sound": "default",
            "click_action": "FLUTTER_NOTIFICATION_CLICK"
        },
        "data": {
            "screen": "leads",
            "action": "view_all",
            "timestamp": "2026-01-06T12:00:00Z"
        },
        "android": {
            "priority": "high",
            "notification": {
                "sound": "default",
                "channel_id": "crm_notifications",
                "notification_priority": "PRIORITY_HIGH"
            }
        }
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        
        print("✅ Notification sent successfully!")
        print(f"Response: {response.json()}")
        return True
        
    except requests.exceptions.HTTPError as e:
        print(f"❌ HTTP Error: {e}")
        print(f"Response: {e.response.text}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python send_test_notification.py YOUR_FCM_TOKEN")
        print("\nGet your FCM token from the app:")
        print("1. Open the app")
        print("2. Go to Profile → Notifications")
        print("3. Copy the FCM token")
        sys.exit(1)
    
    fcm_token = sys.argv[1]
    title = sys.argv[2] if len(sys.argv) > 2 else "CRM Test Notification"
    body = sys.argv[3] if len(sys.argv) > 3 else "This is a test notification from your CRM Admin app!"
    
    print(f"📱 Sending notification to: {fcm_token[:20]}...")
    send_notification(fcm_token, title, body)
