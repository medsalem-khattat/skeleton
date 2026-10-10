# 1. Codemagic

Codemagic builds your app and publishes it to the stores. It is also the only
place where your secrets are stored. About 20 minutes.

## Step 1: Create your team

1. Go to <https://codemagic.io> and sign up with your **company** email
   address, not a personal one.
2. Create a team: open **Teams**, click **Add team** (or **Create team**),
   and name it after your company, for example `Acme apps`.
3. Invite the colleagues who will run builds: **Team settings → Team
   members → Invite**. Give the role **Admin** only to the people who manage
   secrets.

## Step 2: Set up billing

1. Open the team, then **Team settings → Billing**.
2. Choose a plan or add a payment method. iOS builds need macOS build
   minutes, which are paid.

## Step 3: Get access to the app's source code

Codemagic reads the app's source code from our repository, with a key that
only you hold. You send us the **public** half of the key, which is not a
secret.

1. Open a terminal (**Terminal** on a Mac, **PowerShell** on Windows) and
   run:

   ```
   ssh-keygen -t ed25519 -f codemagic_source_key -q -N "" -C "codemagic-<your-company>"
   ```

   It creates two files: `codemagic_source_key` (private, a **secret**) and
   `codemagic_source_key.pub` (public).
2. Send `codemagic_source_key.pub` to [medsalemkhattat@gmail.com](mailto:medsalemkhattat@gmail.com), with your company name. We add
   it as a **read-only** key on our repository and confirm, usually within
   one working day.
3. Keep `codemagic_source_key` for Step 4. Do not send it to anyone.

## Step 4: Add the app to your team

After we confirm Step 3:

1. In Codemagic, open **Apps** and click **Add application**.
2. Choose your team, then **Other** (or **Git repository URL**, depending on
   the screen).
3. **Repository URL:** `git@github.com:medsalem-khattat/skeleton.git`.
4. **SSH key:** open `codemagic_source_key` (the file without `.pub`) in a text
   editor and paste all of it, including the `-----BEGIN` and `-----END`
   lines. Leave the passphrase empty.
5. **Project type:** **Flutter App (via codemagic.yaml)**. Click **Finish**
   (or **Add application**).
6. Delete both key files. If you ever need a new one, repeat Step 3.

## Step 5: Create the environment groups

The app's workflows read their settings from **groups** of variables with
these exact names. Create the groups now; the other guides fill them.

1. Open the app, then the **Environment variables** tab.
2. Add the first variable below; type the group name in **Select group**
   to create the group.

| Group | Variable | Value | Secret | Filled in |
| --- | --- | --- | --- | --- |
| `deployment` | `DEPLOYMENT_ID` | Your deployment ID (guide 2) | Off | Guide 2 |
| `deployment` | `DEPLOYMENT_REPO` | SSH URL of your deployment repository | Off | Guide 2 |
| `deployment` | `DEPLOYMENT_REPO_SSH_KEY` | Its read-only key | **On** | Guide 2 |
| `deployment` | `CM_PUBLISH_EMAIL` | The address that receives build results | Off | Now |
| `firebase_deploy` | `FIREBASE_SERVICE_ACCOUNT` | The Firebase deploy key | **On** | Guide 3 |
| `ios_signing` | `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_PRIVATE_KEY`, `CERTIFICATE_PRIVATE_KEY` | Apple keys | **On** | Guide 4 |
| `google_play` | `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | The Play publishing key | **On** | Guide 5 |

Plus one Android keystore with the reference name `upload_keystore`
(guide 5).

## How to paste a secret into Codemagic

The other guides refer to this section. They tell you a **group** and a
**variable name**.

1. In your Codemagic team, open the app, then the **Environment variables**
   tab.
2. Fill in:
   - **Variable name**: exactly as the guide says (capital letters and
     underscores).
   - **Variable value**: the secret. For a key file, open it in a text
     editor and copy **everything**, including the `-----BEGIN` and
     `-----END` lines.
   - **Select group**: the group the guide names.
   - **Secret**: switched **on**.
3. Click **Add**. The value is now hidden; nobody can read it back.
4. Delete the file you copied it from, unless the guide says to keep it in
   your password manager.

To replace a secret, delete the variable and add it again.

## How to upload the Android keystore

[Guide 5](5-google-play.md) creates this file.

1. Open **Team settings → codemagic.yaml settings → Code signing
   identities → Android keystores**.
2. Upload the keystore file, and enter its password, key alias, and key
   password.
3. In **Reference name**, enter exactly `upload_keystore`.
4. Click **Add keystore**.

## Check

- [ ] Billing is active
- [ ] The app is added, and its **Start new build** dialog lists the
      repository's branches and tags
- [ ] `CM_PUBLISH_EMAIL` is set in group `deployment`
- [ ] Both `codemagic_source_key` files are deleted
