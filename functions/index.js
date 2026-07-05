/**
 * ============================================================
 * fcm_queue → real device push notification
 *
 * THIS is the missing piece. Your Flutter app already writes
 * documents into `fcm_queue` correctly (order_service.dart /
 * notification_service.dart) and already writes to `notifications`
 * for the in-app bell. But writing a Firestore document does NOT
 * send a push by itself — something server-side has to notice the
 * new document and call the Firebase Admin SDK's messaging().send().
 * That's exactly what this function does.
 *
 * Once this is deployed, every fcm_queue document you're already
 * creating will result in a REAL system-level notification — heads-up
 * popup, lock-screen, sound, vibration — whether the CallMe app is in
 * the foreground, backgrounded, or fully killed. Nothing on the
 * Flutter side needs to change; it already writes the right shape of
 * document.
 *
 * DEPLOY:
 *   1. From your Firebase project root:  firebase init functions
 *      (choose JavaScript, skip if functions/ already exists)
 *   2. Drop this file in as functions/index.js
 *   3. cd functions && npm install firebase-admin firebase-functions
 *   4. firebase deploy --only functions
 *
 * REQUIRES: Blaze (pay-as-you-go) plan. Firestore-triggered functions
 * don't run on the free Spark plan — but Blaze still has a generous
 * free monthly quota, so for an app this size you likely pay ₹0.
 * ============================================================
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

/**
 * Fires once for every new document created in `fcm_queue`.
 * Expects the exact shape your Dart code already writes:
 *   {
 *     token: string,          // device FCM token
 *     receiverId: string,     // uid of the user/provider doc
 *     providerId?: string,    // only present for provider-bound pushes
 *     orderId: string,
 *     title: string,
 *     body: string,
 *     type: string,           // e.g. 'new_booking', 'booking_accepted'
 *     data: { ... },          // small map of extra fields, all strings
 *     sent: false,
 *     createdAt: Timestamp,
 *   }
 */
exports.sendFcmQueueNotification = onDocumentCreated(
  'fcm_queue/{queueId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const queueId = event.params.queueId;
    const doc = snap.data();

    const token = (doc.token || '').toString().trim();
    if (!token) {
      logger.warn(`[fcm_queue/${queueId}] No token on document — skipping.`);
      await snap.ref.update({
        sent: false,
        error: 'missing_token',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    // FCM `data` payload values must ALL be strings.
    const rawData = doc.data && typeof doc.data === 'object' ? doc.data : {};
    const stringData = {};
    for (const [k, v] of Object.entries(rawData)) {
      stringData[k] = v === null || v === undefined ? '' : String(v);
    }
    // Always guarantee these two, since notification_router.dart on the
    // client uses them to decide where to navigate on tap.
    stringData.type = stringData.type || (doc.type || '').toString();
    stringData.orderId = stringData.orderId || (doc.orderId || '').toString();

    const title = (doc.title || 'CallMe').toString();
    const body = (doc.body || '').toString();

    const message = {
      token,

      // ── Intentionally DATA-ONLY for Android ──────────────────
      // Your Dart firebaseMessagingBackgroundHandler() /
      // NotificationService already build the actual on-screen
      // notification themselves (custom channel `callme_high_v7`,
      // custom sound, custom vibration pattern). If we ALSO sent a
      // top-level `notification` block, Android would show its own
      // generic tray notification in addition to — or instead of —
      // your custom one, and you'd lose the custom sound/vibration.
      // Data-only + high priority is what makes your existing
      // Dart-side notification code actually run in the background.
      data: stringData,

      android: {
        priority: 'high',
      },

      // ── iOS needs an actual alert block ──────────────────────
      // Flutter's background isolate is not reliably invoked on iOS
      // the way it is on Android, so iOS pop-ups need to come
      // straight from APNs itself rather than from Dart code.
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1,
            'content-available': 1,
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      await snap.ref.update({
        sent: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      logger.info(`[fcm_queue/${queueId}] Sent OK -> receiverId=${doc.receiverId || ''}`);
    } catch (err) {
      logger.error(`[fcm_queue/${queueId}] Send failed: ${err.code} — ${err.message}`);

      await snap.ref.update({
        sent: false,
        error: err.code || err.message || 'unknown_error',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Stale/invalid token → clean it up so future orders don't keep
      // trying (and failing) to notify this same dead token.
      const staleTokenCodes = new Set([
        'messaging/registration-token-not-registered',
        'messaging/invalid-registration-token',
        'messaging/invalid-argument',
      ]);
      if (staleTokenCodes.has(err.code)) {
        await _clearStaleToken(doc.receiverId, doc.providerId);
      }
    }
  }
);

/**
 * Removes a dead fcmToken from wherever it lives — users/{email} for
 * customers, providers/{providerId} for providers — mirroring exactly
 * how your Dart _writeToken()/clearTokenOnLogout() already store it,
 * just from the server side.
 */
async function _clearStaleToken(receiverId, providerId) {
  try {
    if (providerId) {
      await db.collection('providers').doc(providerId).update({
        fcmToken: admin.firestore.FieldValue.delete(),
      });
      logger.info(`Cleared stale token on providers/${providerId}`);
      return;
    }
    if (receiverId) {
      // Your users collection is keyed by email in _writeToken(), but
      // fall back to a userId-field query in case some docs are keyed
      // differently.
      const byId = await db.collection('users').doc(receiverId).get();
      if (byId.exists) {
        await byId.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
        logger.info(`Cleared stale token on users/${receiverId}`);
        return;
      }
      const q = await db
        .collection('users')
        .where('uid', '==', receiverId)
        .limit(1)
        .get();
      if (!q.empty) {
        await q.docs[0].ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
        logger.info(`Cleared stale token on users/${q.docs[0].id}`);
      }
    }
  } catch (e) {
    logger.error(`_clearStaleToken error: ${e.message}`);
  }
}