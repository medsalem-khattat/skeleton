import type { MulticastMessage } from "firebase-admin/messaging";

export type PushLanguage = "en" | "fr";

/** Keep in sync with passwordChangedNotification* in frontend/lib/l10n. */
const passwordChangedText: Record<
  PushLanguage,
  { title: string; body: string }
> = {
  en: {
    title: "Password changed",
    body: "Your account password was changed successfully.",
  },
  fr: {
    title: "Mot de passe modifié",
    body: "Le mot de passe de votre compte a été modifié.",
  },
};

const invalidTokenCodes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

/** Maps any client-supplied value to a supported language, English by default. */
export function normalizeLanguage(value: unknown): PushLanguage {
  return value === "fr" ? "fr" : "en";
}

export function buildPasswordChangedMessage(
  tokens: string[],
  notificationId: string,
  language: PushLanguage,
): MulticastMessage {
  return {
    tokens,
    notification: passwordChangedText[language],
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
}

/** Indexes of sends that failed because the token is no longer valid. */
export function staleTokenIndexes(
  responses: { success: boolean; error?: { code: string } }[],
): number[] {
  return responses.flatMap((response, index) =>
    !response.success && invalidTokenCodes.has(response.error?.code ?? "")
      ? [index]
      : [],
  );
}
