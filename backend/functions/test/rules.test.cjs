const fs = require("node:fs");
const path = require("node:path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc } = require("firebase/firestore");
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
