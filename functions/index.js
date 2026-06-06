
const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

admin.initializeApp();

exports.sendFcmNotification = onDocumentCreated(
  "fcm_queue/{notificationId}",
  async (event) => {
    try {
      const doc = event.data;

      if (!doc) return;

      const data = doc.data();

      if (!data?.token) {
        console.log("Token missing");
        return;
      }

      const message = {
        token: data.token,

        notification: {
          title: data.title || "CallMe",
          body: data.body || "",
        },

        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          title: String(data.title || "CallMe"),
          body: String(data.body || ""),
          type: String(data?.data?.type || ""),
          receiverId: String(data?.data?.receiverId || ""),
          orderId: String(data?.data?.orderId || ""),
          providerId: String(data?.data?.providerId || ""),
        },

        android: {
          priority: "high",

          notification: {
            channelId: "callme_high_v4",

            sound: "default",

            visibility: "public",

            defaultSound: true,

            defaultVibrateTimings: true,

            defaultLightSettings: true,

            notificationCount: 1,
          },
        },

        apns: {
          headers: {
            "apns-priority": "10",
          },

          payload: {
            aps: {
              alert: {
                title: data.title || "CallMe",
                body: data.body || "",
              },

              sound: "default",

              badge: 1,

              contentAvailable: true,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);

      await doc.ref.update({
        sent: true,
        messageId: response,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Notification sent:", response);
    } catch (e) {
      console.error("Notification error:", e);

      if (event.data) {
        await event.data.ref.update({
          sent: false,
          error: String(e),
        });
      }
    }
  }
);

