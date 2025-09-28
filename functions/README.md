# Firebase Cloud Functions - Push Notifications System

This directory contains Firebase Cloud Functions that handle automatic push notifications for the Customer App.

## Functions Overview

### 1. `sendNotificationOnCreate` (Firestore Trigger)
**Type**: Automatic trigger when documents are created
**Path**: `customers/{userId}/notifications/{notificationId}`
**Purpose**: Automatically sends push notifications when new notification documents are added to Firestore

**Features**:
- ✅ Automatic FCM token retrieval
- ✅ Type-specific notification titles with emojis
- ✅ App logo integration in notifications
- ✅ Android/iOS optimized messaging
- ✅ High priority delivery for closed apps
- ✅ Error handling and logging

### 2. `sendAdminNotificationToAll` (Callable Function)
**Type**: HTTPS Callable (requires admin authentication)
**Purpose**: Send broadcast notifications to all users

**Usage**:
```javascript
const functions = firebase.functions();
const result = await functions.httpsCallable('sendAdminNotificationToAll')({
  title: 'System Maintenance',
  message: 'App will be down for maintenance at 2 AM',
  type: 'admin_announcement'
});
```

### 3. `sendTestNotification` (Callable Function)
**Type**: HTTPS Callable
**Purpose**: Send test notifications for debugging

**Usage**:
```javascript
const result = await functions.httpsCallable('sendTestNotification')({
  userId: 'user123',
  title: 'Test Notification',
  message: 'This is a test message',
  type: 'test'
});
```

### 4. `trackNotificationClick` (Callable Function)
**Type**: HTTPS Callable
**Purpose**: Track notification analytics when users click notifications

**Usage**:
```javascript
const result = await functions.httpsCallable('trackNotificationClick')({
  notificationId: 'notif123',
  userId: 'user123'
});
```

### 5. `cleanupOldNotifications` (Scheduled Function)
**Type**: Pub/Sub scheduled (runs daily at 2 AM UTC)
**Purpose**: Automatically delete notifications older than 30 days
**Schedule**: `0 2 * * *` (Daily at 2:00 AM)

### 6. `getNotificationStats` (HTTP Function)
**Type**: HTTP Request
**Purpose**: Get notification statistics for admin dashboard
**URL**: `https://us-central1-captain-truck-242e5.cloudfunctions.net/getNotificationStats`

**Response**:
```json
{
  "success": true,
  "data": {
    "totalUsers": 150,
    "usersWithTokens": 142,
    "totalNotifications": 1250,
    "unreadNotifications": 45,
    "notificationsByType": {
      "trip_update": 850,
      "admin_message": 200,
      "booking_confirmed": 200
    },
    "recentActivity": [...]
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Notification Types

The system supports various notification types with custom styling:

| Type | Icon | Title Format | Use Case |
|------|------|--------------|----------|
| `trip_update` | 🚛 | Trip Update | Driver location updates, trip status |
| `booking_confirmed` | ✅ | Booking Confirmed | Successful bookings |
| `booking_cancelled` | ❌ | Booking Cancelled | Cancelled bookings |
| `payment_received` | 💰 | Payment Received | Payment confirmations |
| `driver_assigned` | 👨‍✈️ | Driver Assigned | Driver assignment |
| `admin_message` | 📢 | Important Notice | Admin announcements |
| `promotion` | 🎉 | Special Offer | Promotional messages |
| `system_alert` | ⚠️ | System Alert | System notifications |
| `reminder` | ⏰ | Reminder | Booking reminders |

## Setup Instructions

### 1. Install Dependencies
```bash
cd functions
npm install
```

### 2. Configure Firebase
```bash
firebase login
firebase use captain-truck-242e5
```

### 3. Deploy Functions
```bash
firebase deploy --only functions
```

### 4. Test Functions
After deployment, test using the Firebase Console or your Flutter app.

## App Logo Configuration

The functions are configured to use the app logo from Firebase Storage:
```
https://firebasestorage.googleapis.com/v0/b/captain-truck-242e5.appspot.com/o/assets%2Flogo.png?alt=media
```

Make sure to upload your app logo to Firebase Storage at path: `assets/logo.png`

## Flutter Integration

### Add to Firestore to trigger notification:
```dart
await FirebaseFirestore.instance
  .collection('customers')
  .doc(userId)
  .collection('notifications')
  .add({
    'title': 'Your trip has started!',
    'message': 'Driver John is on the way to pick up your items.',
    'type': 'trip_update',
    'senderId': 'driver_123',
    'priority': 'high',
    'read': false,
    'timestamp': FieldValue.serverTimestamp(),
  });
```

### Handle notification clicks in Flutter:
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Handle notification click
  final data = message.data;
  if (data['type'] == 'trip_update') {
    // Navigate to trip screen
  }
});
```

## Error Handling

All functions include comprehensive error handling:
- Invalid FCM tokens are logged but don't stop execution
- Missing parameters return appropriate error messages
- All errors are logged with emojis for easy identification
- Failed deliveries are tracked and reported

## Monitoring

Monitor function execution in:
1. **Firebase Console** → Functions → Logs
2. **Google Cloud Console** → Cloud Functions
3. **Firebase Console** → Analytics (for notification analytics)

## Security

- Admin functions require proper authentication
- User-specific functions validate user permissions
- CORS is properly configured for HTTP functions
- All inputs are validated before processing

---

**Need Help?**
Check the Firebase Console logs for detailed error messages and execution traces.
