const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function that triggers when a new notification is added
 * to any user's notifications subcollection and sends a push notification
 */
exports.sendNotificationOnCreate = functions.firestore
  .document('customers/{userId}/notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    try {
      const userId = context.params.userId;
      const notificationData = snap.data();
      
      console.log(`📩 New notification created for user: ${userId}`);
      console.log('📄 Notification data:', notificationData);

      // Get the user document to retrieve FCM token
      const userDoc = await admin.firestore()
        .collection('customers')
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.error('❌ User document not found:', userId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.error('❌ No FCM token found for user:', userId);
        return null;
      }

      // Prepare the notification payload
      let notificationTitle = 'Captain Truck';
      let notificationBody = notificationData.message || 'You have a new notification';

      // Customize notification based on type
      if (notificationData.type === 'trip_update') {
        notificationTitle = '🚛 Trip Update';
        notificationBody = notificationData.message || 'Your trip has been updated';
      } else if (notificationData.type === 'admin_message') {
        notificationTitle = '💬 Message from Captain Truck';
        notificationBody = notificationData.message || 'You have a new message';
      } else if (notificationData.type === 'booking_confirmed') {
        notificationTitle = '✅ Booking Confirmed';
        notificationBody = notificationData.message || 'Your booking has been confirmed';
      } else if (notificationData.type === 'booking_cancelled') {
        notificationTitle = '❌ Booking Cancelled';
        notificationBody = notificationData.message || 'Your booking has been cancelled';
      } else if (notificationData.type === 'driver_assigned') {
        notificationTitle = '👨‍✈️ Driver Assigned';
        notificationBody = notificationData.message || 'A driver has been assigned to your trip';
      } else if (notificationData.type === 'payment_reminder') {
        notificationTitle = '💳 Payment Reminder';
        notificationBody = notificationData.message || 'Payment is pending for your trip';
      } else {
        notificationTitle = notificationData.title || 'Captain Truck';
      }

      // Create the FCM message with enhanced design
      const message = {
        token: fcmToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
          imageUrl: 'https://firebasestorage.googleapis.com/v0/b/captain-truck-242e5.firebasestorage.app/o/assets%2Flogo.png?alt=media&token=da4390b6-f593-4246-8541-32e5757ccf5c', // App logo URL
        },
        data: {
          type: notificationData.type || 'general',
          notificationId: context.params.notificationId,
          userId: userId,
          tripId: notificationData.tripId || '',
          senderId: notificationData.senderId || '',
          priority: notificationData.priority || 'normal',
          timestamp: (notificationData.timestamp || admin.firestore.Timestamp.now()).toDate().toISOString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            icon: 'ic_notification', // Uses your app's notification icon
            color: '#4285F4', // Captain Truck primary color
            channelId: 'high_importance_channel',
            priority: 'high',
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            tag: notificationData.type || 'general', // Groups similar notifications
            notificationPriority: 'PRIORITY_HIGH',
            image: 'https://firebasestorage.googleapis.com/v0/b/captain-truck-242e5.firebasestorage.app/o/assets%2Flogo.png?alt=media&token=da4390b6-f593-4246-8541-32e5757ccf5c',
          },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'GENERAL',
            },
          },
          headers: {
            'apns-priority': '10',
          },
        },
      };

      // Send the notification
      console.log(`🚀 Sending FCM notification to user: ${userId}`);
      const response = await admin.messaging().send(message);
      console.log('✅ Successfully sent message:', response);

      return response;

    } catch (error) {
      console.error('❌ Error sending notification:', error);
      return null;
    }
  });

/**
 * Cloud Function to send admin notifications to all users
 */
