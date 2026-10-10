const fs = require("node:fs");
const path = require("node:path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  addDoc,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} = require("firebase/firestore");
const { ref, uploadBytes } = require("firebase/storage");
const { after, before, test } = require("node:test");

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-skeleton",
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8"),
    },
    storage: {
      rules: fs.readFileSync(path.join(__dirname, "../../storage.rules"), "utf8"),
    },
  });
});

after(async () => {
  await environment?.cleanup();
});

test("Firestore documents are owner-scoped", async () => {
  const owner = environment.authenticatedContext("owner").firestore();
  const otherUser = environment.authenticatedContext("other").firestore();
  const ownProfile = doc(owner, "users/owner");
  const otherProfile = doc(otherUser, "users/owner");

  await assertSucceeds(setDoc(ownProfile, { name: "Owner" }));
  await assertSucceeds(getDoc(ownProfile));
  await assertFails(getDoc(otherProfile));
  await assertFails(setDoc(otherProfile, { name: "Intruder" }));
});

test("Profile writes are limited to app-owned fields", async () => {
  const owner = environment.authenticatedContext("owner").firestore();
  const profile = doc(owner, "users/owner");

  await assertSucceeds(
    setDoc(profile, {
      name: "Owner",
      email: "owner@example.com",
      notificationsEnabled: true,
      photoStoragePath: "users/owner/profile/avatar_1.jpg",
    }),
  );
  await assertSucceeds(setDoc(profile, { email: null }, { merge: true }));
  await assertSucceeds(updateDoc(profile, { photoStoragePath: deleteField() }));

  await assertFails(setDoc(profile, { role: "admin" }, { merge: true }));
  await assertFails(setDoc(profile, { notificationsEnabled: "yes" }, { merge: true }));
  await assertFails(
    setDoc(
      profile,
      { photoStoragePath: "users/other/profile/avatar_1.jpg" },
      { merge: true },
    ),
  );
  await assertFails(deleteDoc(profile));
});

test("Profile updates keep legacy fields written by older releases", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users/legacy"), {
      name: "Legacy",
      legacyField: "kept",
    });
  });
  const legacy = environment.authenticatedContext("legacy").firestore();

  await assertSucceeds(
    setDoc(doc(legacy, "users/legacy"), { name: "Renamed" }, { merge: true }),
  );
});

test("Clients cannot create inbox records but can mark them read", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users/owner/notifications/n1"), {
      type: "password_changed",
      isRead: false,
    });
  });
  const owner = environment.authenticatedContext("owner").firestore();

  await assertFails(
    addDoc(collection(owner, "users/owner/notifications"), {
      type: "password_changed",
      createdAt: serverTimestamp(),
      isRead: false,
    }),
  );
  await assertSucceeds(
    updateDoc(doc(owner, "users/owner/notifications/n1"), {
      isRead: true,
      readAt: serverTimestamp(),
    }),
  );
});

test("Storage allows a bounded image only for its owner", async () => {
  const owner = environment.authenticatedContext("owner").storage();
  const otherUser = environment.authenticatedContext("other").storage();
  const image = new Uint8Array([1, 2, 3, 4]);
  const metadata = { contentType: "image/jpeg" };

  await assertSucceeds(
    uploadBytes(
      ref(owner, "users/owner/profile/avatar_123456.jpg"),
      image,
      metadata,
    ),
  );
  await assertFails(
    uploadBytes(
      ref(otherUser, "users/owner/profile/avatar_123456.jpg"),
      image,
      metadata,
    ),
  );
  await assertFails(
    uploadBytes(
      ref(owner, "users/owner/profile/avatar_123456.jpg"),
      image,
      { contentType: "text/plain" },
    ),
  );
  await assertFails(
    uploadBytes(
      ref(owner, "users/owner/unrelated/file.jpg"),
      image,
      metadata,
    ),
  );
  await assertFails(
    uploadBytes(
      ref(owner, "users/owner/profile/avatar_too_large.jpg"),
      new Uint8Array(5 * 1024 * 1024 + 1),
      metadata,
    ),
  );
});
