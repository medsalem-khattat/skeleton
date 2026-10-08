import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import * as functionsV1 from "firebase-functions/v1";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { requireRecentAuthentication } from "./auth";
import {
  buildPasswordChangedMessage,
  normalizeLanguage,
  staleTokenIndexes,
} from "./push";

initializeApp();

const region = "us-central1";

/** Removes the user's Firestore subtree and profile photos. Idempotent. */
async function deleteUserData(uid: string): Promise<void> {
  await Promise.all([
    getFirestore().recursiveDelete(getFirestore().collection("users").doc(uid)),
    getStorage().bucket().deleteFiles({ prefix: `users/${uid}/profile/` }),
  ]);
}

export const deleteAccount = onCall(
  {
    region,
    timeoutSeconds: 300,
    enforceAppCheck: true,
  },
  async (request) => {
    const uid = requireRecentAuthentication(request);
    try {
      await deleteUserData(uid);
      await getAuth().deleteUser(uid);
    } catch (error) {
      if ((error as { code?: string }).code === "auth/user-not-found") return;
      logger.error("Account deletion failed.", { uid, error });
      throw new HttpsError(
        "internal",
        "Account deletion could not be completed.",
      );
    }
  },
);

/**
 * Removes leftover data when an Auth user is deleted outside the app, for
 * example from the Firebase console, so no orphaned personal data remains.
 */
export const cleanupDeletedUser = functionsV1
  .region(region)
  .auth.user()
  .onDelete(async (user) => {
    await deleteUserData(user.uid);
  });

export const revokeAllSessions = onCall(
  {
    region,
    timeoutSeconds: 300,
    enforceAppCheck: true,
  },
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

/**
 * Writes the password-change inbox record. Clients cannot create inbox
 * records; they call this right after reauthenticating and changing the
 * password, so a recent sign-in is required.
 */
export const recordPasswordChange = onCall(
  {
    region,
    enforceAppCheck: true,
  },
  async (request) => {
    const uid = requireRecentAuthentication(request);
    const data = request.data as { languageCode?: unknown } | undefined;
    await getFirestore()
      .collection("users")
      .doc(uid)
      .collection("notifications")
      .add({
        type: "password_changed",
        createdAt: FieldValue.serverTimestamp(),
        isRead: false,
        languageCode: normalizeLanguage(data?.languageCode),
      });
  },
);

export const sendInboxPush = onDocumentCreated(
  {
    document: "users/{userId}/notifications/{notificationId}",
    region,
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
    const language = normalizeLanguage(notification.languageCode);

    for (let start = 0; start < tokenDocuments.length; start += 500) {
      const batch = tokenDocuments.slice(start, start + 500);
      const result = await getMessaging().sendEachForMulticast(
        buildPasswordChangedMessage(
          batch.map((document) => document.id),
          notificationId,
          language,
        ),
      );

      const staleTokens = staleTokenIndexes(result.responses).map(
        (index) => batch[index],
      );
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
