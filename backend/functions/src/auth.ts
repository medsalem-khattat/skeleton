import { CallableRequest, HttpsError } from "firebase-functions/v2/https";

export const recentAuthWindowSeconds = 5 * 60;

/** Returns the caller's uid when they signed in within the recent window. */
export function requireRecentAuthentication(
  request: Pick<CallableRequest<unknown>, "auth">,
  nowSeconds: number = Date.now() / 1000,
): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to continue.");
  }
  const authTime = request.auth.token.auth_time;
  const ageSeconds = nowSeconds - Number(authTime);
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
