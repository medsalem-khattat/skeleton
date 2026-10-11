# 4. Apple

Your iOS app is published under your company's Apple Developer account.
About 45 minutes, plus Apple's approval time.

**Start Steps 1–2 on day one**: Apple can take 1–3 weeks to approve an
organization.

## Step 1: Get a D-U-N-S number

Apple and Google identify organizations by their D-U-N-S number.

1. Check whether your company already has one, and request it for free if
   not: <https://developer.apple.com/enroll/duns-lookup/>.
2. A new number can take several days to arrive.

## Step 2: Enroll your organization

1. Go to <https://developer.apple.com/programs/enroll/> and sign in with an
   Apple Account in your company's name, with two-factor authentication on.
   This person becomes the **Account Holder**.
2. Enroll as an **organization**, enter the D-U-N-S number and your company
   details, and pay the yearly fee.
3. Wait for Apple's approval email. Apple may call to verify your company.

## Step 3: Accept the agreements

1. The Account Holder signs in to <https://appstoreconnect.apple.com>.
2. Open **Business** (or **Agreements, Tax, and Banking**) and accept every
   pending agreement.
3. Do this again whenever Apple publishes a new agreement: until it is
   accepted, new builds cannot be uploaded.

## Step 4: Register the App ID

1. Go to <https://developer.apple.com/account/resources/identifiers/list>
   and click **+**.
2. Choose **App IDs**, click **Continue**, choose **App**, and click
   **Continue**.
3. **Description:** your app name. **Bundle ID:** choose **Explicit** and
   enter your App ID exactly.
4. In **Capabilities**, tick **Push Notifications** and **Associated
   Domains**.
5. Click **Continue**, then **Register**.

## Step 5: Create the app in App Store Connect

1. In <https://appstoreconnect.apple.com/apps>, click **+**, then **New App**.
2. Tick **iOS**. Enter your app name (it must be unique on the App Store; if
   it is taken, add your company name) and primary language, select the
   bundle ID from Step 4, enter the App ID again as **SKU**, and choose **Full
   Access**. Click **Create**.
3. Open **App Information** and copy the **Apple ID** (a number).
4. Put it in `deployment.json` as the value of `stores.appleId`, for example
   `"stores": { "appleId": "6821400066" }`, then commit and push your
   deployment repository. If you used guide 3A, run
   `node tool/provision.mjs <deployment ID>` again: it publishes the App Store
   link. With 3B, add `ios_store_url` in Remote Config by hand.

## Step 6: Create the push notification key

This key lets Firebase send notifications to iPhones. It is a **secret**, and
the one secret that goes to Firebase instead of Codemagic. One key serves
every app of your Apple team: if you already have one, reuse it.

1. Go to <https://developer.apple.com/account/resources/authkeys/list> and
   click **+**.
2. Name it `Push`, tick **Apple Push Notifications service (APNs)**, and if
   asked, choose **Sandbox & Production**.
3. Click **Continue**, **Register**, then **Download**. You can download it
   **only once**. Note the **Key ID**.
4. Note your **Team ID**, shown in **Membership details** on
   <https://developer.apple.com/account>.
5. Open your Firebase project → **Project settings → Cloud Messaging**. Under
   **Apple app configuration**, in **APNs Authentication Key**, click
   **Upload**, choose the file, enter the Key ID and Team ID, and click
   **Upload**.
6. Keep the file in your company's password manager. Never send it to anyone.

## Step 7: Create the App Store Connect API key

This key lets Codemagic sign and upload your app. It is a **secret**.

1. In App Store Connect, open **Users and Access → Integrations → App Store
   Connect API → Team Keys**. The first time, the Account Holder must click
   **Request Access** and accept.
2. Click **Generate API Key** (or **+**). Name it `Codemagic`, choose the
   access **App Manager**, and click **Generate**.
3. Note the **Issuer ID** (above the list) and the key's **Key ID**.
4. Click **Download API Key**. You can download it **only once**.
5. Paste into Codemagic, group `ios_signing`, Secret on
   ([how to paste a secret](1-codemagic.md#how-to-paste-a-secret-into-codemagic)):

   | Variable name | Value |
   | --- | --- |
   | `APP_STORE_CONNECT_ISSUER_ID` | The Issuer ID |
   | `APP_STORE_CONNECT_KEY_IDENTIFIER` | The Key ID |
   | `APP_STORE_CONNECT_PRIVATE_KEY` | The whole content of the `.p8` file |

6. Delete the downloaded file.

## Step 8: Create the certificate key

Codemagic uses this private key to create your app's signing certificate. It
is a **secret**.

1. In a terminal, run:

   ```
   ssh-keygen -t rsa -b 2048 -m PEM -f cert_key -q -N ""
   ```

2. Open `cert_key` (not `.pub`) in a text editor and copy everything.
3. Paste it into Codemagic, group `ios_signing`, variable
   `CERTIFICATE_PRIVATE_KEY`, Secret on.
4. Delete both files, `cert_key` and `cert_key.pub`.

## Step 9: Add your testers

1. In App Store Connect, open your app → **TestFlight → Internal Testing**,
   and create a group, for example `Team`.
2. Add the colleagues who will test the app (they need App Store Connect
   access). They install the app with Apple's **TestFlight** app.

## Check

- [ ] Membership approved; no pending agreement in App Store Connect
- [ ] App ID registered with Push Notifications and Associated Domains
- [ ] App created in App Store Connect; `stores.appleId` set and pushed
- [ ] APNs key uploaded in Firebase
- [ ] Group `ios_signing` has its four variables; no key file was sent to anyone
