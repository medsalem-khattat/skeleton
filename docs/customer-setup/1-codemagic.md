# 1. Codemagic

Codemagic builds your app and publishes it to the stores. It is also the only
place where your secrets are stored. This guide is the same for Option A and
Option B, and takes about 15 minutes.

Do it first: the other guides paste secrets into your Codemagic team.

## Step 1: Create your team

1. Go to <https://codemagic.io> and sign up with your **company** email
   address, not a personal one.
2. Create a team: open **Teams**, click **Add team** (or **Create team**),
   and name it after your company, for example `Acme apps`.

## Step 2: Set up billing

1. Open the team, then **Team settings → Billing**.
2. Choose a plan or add a payment method. iOS builds need macOS build
   minutes, which are paid.

## Step 3: Invite us

1. Open **Team settings → Team members** and click **Invite**.
2. Enter our team's email address (we send it to you), choose the role
   **Admin**, and send the invitation.

We then add the app to your team and create the settings that are not
secret. When that is done, we tell you, and the other guides can paste their
secrets into it.

## How to paste a secret into Codemagic

The other guides refer to this section. They tell you a **group** and a
**variable name**, for example group `ios_signing`, variable
`APP_STORE_CONNECT_KEY_IDENTIFIER`.

1. In your Codemagic team, open the app (named after your app), then the
   **Environment variables** tab.
2. Fill in:
   - **Variable name**: exactly as the guide says (capital letters and
     underscores).
   - **Variable value**: the secret. For a key file, open it in a text
     editor and copy **everything**, including the `-----BEGIN` and
     `-----END` lines.
   - **Select group**: the group the guide names. It already exists; we
     created it.
   - **Secret**: switched **on**.
3. Click **Add**. The value is now hidden; nobody can read it back.
4. Delete the file you copied it from, unless the guide says to keep it in
   your password manager.

To replace a secret later, delete the variable and add it again.

## How to upload the Android keystore

The [Google Play guide](4-google-play.md) creates this file.

1. Open **Team settings → codemagic.yaml settings → Code signing
   identities → Android keystores**.
2. Upload the keystore file, and enter its password, key alias, and key
   password.
3. In **Reference name**, enter exactly `upload_keystore`.
4. Click **Add keystore**.

## Send us

- [ ] The name of your Codemagic team

## Check

- [ ] Billing is active
- [ ] We have accepted the invitation and appear as Admin in Team members
