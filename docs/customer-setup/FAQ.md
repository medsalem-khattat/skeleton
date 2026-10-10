# Frequently Asked Questions

Questions from technical teams deploying the app for the first time, by
topic. If yours is not here, write to us with the guide and step number and
the error message (see [Getting help](README.md#getting-help)).

## General

### Do you have access to our accounts?

No. Every account is yours, and we never ask for access to it. We provide the
source code, the releases, these guides, and answers to your questions.

### Can we change the app's code?

No. Your app is configured, not modified: everything specific to you is in
your `deployment.json`. If you need something it cannot express, ask us: if
it is accepted, it becomes an option of the product in a future version.

### What will it cost?

Your accounts are billed to you directly: the Apple Developer Program (yearly
fee), Google Play (one-time fee), Codemagic (build minutes; iOS builds use
macOS minutes), and Google Cloud/Firebase (pay-as-you-go; small apps usually
stay within the free allowance, SMS for phone verification is billed per
message). Set a budget alert ([guide 3, Step 1](3-google-cloud-firebase.md#step-1-billing-account)).

### What do these words mean?

| Word | Meaning |
| --- | --- |
| App ID | Your app's unique name in the stores, like `com.acme.field`. Permanent |
| Firebase | Google's backend service: accounts, database, files, notifications |
| Blaze | Firebase's pay-as-you-go plan, needed for the backend |
| Service account | A Google account for a program instead of a person, such as Codemagic |
| Deploy key | A key that lets a program read one Git repository, and nothing else |
| Keystore | The file holding the key that signs Android builds |
| APNs | Apple's push notification service |
| TestFlight / Internal testing | Apple's and Google's test channels, before the public store |
| Tag | A fixed, named version of the source code, like `v1.2.0` |
| Workflow | One automated job in Codemagic, such as **Android release** |

### A secret was sent by mistake: what now?

Replace it right away, as described in
[guide 7](7-upgrades-and-changes.md#a-secret-replacement), and delete the
message that contained it. If you sent it to us, tell us: we delete it too.

## Codemagic

### The build stops at "Check release tag"

The build was started on a branch. Start it again from the **Tags** tab, on
the announced release tag ([guide 6](6-first-release.md#how-to-start-a-workflow-in-codemagic)).

### "Deployment is not in this repository; set DEPLOYMENT_REPO"

Group `deployment` lacks `DEPLOYMENT_REPO`, or the workflow does not see the
group. Check the name and the group ([guide 2, Step 5](2-deployment-repository.md#step-5-let-codemagic-read-the-repository)).

### "Cannot clone ... check DEPLOYMENT_REPO and that its deploy key is added"

Either the URL is not the SSH URL (`git@...`), the deploy key is not added to
your deployment repository, or `DEPLOYMENT_REPO_SSH_KEY` does not hold the
matching private key. Create a new pair and repeat
[guide 2, Step 5](2-deployment-repository.md#step-5-let-codemagic-read-the-repository).

### "Deployment ... is invalid"

The log lists each problem in your `deployment.json` or Firebase files. Fix
them in your deployment repository, run `node tool/deployment.mjs check
<deployment ID>` on your computer, push, and start the build again.

### Codemagic cannot read the source code, or shows no tags

The source code key is missing or was replaced. Repeat
[guide 1, Step 3](1-codemagic.md#step-3-get-access-to-the-apps-source-code)
and send us the new public key.

### The build email does not arrive

`CM_PUBLISH_EMAIL` is missing from group `deployment`, or the email is in
spam. Without it, Codemagic can reject the workflow with `recipients -> 0 none
is not an allowed value`.

## Google Cloud and Firebase

### My billing account shows as closed

A new billing account stays closed until its payment method is accepted. Open
<https://console.cloud.google.com/billing>, select the account, and follow
the banner (**Fix** or **Reopen billing account**). Some banks need you to
confirm a small test charge. Then run `node tool/provision.mjs` again, or
link the account in the Firebase console.

### Key creation is disabled by an organization policy

Organizations created since 2024 block service account keys by default. Your
Google Cloud organization administrator can allow them for this project only:
**IAM & Admin → Organization Policies → Disable service account key creation
(`iam.disableServiceAccountKeyCreation`) → Manage policy → Override parent's
policy → Not enforced**, for this project.

### provision.mjs says "Not signed in"

Run `npx firebase login` in `backend/functions`, with your company Google
account ([guide 3, Step 2](3-google-cloud-firebase.md#step-2-sign-in-from-your-computer)).

### provision.mjs says "click Get started once in the console"

Open the link it shows, click **Get started** under Authentication, and run
the command again.

### "Storage bucket: skipped: needs Blaze"

Billing is not linked yet. Link it, then run the command again.

### "FIREBASE_SERVICE_ACCOUNT belongs to ..., not ..."

The deploy key in Codemagic comes from another Firebase project. Create the
key in the project of your `deployment.json` ([guide 3, Step 4](3-google-cloud-firebase.md#step-4-put-the-deploy-key-into-codemagic)).

### Backend deploy fails with a permission or "API not enabled" error

After the first deploy enables Google's services, they can take a few minutes
to be ready: start **Backend deploy** again. If it still fails, check the four
roles of `codemagic-deploy` (guide 3, 3B.7).

## Apple

### iOS release fails: "missing the aps-environment entitlement" or "missing applinks"

The App ID lacks **Push Notifications** or **Associated Domains**. Enable them
([guide 4, Step 4](4-apple.md#step-4-register-the-app-id)) and start the build
again: it regenerates the profile.

### iOS release fails at upload, mentioning an agreement

A new Apple agreement waits for the Account Holder
([guide 4, Step 3](4-apple.md#step-3-accept-the-agreements)).

### The app name is already taken

App Store names are unique. Add your company name, for example `Field by
Acme`, in App Store Connect; it does not change your App ID.

### iPhones receive no notifications

The APNs key is not uploaded in Firebase, or with a wrong Key ID or Team ID
([guide 4, Step 6](4-apple.md#step-6-create-the-push-notification-key)).
Notifications are not shown while the app is in the foreground on some
devices; test with the app in the background.

## Google Play

### Android release fails: "Package not found" or the app has no build

Expected on the very first build: upload the `.aab` once by hand
([guide 6, Step 3](6-first-release.md#step-3-android-about-20-minutes)).

### "Only releases with status draft may be created on draft app"

The app has never been rolled out. Roll out the first internal testing
release by hand (guide 6, Step 3), then start **Android release** again.

### "The caller does not have permission"

The `codemagic-play` service account is not invited for your app, or its
access is not active yet (up to a day). Check
[guide 5, Step 5](5-google-play.md#step-5-allow-the-publishing-key-in-play-console).

### "The Android App Bundle was signed with the wrong key"

The keystore in Codemagic is not the one Google registered for your app.
Upload the right one, or request an upload key reset in Play Console → **App
integrity**.

## The app

### Every user sees "update required"

`minimum_app_version` in Remote Config is higher than the version in the
stores. Lower it to the published version and publish; devices pick it up
within an hour.

### "Configuration check" error on the update screen

`android_store_url` or `ios_store_url` is missing or invalid while
`minimum_app_version` is above `0.0.0`. Set both links
([guide 3, 3B.6](3-google-cloud-firebase.md#3b6-update-settings)).

### Email verification links open the browser instead of the app

Normal until the app is installed from a store or testing track. If it
persists, check that `firebase.authActionHost` is `<project ID>.firebaseapp.com`
and that the App ID has **Associated Domains**.

### Phone verification fails on Android

Add the SHA-1 and SHA-256 fingerprints to Firebase
([guide 6, Step 5](6-first-release.md#step-5-after-the-first-release)).
