const assert = require("node:assert/strict");
const { test } = require("node:test");

const { requireRecentAuthentication } = require("../lib/auth");
const {
  buildPasswordChangedMessage,
  normalizeLanguage,
  staleTokenIndexes,
} = require("../lib/push");

const now = 1_800_000_000;
const signedIn = (authTime) => ({
  auth: { uid: "owner", token: { auth_time: authTime } },
});

test("recent authentication returns the caller's uid", () => {
  assert.equal(requireRecentAuthentication(signedIn(now - 60), now), "owner");
});

test("recent authentication rejects missing, stale, and future sign-ins", () => {
  assert.throws(
    () => requireRecentAuthentication({ auth: undefined }, now),
    { code: "unauthenticated" },
  );
  for (const authTime of [now - 301, now + 10, "recent", undefined]) {
    assert.throws(
      () => requireRecentAuthentication(signedIn(authTime), now),
      { code: "failed-precondition" },
    );
  }
});

test("push language falls back to English for unsupported values", () => {
  assert.equal(normalizeLanguage("fr"), "fr");
  assert.equal(normalizeLanguage("en"), "en");
  assert.equal(normalizeLanguage("de"), "en");
  assert.equal(normalizeLanguage(undefined), "en");
  assert.equal(normalizeLanguage({ toString: () => "fr" }), "en");
});

test("password-change push uses the recorded language", () => {
  const french = buildPasswordChangedMessage(["t1", "t2"], "n1", "fr");
  assert.deepEqual(french.tokens, ["t1", "t2"]);
  assert.equal(french.notification.title, "Mot de passe modifié");
  assert.deepEqual(french.data, { notificationId: "n1" });
  assert.equal(french.android.notification.channelId, "push_notifications");

  const english = buildPasswordChangedMessage(["t1"], "n1", "en");
  assert.equal(english.notification.title, "Password changed");
});

test("only invalid-token failures are treated as stale", () => {
  assert.deepEqual(
    staleTokenIndexes([
      { success: true },
      { success: false, error: { code: "messaging/registration-token-not-registered" } },
      { success: false, error: { code: "messaging/internal-error" } },
      { success: false, error: { code: "messaging/invalid-registration-token" } },
    ]),
    [1, 3],
  );
});
