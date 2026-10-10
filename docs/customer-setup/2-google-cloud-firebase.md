# 2. Google Cloud and Firebase

Firebase is your app's backend: user accounts, data, files, and
notifications. It runs in a Google Cloud project that you own and pay for.

- **Part 1** is for everyone.
- Then do **Part 2A** (we do the setup) **or Part 2B** (you do the setup).
- **Part 3** is for Option B only, after the app's first store release.

You need the values we sent you: the **App ID**, the **Firebase project ID**,
and the **data location**.

## Part 1: Billing and project (everyone, about 20 minutes)

### Step 1: Create a billing account

1. Sign in to <https://console.cloud.google.com> with your company Google
   account. If your company uses Google Workspace or a Google Cloud
   organization, use an account in it.
2. Open **Billing** (menu ☰ → Billing) and click **Create account** (or
   **Add billing account**).
3. Enter your company details and payment method, and finish.
4. In **Billing → Budgets & alerts**, click **Create budget**, choose an
   amount, and keep the default email alerts. This warns you if costs grow
   unexpectedly.

### Step 2: Create the Firebase project

1. Go to <https://console.firebase.google.com> and click **Create a project**
   (or **Add project**).
2. Enter the project name. Below the name, Firebase shows the **project ID**.
   Click it to edit it, and make it exactly the Firebase project ID we gave
   you, for example `acme-prod`. It cannot be changed later.
3. If your company has a Google Cloud organization, choose it as the parent.
4. Turn **Google Analytics off**. The app does not use it.
5. Click **Create project**.

### Step 3: Switch to the Blaze plan

The app's backend functions need the pay-as-you-go **Blaze** plan. Small apps
usually stay within the free allowance.

1. In the Firebase console, at the bottom left, click the plan name
   (**Spark**), then **Upgrade**.
2. Choose **Blaze** and select the billing account from Step 1.

## Part 2A: Give us access (about 10 minutes)

1. Go to <https://console.cloud.google.com>, and at the top, select the
   project from Part 1.
2. Open **IAM & Admin → IAM** and click **Grant access**.
3. In **New principals**, enter our team's email address.
4. Add these four roles (click **Add another role** for each):
   - **Firebase Admin**: to set up and run Firebase. We keep this one.
   - **Project IAM Admin**, **Service Account Admin**, and **Service Account
     Key Admin**: only to create the deploy account during setup. We tell you
     when to remove them, right after the first release.
5. Click **Save**.

That is all. We do the rest of the setup in your project, and paste every
key we create straight into your Codemagic team.

## Part 2B: Do the setup yourself (about 1 hour)

### Step 1: Sign-in methods

1. In the Firebase console, open **Build → Authentication** and click **Get
   started**.
2. In **Sign-in method**, choose **Email/Password**, switch **Enable** on,
   and click **Save**.
3. Only if we told you that your app uses phone verification: choose
   **Phone**, enable it, and click **Save**.

### Step 2: Database

1. Open **Build → Firestore Database** and click **Create database**.
2. If asked for an edition, choose **Standard**.
3. For **Location**, choose exactly the data location we gave you. **It
   cannot be changed later.**
4. Choose **Start in production mode** and click **Create**.

### Step 3: File storage

1. Open **Build → Storage** and click **Get started**.
2. Choose the same location as the database, then **Start in production
   mode**, and click **Done** (or **Create**).

### Step 4: Register the Android app

1. Open **Project overview** (the house icon) and click **Add app**, then the
   **Android** icon.
2. In **Android package name**, enter the **App ID** exactly. Enter the app
   name as the nickname. Leave the SHA-1 field empty.
3. Click **Register app**, then **Download google-services.json**.
4. Click **Next** until the end. You can skip the SDK instructions.

### Step 5: Register the iOS app

1. In **Project overview**, click **Add app**, then the **iOS** icon.
2. In **Apple bundle ID**, enter the same **App ID** exactly. Enter the app
   name as the nickname.
3. Click **Register app**, then **Download GoogleService-Info.plist**.
4. Click **Next** until the end.

These two files are not secret: they ship inside the app. You send them to
us.

### Step 6: Update policy

1. Open **Run → Remote Config** and click **Create configuration**.
2. Add a parameter named `minimum_app_version`, type **String**, default
   value `0.0.0`, and save it.
3. Click **Publish changes**.

We send you the two store links to add (`android_store_url` and
`ios_store_url`) once the store listings exist.

### Step 7: Create the deploy account and its key

This key lets Codemagic install the backend in your project. It is a
**secret**.

1. Go to <https://console.cloud.google.com> and select your project.
2. Open **IAM & Admin → Service Accounts** and click **Create service
   account**.
3. Name it `codemagic-deploy` and click **Create and continue**.
4. Add these four roles, then click **Done**:
   - **Firebase Admin**
   - **Cloud Functions Admin**
   - **Service Account User**
   - **Artifact Registry Administrator**
5. Click the new service account, open the **Keys** tab, then **Add key →
   Create new key → JSON → Create**. A file downloads.
6. Paste the whole file content into Codemagic: group `firebase_deploy`,
   variable `FIREBASE_SERVICE_ACCOUNT`, Secret on (see
   [How to paste a secret](1-codemagic.md#how-to-paste-a-secret-into-codemagic)).
7. Delete the downloaded file.

If step 5 says that **service account key creation is disabled**, your
organization blocks keys by default. Your Google Cloud organization
administrator can allow it for this project only: **IAM & Admin →
Organization Policies → Disable service account key creation
(`iam.disableServiceAccountKeyCreation`) → Manage policy → Override parent's
policy → Not enforced** for this project.

### Send us (Option B)

- [ ] `google-services.json` and `GoogleService-Info.plist`
- [ ] Screenshots of: the Authentication sign-in methods, the Firestore
      location, the plan (Blaze), and the four roles of `codemagic-deploy`

## Send us (Option A)

- [ ] Confirmation that the four roles are granted to our team's email

## Check

- [ ] The project ID is exactly the one we gave you
- [ ] The project is on the Blaze plan, with a budget alert
- [ ] Option A: our email has the four roles in IAM
- [ ] Option B: Steps 1–7 done; the deploy key is in Codemagic and the file is
      deleted

## Part 3: After the first store release (Option B only)

We tell you when to do this. It needs information that exists only after the
app is in the stores.

1. **Android fingerprints** (needed for phone sign-in and app protection): in
   Google Play Console, open your app, then **Test and release → App
   integrity → App signing**. Copy the **SHA-1** and **SHA-256** of the
   **App signing key certificate**. In the Firebase console, open **Project
   settings → General**, select the Android app, click **Add fingerprint**,
   and paste each one.
2. **App Check** (protects your backend from fake apps): open **Build → App
   Check → Apps**.
   - Android app: choose **Play Integrity**, paste the SHA-256 from above,
     and save.
   - iOS app: choose **App Attest**, enter your Apple **Team ID**, and save.
   - **Do not click Enforce** on any product. We tell you when.
3. **Store links**: in **Run → Remote Config**, add the parameters
   `android_store_url` and `ios_store_url` with the links we send you, and
   publish.
