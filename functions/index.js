

const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

exports.sendFcmFromQueue = functions.firestore
  .document('fcm_queue/{docId}')
  .onCreate(async (snap, context) => {
    const docId = context.params.docId;
    const queueData = snap.data() || {};

    const token = (queueData.token || '').toString().trim();
    if (!token) {
      console.log(`[sendFcmFromQueue] ${docId}: no token present, skipping.`);
      await snap.ref.update({
        sent: false,
        error: 'no_token',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    }

    // Build the data payload. Every value in a FCM `data` map MUST be a
    // string — coerce everything defensively.
    const nestedData = queueData.data && typeof queueData.data === 'object'
      ? queueData.data
      : {};

    const dataPayload = {
      type: (queueData.type || nestedData.type || '').toString(),
      title: (queueData.title || '').toString(),
      body: (queueData.body || '').toString(),
      orderId: (queueData.orderId || nestedData.orderId || '').toString(),
      providerId: (queueData.providerId || nestedData.providerId || '').toString(),
      receiverId: (queueData.receiverId || queueData.userId || nestedData.receiverId || '').toString(),
      businessName: (queueData.businessName || '').toString(),
      serviceType: (queueData.serviceType || '').toString(),
      reason: (queueData.reason || '').toString(),
    };

    // Strip empty keys — cleaner payload, avoids sending "" for
    // everything that wasn't relevant to this particular notification.
    Object.keys(dataPayload).forEach((k) => {
      if (dataPayload[k] === '') delete dataPayload[k];
    });

    const message = {
      token,
      data: dataPayload,
      android: {
        priority: 'high',
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            'content-available': 1,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log(`[sendFcmFromQueue] ${docId}: sent OK, messageId=${response}`);
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmMessageId: response,
      });
    } catch (err) {
      console.error(`[sendFcmFromQueue] ${docId}: send FAILED`, err);

      // Common actionable cases, logged plainly so they show up in
      // `firebase functions:log` without needing to decode error codes.
      const code = err && err.code ? err.code : 'unknown';
      if (code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token') {
        console.error(`[sendFcmFromQueue] ${docId}: token is stale/invalid — `
          + `the provider's device likely reinstalled the app or cleared data. `
          + `A fresh token will be written next time NotificationService.initialize() `
          + `runs on their device.`);
      }

      await snap.ref.update({
        sent: false,
        error: code,
        errorMessage: (err && err.message) ? err.message : String(err),
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return null;
  });

/**
 * OPTIONAL BUT RECOMMENDED — cleanup old processed queue docs so
 * `fcm_queue` doesn't grow forever. Runs once a day, deletes anything
 * older than 2 days regardless of sent/failed status.
 */
exports.cleanupFcmQueue = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const cutoff = admin.firestore.Timestamp.fromMillis(
      Date.now() - 2 * 24 * 60 * 60 * 1000,
    );

    const snap = await db
      .collection('fcm_queue')
      .where('createdAt', '<', cutoff)
      .limit(500)
      .get();

    if (snap.empty) {
      console.log('[cleanupFcmQueue] nothing to clean up.');
      return null;
    }

    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    console.log(`[cleanupFcmQueue] deleted ${snap.docs.length} old fcm_queue docs.`);
    return null;
  });