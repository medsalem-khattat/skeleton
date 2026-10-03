import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

initializeApp();

const invalidTokenCodes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

export const sendInboxPush = onDocumentCreated(
  {
    document: "users/{userId}/notifications/{notificationId}",
    region: "us-central1",
  },
  async (event) => {
    const notification = event.data?.data();
    if (notification?.type !== "password_changed") return;

    const { userId, notificationId } = event.params;
    const user = await getFirestore().collection("users").doc(userId).get();
    if (user.data()?.notificationsEnabled === false) return;

    const tokenSnapshot = await getFirestore()
      .collection("users")
      .doc(userId)
      .collection("fcmTokens")
      .get();
    const tokenDocuments = tokenSnapshot.docs.filter(
      (document) => document.id.length > 0 && !document.id.includes("/"),
    );

    for (let start = 0; start < tokenDocuments.length; start += 500) {
      const batch = tokenDocuments.slice(start, start + 500);
      const message: MulticastMessage = {
        tokens: batch.map((document) => document.id),
        notification: {
          title: "Password changed",
          body: "Your account password was changed successfully.",
        },
        data: { notificationId },
        android: {
          priority: "high",
          notification: {
            channelId: "push_notifications",
            sound: "default",
          },
        },
        apns: {
          headers: { "apns-priority": "10" },
          payload: { aps: { sound: "default" } },
        },
      };
      const result = await getMessaging().sendEachForMulticast(message);
      const staleTokens = batch.filter((_, index) => {
        const response = result.responses[index];
        return (
          !response.success &&
          invalidTokenCodes.has(response.error?.code ?? "")
        );
      });

      if (staleTokens.length > 0) {
        const writes = getFirestore().batch();
        staleTokens.forEach((document) => writes.delete(document.ref));
        await writes.commit();
      }

      const failures = result.responses
        .filter((response) => !response.success)
        .map((response) => response.error?.code ?? "unknown");
      if (failures.length > 0) {
        logger.error("Some notification pushes could not be sent.", {
          notificationId,
          failureCount: failures.length,
          errorCodes: failures,
        });
      }
    }
  },
);
