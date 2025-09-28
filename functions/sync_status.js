const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin (if not already initialized)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function to sync status and currentStatus fields in dispatches collection
 * This fixes the data inconsistency issue
 */
exports.syncDispatchStatuses = functions.https.onRequest(async (req, res) => {
  try {
    console.log('Starting dispatch status synchronization...');
    
    // Get all dispatches
    const dispatchesSnapshot = await db.collection('dispatches').get();
    
    let updateCount = 0;
    let errors = 0;
    const batch = db.batch();
    
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