exports.sendAdminNotificationToAll = functions.https.onCall(async (data, context) => {
  try {
    // Verify that the request is from an admin
    if (!context.auth || !context.auth.token.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can send notifications to all users');
    }

    const { title, message, type } = data;

    if (!title || !message) {
      throw new functions.https.HttpsError('invalid-argument', 'Title and message are required');
    }

    console.log('📢 Sending admin notification to all users');

    // Get all users with FCM tokens
    const usersSnapshot = await admin.firestore()
      .collection('customers')
      .where('fcmToken', '!=', null)
      .get();

    if (usersSnapshot.empty) {
      console.log('⚠️ No users found with FCM tokens');
      return { success: true, message: 'No users to notify' };
    }

    const promises = [];

    // Send notification to each user
    usersSnapshot.forEach(userDoc => {
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (fcmToken) {
        const messagePayload = {
          token: fcmToken,
          notification: {
            title: `📢 ${title}`,
            body: message,
            imageUrl: 'https://firebasestorage.googleapis.com/v0/b/captain-truck-242e5.firebasestorage.app/o/assets%2Flogo.png?alt=media&token=da4390b6-f593-4246-8541-32e5757ccf5c',
          },
          data: {
            type: type || 'admin_broadcast',
            timestamp: new Date().toISOString(),
            priority: 'high',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            notification: {
              icon: 'ic_notification',
              color: '#4285F4',
              channelId: 'high_importance_channel',
              priority: 'high',
              sound: 'default',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
              tag: 'admin_broadcast',
              image: 'https://firebasestorage.googleapis.com/v0/b/captain-truck-242e5.firebasestorage.app/o/assets%2Flogo.png?alt=media&token=da4390b6-f593-4246-8541-32e5757ccf5c',
            },
            data: {
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          apns: {
            payload: {
              aps: {
                badge: 1,
                sound: 'default',
                category: 'ADMIN_MESSAGE',
              },
            },
            headers: {
              'apns-priority': '10',
            },
          },
        };

        promises.push(admin.messaging().send(messagePayload));
      }
    });

    // Wait for all notifications to be sent
    const results = await Promise.allSettled(promises);
    const successful = results.filter(result => result.status === 'fulfilled').length;
    const failed = results.filter(result => result.status === 'rejected').length;

    console.log(`✅ Admin notification sent: ${successful} successful, ${failed} failed`);

    return {
      success: true,
      message: `Notification sent to ${successful} users, ${failed} failed`
    };

  } catch (error) {
    console.error('❌ Error sending admin notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cloud Function for testing notifications (callable from admin panel)
 */
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  try {
    const { userId, title, message, type } = data;

    if (!userId || !title || !message) {
      throw new functions.https.HttpsError('invalid-argument', 'userId, title, and message are required');
    }

    console.log('🧪 Sending test notification to user:', userId);

    // Add notification to user's Firestore collection
    await admin.firestore()
      .collection('customers')
      .doc(userId)
      .collection('notifications')
      .add({
        title: title,
        message: message,
        type: type || 'test',
        senderId: 'system_test',
        priority: 'high',
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log('✅ Test notification added to Firestore - FCM will be triggered automatically');

    return {
      success: true,
      message: 'Test notification sent successfully'
    };

  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cloud Function to handle notification clicks (optional analytics)
 */
exports.trackNotificationClick = functions.https.onCall(async (data, context) => {
  try {
    const { notificationId, userId } = data;

    if (!notificationId || !userId) {
      return { success: false, message: 'Missing required parameters' };
    }

    // Mark notification as clicked
    await admin.firestore()
      .collection('customers')
      .doc(userId)
      .collection('notifications')
      .doc(notificationId)
      .update({
        clicked: true,
        clickedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log(`📊 Notification clicked: ${notificationId} by user: ${userId}`);

    return { success: true, message: 'Click tracked successfully' };

  } catch (error) {
    console.error('❌ Error tracking notification click:', error);
    return { success: false, message: error.message };
  }
});

/**
 * Cloud Function to clean up old notifications (optional)
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 2 * * *') // Run daily at 2 AM
  .onRun(async (context) => {
    try {
      console.log('🧹 Starting cleanup of old notifications');

      const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      );

      // Get all customer documents
      const customersSnapshot = await admin.firestore()
        .collection('customers')
        .get();

      const deletePromises = [];

      for (const customerDoc of customersSnapshot.docs) {
        const userId = customerDoc.id;
        
        // Get old notifications for this user
        const oldNotificationsSnapshot = await admin.firestore()
          .collection('customers')
          .doc(userId)
          .collection('notifications')
          .where('timestamp', '<', thirtyDaysAgo)
          .get();

        // Delete each old notification
        oldNotificationsSnapshot.forEach(notificationDoc => {
          deletePromises.push(notificationDoc.ref.delete());
        });
      }

      await Promise.all(deletePromises);

      console.log(`✅ Cleaned up ${deletePromises.length} old notifications`);
      return null;

    } catch (error) {
      console.error('❌ Error cleaning up notifications:', error);
      return null;
    }
  });

/**
 * HTTP function to get notification statistics (for admin dashboard)
 */
exports.getNotificationStats = functions.https.onRequest(async (req, res) => {
  try {
    console.log('📊 Getting notification statistics');

    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const stats = {
      totalUsers: 0,
      usersWithTokens: 0,
      totalNotifications: 0,
      unreadNotifications: 0,
      notificationsByType: {},
      recentActivity: [],
    };

    // Get all customers
    const customersSnapshot = await admin.firestore()
      .collection('customers')
      .get();

    stats.totalUsers = customersSnapshot.size;

    for (const customerDoc of customersSnapshot.docs) {
      const customerData = customerDoc.data();

      // Count users with FCM tokens
      if (customerData.fcmToken) {
        stats.usersWithTokens++;
      }

      // Get recent notifications for this user (last 7 days)
      const recentDate = new Date();
      recentDate.setDate(recentDate.getDate() - 7);

      const notificationsSnapshot = await customerDoc.ref
        .collection('notifications')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(recentDate))
        .orderBy('timestamp', 'desc')
        .limit(10)
        .get();

      stats.totalNotifications += notificationsSnapshot.size;

      notificationsSnapshot.forEach(notificationDoc => {
        const notificationData = notificationDoc.data();

        // Count unread notifications
        if (!notificationData.read) {
          stats.unreadNotifications++;
        }

        // Count notifications by type
        const type = notificationData.type || 'unknown';
        stats.notificationsByType[type] = (stats.notificationsByType[type] || 0) + 1;

        // Add to recent activity
        if (stats.recentActivity.length < 20) {
          stats.recentActivity.push({
            type: type,
            title: notificationData.title,
            timestamp: notificationData.timestamp,
            userId: customerDoc.id.substring(0, 8) + '...', // Anonymize user ID
          });
        }
      });
    }

    console.log('📈 Notification stats generated successfully');

    res.json({
      success: true,
      data: stats,
      timestamp: new Date().toISOString(),
    });

  } catch (error) {
    console.error('❌ Error getting notification stats:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Cloud Function to sync status and currentStatus fields in dispatches collection
 * This fixes the data inconsistency issue
 */
exports.syncDispatchStatuses = functions.https.onRequest(async (req, res) => {
  try {
    console.log('Starting dispatch status synchronization...');
    
    // Get all dispatches
    const dispatchesSnapshot = await admin.firestore().collection('dispatches').get();
    
    let updateCount = 0;
    let errors = 0;
    const batch = admin.firestore().batch();
    
    dispatchesSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      const mainStatus = data.status;
      const currentStatusObject = data.currentStatus;
      
      // Check if synchronization is needed
      if (currentStatusObject && currentStatusObject.status !== mainStatus) {
        console.log(`Syncing dispatch ${doc.id}: main status "${mainStatus}" != currentStatus "${currentStatusObject.status}"`);
        
        // Update currentStatus to match main status
        const syncedCurrentStatus = {
          status: mainStatus,
          updatedAt: data.updatedAt || admin.firestore.FieldValue.serverTimestamp()
        };
        
        batch.update(doc.ref, {
          currentStatus: syncedCurrentStatus
        });
        
        updateCount++;
      }
    });
    
    // Commit all updates
    if (updateCount > 0) {
      await batch.commit();
      console.log(`Successfully synchronized ${updateCount} dispatch statuses`);
    } else {
      console.log('No synchronization needed - all statuses are already in sync');
    }
    
    res.status(200).json({
      success: true,
      message: `Synchronized ${updateCount} dispatch statuses`,
      totalChecked: dispatchesSnapshot.docs.length,
      updated: updateCount,
      errors: errors
    });
    
  } catch (error) {
    console.error('Error synchronizing dispatch statuses:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to synchronize dispatch statuses',
      error: error.message
    });
  }
});

/**
 * Trigger this function when a dispatch document is updated
 * to ensure status fields stay synchronized
 */
exports.maintainStatusSync = functions.firestore
  .document('dispatches/{dispatchId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    
    // Check if main status was updated but currentStatus wasn't
    if (beforeData.status !== afterData.status) {
      const currentStatusNeedsUpdate = 
        !afterData.currentStatus || 
        afterData.currentStatus.status !== afterData.status;
      
      if (currentStatusNeedsUpdate) {
        console.log(`Auto-syncing status for dispatch ${context.params.dispatchId}`);
        
        // Update currentStatus to match main status
        await change.after.ref.update({
          'currentStatus.status': afterData.status,
          'currentStatus.updatedAt': admin.firestore.FieldValue.serverTimestamp()
        });
        
        console.log(`Successfully synced status to "${afterData.status}" for dispatch ${context.params.dispatchId}`);
      }
    }
  });
