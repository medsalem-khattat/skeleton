# 4. Google Play

Your Android app is published under your company's Google Play developer
account.

- **Part 1** is for everyone. Start it early: Google verifies your
  organization, which can take several days.
- Then do **Part 2A** (we do the setup) **or Part 2B** (you do the setup).
- **Part 3** is for everyone, when the first build is ready.

## Part 1: Developer account (everyone)

1. Go to <https://play.google.com/console/signup> and sign in with your
   company Google account.
2. Choose an **organization** account. **Do not create a personal account**:
   a new personal account must run a test with at least 12 testers for 14
   days before it can publish.
3. Enter your company details and D-U-N-S number (see the
   [Apple guide](3-apple.md#step-1-get-a-d-u-n-s-number)), and pay the
   one-time registration fee.
4. Finish every identity verification step that Google asks for. Wait until
   Play Console no longer shows a verification message.

## Part 2A: Give us access (about 5 minutes)

1. In <https://play.google.com/console>, open **Users and permissions** and
   click **Invite new users**.
2. Enter our team's email address.
3. In **Account permissions**, choose **Admin (all permissions)**, and click
   **Invite user**.

That is all. We create the app, the store listing (with texts and answers you
confirm), and the Codemagic access. Creating that access needs the Google
Cloud roles from [guide 2, Option A](2-google-cloud-firebase.md#part-2a-give-us-access-about-10-minutes).
If you chose Option B there, do Steps 3 and 4 of Part 2B below yourself.

## Part 2B: Do the setup yourself (about 1–2 hours)

### Step 1: Create the app

1. In Play Console, on **Home**, click **Create app**.
2. Enter the app name and default language, choose **App** and **Free**,
   accept the declarations, and click **Create app**.

### Step 2: Complete the app's setup tasks

On the app's **Dashboard**, open **Set up your app** and complete every task.
We send you the texts and answers for the modules your app uses:

- **Privacy policy**: your public privacy policy link.
- **App access**: choose that parts of the app need a login, and enter the
  test account we give you, so Google can review the app.
- **Ads**: No.
- **Content rating**, **Target audience**, **Data safety**: the answers we
  prepared, checked by you.
- **Store listing**: short and full description, app icon 512×512, feature
  graphic 1024×500, and phone screenshots. We can produce the images.

### Step 3: Create the publishing account and its key

This key lets Codemagic upload builds to Play Console. It is a **secret**.

1. Go to <https://console.cloud.google.com> and select your Firebase project
   (see [guide 2](2-google-cloud-firebase.md)).
2. Open **APIs & Services → Library**, search for **Google Play Android
   Developer API**, open it, and click **Enable**.
3. Open **IAM & Admin → Service Accounts** and click **Create service
   account**. Name it `codemagic-play`, click **Create and continue**, add
   **no** role, and click **Done**.
4. Copy the service account's email address
   (`codemagic-play@<project>.iam.gserviceaccount.com`).
5. Click it, open **Keys**, then **Add key → Create new key → JSON →
   Create**. A file downloads.
6. Paste the whole file content into Codemagic: group `google_play`, variable
   `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`, Secret on (see
   [How to paste a secret](1-codemagic.md#how-to-paste-a-secret-into-codemagic)).
7. Delete the downloaded file.

If key creation is blocked, see the note at the end of
[guide 2, Step 7](2-google-cloud-firebase.md#step-7-create-the-deploy-account-and-its-key).

### Step 4: Allow the publishing account in Play Console

1. In Play Console, open **Users and permissions** and click **Invite new
   users**.
2. Paste the service account email from Step 3.
3. Open **App permissions**, click **Add app**, select your app, and tick:
   - **Release to production, exclude devices, and use Play App Signing**
   - **Release apps to testing tracks**
   - **Manage testing tracks and edit tester lists**
4. Click **Apply**, then **Invite user**.

### Step 5: Create the upload key

Every Android build is signed with this key before it is uploaded. It is a
**secret**. If it is ever lost, Google can replace it (Play Console → App
integrity → **Request upload key reset**), because Google keeps the real app
signing key.

1. You need Java installed (it comes with Android Studio). Open a terminal
   and run:

   ```
   keytool -genkeypair -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Choose a strong password when asked, and answer the questions with your
   company's details.
3. Upload `upload.jks` to Codemagic with the password and the alias `upload`,
   with reference name `upload_keystore` (see
   [How to upload the Android keystore](1-codemagic.md#how-to-upload-the-android-keystore)).
4. Keep the file and its password in your company's password manager, then
   delete the file from your computer.

If you cannot run the command, choose Option A for this step only: we do it
in a short call while you watch.

### Send us (Option B)

- [ ] The `codemagic-play` service account email
- [ ] Screenshots of: the app's Dashboard with all setup tasks done, and the
      service account's app permissions

## Part 3: First upload (everyone, about 10 minutes)

Google accepts automatic uploads only after the first build was uploaded by
hand. When we tell you the first build is ready:

1. In Codemagic, open the finished **Android release** build and download
   the `.aab` file from **Artifacts**.
2. In Play Console, open your app, then **Test and release → Testing →
   Internal testing**, and click **Create new release**.
3. If asked about **Play App Signing**, keep Google's recommended option and
   continue.
4. Upload the `.aab` file, click **Next**, then **Save**.

With Option A, we do this part for you.

## Send us (Option A)

- [ ] Confirmation that the invitation is sent

## Check

- [ ] Organization account verified
- [ ] Option A: we appear in Users and permissions as Admin
- [ ] Option B: Steps 1–5 done; no key file was sent to anyone
- [ ] First upload done (Part 3)
