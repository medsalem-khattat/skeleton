# 6. First Release

You now have every account and secret in place. This guide checks them,
installs the backend, builds both apps, and takes them to your testers, then
to the stores. About 1.5 hours, most of it waiting for builds.

## How to start a workflow in Codemagic

Every step below starts a **workflow**:

1. In Codemagic, open your app and click **Start new build**.
2. Open the **Tags** tab and choose the release tag we announced (for
   example `v1.1.0`). **Always a tag, never a branch**: a build from a branch
   stops at **Check release tag**.
3. Choose the workflow named in the step, and click **Start new build**.
4. When it finishes, Codemagic emails `CM_PUBLISH_EMAIL`. A failed step shows
   its log: look for the first red line, then in the [FAQ](FAQ.md).

## Step 1: Readiness check (5 minutes)

Start the workflow **Readiness check**. It changes nothing: it proves that
your deployment repository and every secret work, without showing them.
In the step **Check customer accounts and secrets**, every line starts with:

- **OK**: fine.
- **FAIL**: to fix; the line names the guide and step. Fix it and run the
  check again.
- **WAIT**: expected now. "Google Play access not confirmed" stays WAIT until
  the first Android upload (Step 3).

Go on only when there is no **FAIL**.

## Step 2: Backend (about 10 minutes)

Start **Backend deploy**. It checks the deployment, runs the backend tests,
and installs the backend functions and security rules in your Firebase
project. Always deploy the backend before the apps.

## Step 3: Android (about 20 minutes)

1. Start **Android release**. It builds the app and uploads it to Play's
   internal testing track.
2. **The very first time only**, the last step (publishing) fails: Google
   accepts automatic uploads only after one manual upload. Then:
   1. In the finished build, open **Artifacts** and download the `.aab` file.
   2. In Play Console, open your app, then **Test and release → Testing →
      Internal testing**, and click **Create new release**.
   3. If asked about **Play App Signing**, keep Google's recommended option.
   4. Upload the `.aab`, click **Next**, then **Save**, then **Review release**
      and **Start rollout to Internal testing**. If Play Console asks you to
      finish setup tasks first, complete those it lists
      ([guide 5, Step 3](5-google-play.md#step-3-complete-the-apps-setup-tasks)).
3. From the second build on, uploads are automatic.
4. Your testers get an invitation link in **Internal testing → Testers**.

## Step 4: iOS (about 30 minutes)

1. Start **iOS release**. The first run also creates your signing certificate
   and profile. It uploads the app to TestFlight.
2. Apple then processes the build for 10–30 minutes. In App Store Connect →
   **TestFlight**, the build appears; if it asks about **export compliance**,
   answer that the app uses only standard encryption (HTTPS).
3. Add the build to your internal testing group. Testers receive it in the
   **TestFlight** app.

Steps 3 and 4 can run at the same time.

## Step 5: After the first release

1. **Android fingerprints** (needed for phone verification and app
   protection): in Play Console, open **Test and release → App integrity →
   App signing**, and copy the **SHA-1** and **SHA-256** of the **App signing
   key certificate**. In Firebase → **Project settings → General**, select
   the Android app, click **Add fingerprint**, and paste each one.
2. **App Check** (protects your backend from fake apps): in Firebase, open
   **Build → App Check → Apps**.
   - Android: choose **Play Integrity**, paste the SHA-256, and save.
   - iOS: choose **App Attest**, enter your Team ID, and save.
   - Leave **Enforce** off until your testers have used the store builds for
     a few days with no App Check errors in the Firebase console.

## Step 6: Test the app (about 15 minutes)

On one Android phone and one iPhone, installed from the testing tracks:

- [ ] Create an account; the verification email arrives, and its link opens
      the app
- [ ] Sign out and sign in again; reset a forgotten password
- [ ] Change your name and photo (if `profile` is on)
- [ ] Change your password: a notification arrives (if notifications are on)
- [ ] Settings: theme, language, app lock (if on)
- [ ] Export your data, then delete the test account

## Step 7: Publish to the stores

When the tests pass and the store setup tasks are done:

- **Google Play:** in **Internal testing**, open the release and click
  **Promote release → Production**. Choose a staged rollout (for example
  20%), and send it for review. Google's review takes from hours to a few
  days.
- **App Store:** in App Store Connect, open your app, fill in the version
  page (screenshots, description, keywords, support URL), **App Privacy**,
  and **App Review Information** with a test account. Select the build, and
  click **Add for Review**, then **Submit**. Apple's review usually takes 1–3
  days.

## Step 8: Tell us

Email us the version you published and the date. We use it to send you the
right release and end-of-support notices.

## Check

- [ ] Readiness check without FAIL
- [ ] Backend deployed
- [ ] Android and iOS builds installed by testers, and the Step 6 tests pass
- [ ] Fingerprints and App Check registered
- [ ] Apps submitted to the stores
