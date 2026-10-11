# 3. Apple

Your iOS app is published under your company's Apple Developer account.

- **Part 1** is for everyone. **Start it on day one**: Apple can take 1–3
  weeks to approve an organization.
- Then do **Part 2A** (we do the setup) **or Part 2B** (you do the setup).

## Part 1: Membership and agreements (everyone)

### Step 1: Get a D-U-N-S number

Apple identifies organizations by their D-U-N-S number.

1. Check whether your company already has one, and request it for free if
   not, through Apple's D-U-N-S lookup:
   <https://developer.apple.com/enroll/duns-lookup/>.
2. A new number can take several days to arrive.

### Step 2: Enroll your organization

1. Go to <https://developer.apple.com/programs/enroll/> and sign in with an
   Apple Account in your company's name, with two-factor authentication on.
   This person becomes the **Account Holder**.
2. Choose to enroll as an **organization**, enter the D-U-N-S number and
   your company details, and pay the yearly fee.
3. Wait for Apple's approval email. Apple may call to verify your company.

### Step 3: Accept the agreements

1. The Account Holder signs in to <https://appstoreconnect.apple.com>.
2. Open **Business** (or **Agreements, Tax, and Banking**) and accept every
   pending agreement.
3. Do this again whenever Apple publishes a new agreement: until it is
   accepted, new builds cannot be uploaded.

## Part 2A: Give us access (about 5 minutes)

1. In <https://appstoreconnect.apple.com>, open **Users and Access** and
   click **+**.
2. Enter our team's name and email address.
3. Choose the role **Admin**, and click **Invite**.

That is all. We register the app, create the keys, and paste them straight
into your Codemagic team. If your app uses Firebase Option A, we also upload
the push key to your Firebase project.

## Part 2B: Do the setup yourself (about 1 hour)

You need the **App ID** and **App name** we sent you, and the Codemagic team
from [guide 1](1-codemagic.md).

### Step 1: Register the App ID

1. Go to <https://developer.apple.com/account>, then **Certificates, IDs &
   Profiles → Identifiers**, and click **+**.
2. Choose **App IDs**, click **Continue**, choose **App**, and click
   **Continue**.
3. **Description**: the app name. **Bundle ID**: choose **Explicit** and
   enter the App ID exactly.
4. In **Capabilities**, tick **Push Notifications** and **Associated
   Domains**.
5. Click **Continue**, then **Register**.

### Step 2: Create the app in App Store Connect

1. In <https://appstoreconnect.apple.com>, open **Apps**, click **+**, then
   **New App**.
2. Tick **iOS**. Enter the app name and primary language, select the bundle
   ID from Step 1, enter the App ID again as **SKU**, and choose **Full
   Access**.
3. Click **Create**.
4. Open **App Information** and note the **Apple ID** (a number). You send it
   to us; it is used for the update screen's store link.

### Step 3: Create the push notification key

This key lets Firebase send notifications to iPhones. It is a **secret**, and
the one secret that goes to Firebase instead of Codemagic.

1. In <https://developer.apple.com/account>, open **Certificates, IDs &
   Profiles → Keys** and click **+**.
2. Name it `Push`, tick **Apple Push Notifications service (APNs)**, and if
   asked, choose the environment **Sandbox & Production**.
3. Click **Continue**, then **Register**, then **Download**. You can download
   it **only once**. Note the **Key ID** shown on the page.
4. Note your **Team ID**: it is shown in **Membership details** on
   <https://developer.apple.com/account>.
5. In the Firebase console, open **Project settings → Cloud Messaging**. Under
   **Apple app configuration**, in **APNs Authentication Key**, click
   **Upload**, choose the file, enter the Key ID and Team ID, and click
   **Upload**.
6. Keep the file in your company's password manager, or delete it. Never send
   it to anyone.

### Step 4: Create the App Store Connect API key

This key lets Codemagic sign your app and upload it. It is a **secret**.

1. In <https://appstoreconnect.apple.com>, open **Users and Access →
   Integrations → App Store Connect API → Team Keys**. The first time, the
   Account Holder must click **Request Access** and accept.
2. Click **Generate API Key** (or **+**). Name it `Codemagic`, choose the
   access **App Manager**, and click **Generate**.
3. Note the **Issuer ID** (above the list) and the key's **Key ID**.
4. Click **Download API Key**. You can download it **only once**.
5. Paste into Codemagic, group `ios_signing`, Secret on (see
   [How to paste a secret](1-codemagic.md#how-to-paste-a-secret-into-codemagic)):

   | Variable name | Value |
   | --- | --- |
   | `APP_STORE_CONNECT_ISSUER_ID` | The Issuer ID |
   | `APP_STORE_CONNECT_KEY_IDENTIFIER` | The Key ID |
   | `APP_STORE_CONNECT_PRIVATE_KEY` | The whole content of the downloaded `.p8` file |

6. Delete the downloaded file.

### Step 5: Create the certificate key

Codemagic uses this private key to create your app's signing certificate. It
is a **secret**.

1. Open a terminal: **Terminal** on a Mac, or **PowerShell** on Windows 10 or
   later.
2. Run this command. It creates two files, `cert_key` and `cert_key.pub`, in
   the current folder:

   ```
   ssh-keygen -t rsa -b 2048 -m PEM -f cert_key -q -N ""
   ```

3. Open `cert_key` (not `.pub`) in a text editor and copy everything.
4. Paste it into Codemagic, group `ios_signing`, variable
   `CERTIFICATE_PRIVATE_KEY`, Secret on.
5. Delete both files, `cert_key` and `cert_key.pub`.

If you cannot run the command, choose Option A for this step only: we do it
in a short call while you watch.

### Send us (Option B)

- [ ] Your **Team ID** and the app's **Apple ID**
- [ ] Screenshots of: the App ID with its two capabilities, the app in App
      Store Connect, the APNs key uploaded in Firebase, and the Codemagic
      `ios_signing` group with four variables

## Send us (Option A)

- [ ] Confirmation that the invitation is sent

## Check

- [ ] Membership approved, and no pending agreement in App Store Connect
- [ ] Option A: we appear in Users and Access as Admin
- [ ] Option B: Steps 1–5 done; no key file was sent to anyone
