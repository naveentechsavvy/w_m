const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

setGlobalOptions({maxInstances: 10});

initializeApp();

/**
 * Fires whenever a new document is created in the `notifications`
 * collection (see NotificationDataSource.create in the Flutter app).
 * Looks up the target user's saved FCM token and sends them an
 * actual push notification — this is the piece that makes
 * notifications arrive even when the app is fully closed, since
 * writing to Firestore alone does nothing to a closed app.
 *
 * Matches the exact doc shape written by NotificationDataSource:
 *   {userId, type, title, body, createdAt, isRead, relatedId}
 */
exports.sendPushOnNotificationCreate = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
      const snap = event.data;
      if (!snap) {
        logger.warn("No data associated with the event");
        return;
      }

      const notification = snap.data();
      const {userId, title, body, type, relatedId} = notification;

      if (!userId) {
        logger.warn(
            "Notification doc has no userId, skipping push",
            {notificationId: event.params.notificationId},
        );
        return;
      }

      const db = getFirestore();
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        logger.warn(`No user doc for userId=${userId}, skipping push`);
        return;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        logger.warn(`User ${userId} has no fcmToken, skipping push`);
        return;
      }

      const message = {
        token: fcmToken,
        notification: {
          title: title || "Weekend Masti",
          body: body || "You have a new notification",
        },
        data: {
          type: type || "",
          relatedId: relatedId || "",
          notificationId: event.params.notificationId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "weekend_masti_default",
          },
        },
      };

      try {
        await getMessaging().send(message);
        logger.info(`Push sent to user ${userId}`);
      } catch (err) {
        logger.error(`Failed to send push to user ${userId}`, err);
      }
    },
);