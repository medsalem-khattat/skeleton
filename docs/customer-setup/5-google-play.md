# 5. Google Play

Your Android app is published under your company's Google Play developer
account. About 1 hour, plus Google's verification time.

**Start Step 1 on day one**: Google verifies your organization, which can take
several days.

## Step 1: Developer account

1. Go to <https://play.google.com/console/signup> and sign in with your
   company Google account.
2. Choose an **organization** account. **Do not create a personal account**:
   a new personal account must run a test with at least 12 testers for 14
   days before it can publish.
3. Enter your company details and D-U-N-S number
   ([guide 4, Step 1](4-apple.md#step-1-get-a-d-u-n-s-number)), and pay the
   one-time registration fee.
4. Finish every identity verification step Google asks for, and wait until
   Play Console no longer shows a verification message.

## Step 2: Create the app

1. In <https://play.google.com/console>, on **Home**, click **Create app**.
2. Enter your app name and default language, choose **App** and **Free**,
   accept the declarations, and click **Create app**.

## Step 3: Complete the app's setup tasks

On the app's **Dashboard**, open **Set up your app** and complete every task.
These are needed before the app can go to production; internal testing can
start before.

- **Privacy policy**: your public privacy policy link.
- **App access**: choose that parts of the app need a login, and give Google
  a test account (create one in your app after the first release).
- **Ads**: No.
- **Content rating**, **Target audience**, **Data safety**: answer for the
  modules you enabled. The app stores account details (name, email, phone if
  enabled), profile photos, and device push tokens in your Firebase project,
  sends crash reports if `crashReporting` is on, and lets users delete their
  account and export their data from Settings.
- **Store listing**: short and full description, app icon 512×512, feature
  graphic 1024×500, and phone screenshots (take them from the first test
  build).

## Step 4: Create the publishing key

This key lets Codemagic upload builds to Play Console. It is a **secret**.

1. Go to <https://console.cloud.google.com> and select your Firebase project.
2. Open **APIs & Services → Library**, search for **Google Play Android
   Developer API**, open it, and click **Enable**.
3. Open **IAM & Admin → Service Accounts** and click **Create service
   account**. Name it `codemagic-play`, click **Create and continue**, add
   **no** role, and click **Done**.
4. Copy its email address
   (`codemagic-play@<project ID>.iam.gserviceaccount.com`).
5. Click it, open **Keys**, then **Add key → Create new key → JSON →
   Create**. A file downloads.
6. Paste its whole content into Codemagic: group `google_play`, variable
   `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`, Secret on
   ([how to paste a secret](1-codemagic.md#how-to-paste-a-secret-into-codemagic)).
7. Delete the downloaded file.

## Step 5: Allow the publishing key in Play Console

1. In Play Console (outside the app), open **Users and permissions** and
   click **Invite new users**.
2. Paste the service account email from Step 4.
3. Open **App permissions**, click **Add app**, select your app, and tick:
   - **Release to production, exclude devices, and use Play App Signing**
   - **Release apps to testing tracks**
   - **Manage testing tracks and edit tester lists**
4. Click **Apply**, then **Invite user**.

Google can take up to a day to activate a new service account's access.

## Step 6: Create the upload key

Every Android build is signed with this key before it is uploaded. It is a
**secret**. If it is ever lost, Google can replace it (Play Console → **App
integrity → Request upload key reset**), because Google keeps the real app
signing key.

1. In a terminal (Java must be installed), run:

   ```
   keytool -genkeypair -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Choose a strong password when asked, and answer the questions with your
   company's details.
3. Upload `upload.jks` to Codemagic with its password and the alias `upload`,
   reference name `upload_keystore`
   ([how to upload the Android keystore](1-codemagic.md#how-to-upload-the-android-keystore)).
4. Keep the file and its password in your company's password manager, then
   delete the file from your computer.

## Step 7: Add your testers

1. In your app, open **Test and release → Testing → Internal testing →
   Testers**.
2. Create an email list with your testers' Google accounts, and save.

## Check

- [ ] Organization account verified
- [ ] App created; setup tasks done or planned before production
- [ ] Group `google_play` has `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`, and the
      service account is invited with the three permissions
- [ ] Keystore `upload_keystore` is in Codemagic, and backed up in your
      password manager
- [ ] Internal testers list created
