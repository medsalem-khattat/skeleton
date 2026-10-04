import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import {
  CallableRequest,
  HttpsError,
  onCall,
} from "firebase-functions/v2/https";

initializeApp();

const invalidTokenCodes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);
const recentAuthWindowSeconds = 5 * 60;

function requireRecentAuthentication(
  request: CallableRequest<unknown>,
): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to continue.");
  }
  const authTime = request.auth.token.auth_time;
  const ageSeconds = Date.now() / 1000 - Number(authTime);
  if (
    typeof authTime !== "number" ||
    !Number.isFinite(ageSeconds) ||
    ageSeconds < 0 ||
    ageSeconds > recentAuthWindowSeconds
  ) {
    throw new HttpsError(
      "failed-precondition",
      "Recent authentication is required.",
    );
  }
  return request.auth.uid;
}

export const deleteAccount = onCall(
  { region: "us-central1", timeoutSeconds: 300 },
  async (request) => {
    const uid = requireRecentAuthentication(request);
    const userRef = getFirestore().collection("users").doc(uid);
    try {
      await getFirestore().recursiveDelete(userRef);
      await getAuth().deleteUser(uid);
    } catch (error) {
      logger.error("Account deletion failed.", { uid, error });
      throw new HttpsError(
        "internal",
        "Account deletion could not be completed.",
      );
    }
  },
);

export const revokeAllSessions = onCall(
  { region: "us-central1", timeoutSeconds: 300 },
  async (request) => {
    const uid = requireRecentAuthentication(request);
    const tokenRef = getFirestore()
      .collection("users")
      .doc(uid)
      .collection("fcmTokens");
    try {
      await getFirestore().recursiveDelete(tokenRef);
      await getAuth().revokeRefreshTokens(uid);
    } catch (error) {
      logger.error("Session revocation failed.", { uid, error });
      throw new HttpsError(
        "internal",
        "Sessions could not be revoked. Please try again.",
      );
    }
  },
);

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
