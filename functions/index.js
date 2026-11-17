const {setGlobalOptions} = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
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

/**
 * Marks a coupon as used once the food order that used it is paid.
 *
 * Runs when an order with a `userCouponId`:
 *   - changes to status "paid" (real Razorpay mode), or
 *   - is created with paymentMode "test" (the app's dummy payment
 *     mode, where orders are never marked "paid").
 *
 * In one transaction it updates `user_coupons/{userCouponId}`:
 *   usesLeft - 1, status "used" when usesLeft reaches 0, usedAt, orderId
 * and sets `couponRedeemed: true` on the order so it can never be
 * counted twice (functions can retry, and this function's own write
 * to the order triggers it again).
 *
 * If the coupon is missing, belongs to someone else, or has no uses
 * left, the coupon is NOT touched and `couponError` is written on the
 * order instead, so the admin can see it.
 */
exports.redeemCouponOnOrderPaid = onDocumentWritten(
    "orders/{orderId}",
    async (event) => {
      const before = event.data.before.exists ?
        event.data.before.data() : null;
      const after = event.data.after.exists ?
        event.data.after.data() : null;

      if (!after || !after.userCouponId) return;
      if (after.couponRedeemed === true || after.couponError) return;

      const becamePaid = after.status === "paid" &&
        (!before || before.status !== "paid");
      const testModeCreated = !before && after.paymentMode === "test";
      if (!becamePaid && !testModeCreated) return;

      const db = getFirestore();
      const orderRef = event.data.after.ref;
      const couponRef = db.collection("user_coupons")
          .doc(after.userCouponId);

      try {
        const result = await db.runTransaction(async (tx) => {
          const orderSnap = await tx.get(orderRef);
          const couponSnap = await tx.get(couponRef);

          if (!orderSnap.exists) return "order_missing";
          const order = orderSnap.data();
          if (order.couponRedeemed === true) return "already_redeemed";

          const fail = (code) => {
            tx.update(orderRef, {couponError: code});
            return code;
          };

          if (!couponSnap.exists) return fail("coupon_not_found");
          const coupon = couponSnap.data();

          // The app already marked this coupon used for this order (free
          // plan flow in FoodMenuController) — never count it twice.
          if (coupon.orderId === orderRef.id) {
            return "already_redeemed_by_app";
          }

          if (coupon.userId !== order.userId) {
            return fail("coupon_not_owned_by_user");
          }

          const usesLeft = typeof coupon.usesLeft === "number" ?
            coupon.usesLeft : Number(coupon.usesLeft) || 0;
          if (coupon.status === "used" || usesLeft <= 0) {
            return fail("coupon_already_used");
          }

          const newUsesLeft = usesLeft - 1;
          tx.update(couponRef, {
            usesLeft: newUsesLeft,
            status: newUsesLeft <= 0 ? "used" : "assigned",
            usedAt: FieldValue.serverTimestamp(),
            orderId: orderRef.id,
          });
          tx.update(orderRef, {
            couponRedeemed: true,
            couponRedeemedAt: FieldValue.serverTimestamp(),
          });
          return "redeemed";
        });

        logger.info(
            `Coupon ${after.userCouponId} on order ${orderRef.id}: ${result}`,
        );
      } catch (err) {
        logger.error(
            `Failed to redeem coupon ${after.userCouponId} ` +
            `for order ${orderRef.id}`,
            err,
        );
        throw err; // let Cloud Functions retry if retries are enabled
      }
    },
);
