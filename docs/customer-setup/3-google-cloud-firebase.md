# 3. Google Cloud and Firebase

Firebase is your app's backend: user accounts, data, files, and
notifications. It runs in a Google Cloud project that you own and pay for.

- Steps 1–2 are for everyone.
- Step 3 sets up Firebase: **by one command** (3A, recommended, about 5
  minutes) **or in the console** (3B, about 1 hour). Both give the same
  result.
- Steps 4–5 are for everyone.

You need the values from [guide 2](2-deployment-repository.md#step-2-choose-your-values).

## Step 1: Billing account

1. Sign in to <https://console.cloud.google.com/billing> with your company
   Google account. If your company uses Google Workspace or a Google Cloud
   organization, use an account in it.
2. Click **Create account** (or **Add billing account**), enter your company
   details and a payment method, and finish.
3. Wait until the account shows as **active**. If it shows as closed, open
   it and follow the banner (often a card verification); see the
   [FAQ](FAQ.md#my-billing-account-shows-as-closed).
4. Note the **billing account ID** (format `XXXXXX-XXXXXX-XXXXXX`).
5. In **Budgets & alerts**, click **Create budget**, choose an amount, and
   keep the default email alerts.

The backend needs the pay-as-you-go **Blaze** plan, which is what linking
this account gives. Small apps usually stay within the free allowance.

## Step 2: Sign in from your computer

In the source code folder from guide 2:

```
cd backend/functions
npm ci
npx firebase login
cd ../..
```

`firebase login` opens a browser: sign in with the same company Google
account.

## Step 3A: Set up Firebase by command (recommended)

1. Run, with your deployment ID and billing account ID:

   ```
   node tool/provision.mjs acme --create --billing-account XXXXXX-XXXXXX-XXXXXX
   ```

   It creates the Firebase project, links billing, enables the needed
   services, turns on the sign-in methods, creates the database and file
   storage in your data location, registers the Android and iOS apps, writes
   their two configuration files into `deployments/<deployment ID>/firebase/`,
   publishes the update settings, and creates the `codemagic-deploy` account
   used by Codemagic. Each line shows ✓ when done.
   If your company uses a Google Cloud **organization**, its rules may require
   new projects to be created inside it: create the project in the console
   instead (3B.1, steps 1–4), then run the same command **without**
   `--create`.
2. If it says **click Get started once in the console**, open the link it
   shows, click **Get started** under Authentication, and run the same
   command again. It is safe to run as often as needed: it skips what is done.
3. Read the **Left by hand** list at the end: Step 4 below and the APNs key of
   [guide 4](4-apple.md#step-6-create-the-push-notification-key) are on it.

Then go to Step 4.

## Step 3B: Set up Firebase in the console

### 3B.1 Create the project

1. Go to <https://console.firebase.google.com> and click **Create a project**.
2. Enter the project name. Below it, Firebase shows the **project ID**: click
   it and make it exactly your Firebase project ID.
3. If your company has a Google Cloud organization, choose it as the parent.
4. Turn **Google Analytics off** (the app does not use it), and click
   **Create project**.
5. At the bottom left, click the plan name (**Spark**), then **Upgrade**,
   choose **Blaze**, and select your billing account.

### 3B.2 Sign-in methods

1. Open **Build → Authentication** and click **Get started**.
2. In **Sign-in method**, choose **Email/Password**, switch **Enable** on, and
   save.
3. Only if `phoneVerification` is `true`: choose **Phone**, enable it, and
   save.

### 3B.3 Database

1. Open **Build → Firestore Database** and click **Create database**.
2. If asked for an edition, choose **Standard**.
3. **Location:** your data location. **It cannot be changed later.**
4. Choose **Start in production mode** and click **Create**.

### 3B.4 File storage

1. Open **Build → Storage** and click **Get started**.
2. Choose the same location, **Start in production mode**, and finish.

### 3B.5 Register the apps

1. Open **Project overview** (house icon), click **Add app**, then **Android**.
   **Package name:** your App ID. Nickname: your app name. Leave SHA-1 empty.
   Click **Register app**, then **Download google-services.json**, then
   **Next** until the end.
2. Click **Add app**, then **iOS**. **Bundle ID:** the same App ID. Click
   **Register app**, then **Download GoogleService-Info.plist**, then
   **Next** until the end.
3. Move both files into `deployments/<deployment ID>/firebase/`. They are not
   secret: they ship inside the app.

### 3B.6 Update settings

1. Open **Run → Remote Config** and click **Create configuration**.
2. Add these parameters, type **String**, then click **Publish changes**:

| Parameter | Value |
| --- | --- |
| `minimum_app_version` | `0.0.0` |
| `android_store_url` | `https://play.google.com/store/apps/details?id=<App ID>` |
| `ios_store_url` | `https://apps.apple.com/app/id<Apple ID>` (add it after [guide 4](4-apple.md), Step 5) |

### 3B.7 Deploy account

1. Go to <https://console.cloud.google.com>, select your project, open **IAM &
   Admin → Service Accounts**, and click **Create service account**.
2. Name it `codemagic-deploy` and click **Create and continue**.
3. Add these four roles, then click **Done**: **Firebase Admin**, **Cloud
   Functions Admin**, **Service Account User**, **Artifact Registry
   Administrator**.

## Step 4: Put the deploy key into Codemagic

This key lets Codemagic install the backend in your project. It is a
**secret**.

1. Go to <https://console.cloud.google.com/iam-admin/serviceaccounts>, select
   your project, and click `codemagic-deploy@<project ID>.iam.gserviceaccount.com`.
2. Open **Keys**, then **Add key → Create new key → JSON → Create**. A file
   downloads.
3. Paste its whole content into Codemagic: group `firebase_deploy`, variable
   `FIREBASE_SERVICE_ACCOUNT`, Secret on
   ([how to paste a secret](1-codemagic.md#how-to-paste-a-secret-into-codemagic)).
4. Delete the downloaded file.

If key creation is refused because **service account key creation is
disabled**, see the [FAQ](FAQ.md#key-creation-is-disabled-by-an-organization-policy).

## Step 5: Check and save your deployment

1. In the source code folder, run:

   ```
   node tool/deployment.mjs check acme
   ```

   It must say `Deployment "acme" is valid.` Otherwise it lists what to fix.
2. Commit and push your deployment repository:

   ```
   cd deployments/acme
   git add .
   git commit -m "Deployment settings and Firebase files"
   git push
   cd ../..
   ```

## Check

- [ ] The billing account is active and linked (the Firebase console shows
      **Blaze**), with a budget alert
- [ ] `node tool/deployment.mjs check <deployment ID>` passes
- [ ] The deployment repository is pushed, with `deployment.json` and the two
      files in `firebase/`
- [ ] `FIREBASE_SERVICE_ACCOUNT` is in Codemagic, and the key file is deleted
