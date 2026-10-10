# 2. Your Deployment Repository

Everything that makes the app **yours** (name, app ID, Firebase project,
colors, links, modules) lives in one small file, `deployment.json`, plus two
Firebase files. You keep them in a private repository of your own. Codemagic
reads it at every build. About 30 minutes.

## Step 1: Prepare your computer

1. Install [Git](https://git-scm.com/downloads) and
   [Node.js 22](https://nodejs.org/).
2. Get your own read-only key to our repository, as in
   [guide 1, Step 3](1-codemagic.md#step-3-get-access-to-the-apps-source-code):
   create a key pair named `skeleton_key` on this computer and send us the
   `.pub` file. Keep the private file in your `~/.ssh` folder.
3. Tell SSH to use it for our repository: add these lines to `~/.ssh/config`
   (create the file if it does not exist; on Windows it is
   `C:\Users\<you>\.ssh\config`):

   ```
   Host skeleton-source
     HostName github.com
     User git
     IdentityFile ~/.ssh/skeleton_key
     IdentitiesOnly yes
   ```

4. Clone the source code and switch to the latest release tag (we announce
   it; `git tag` lists them):

   ```
   git clone skeleton-source:medsalem-khattat/skeleton.git
   cd skeleton
   git checkout v1.1.0
   ```

## Step 2: Choose your values

Decide these with your business owner. The first three are **permanent**
once the app is published.

| Value | Rule | Example |
| --- | --- | --- |
| App ID | Your company's reverse domain plus the app name; lowercase letters, digits, dots. Used as Android package name **and** iOS bundle ID | `com.acme.field` |
| Firebase project ID | 6–30 lowercase letters, digits, hyphens; must be free worldwide | `acme-field-prod` |
| Data location | Where user data is stored. Choose for your users and your legal needs: `europe-west1` (Belgium), `us-central1` (Iowa), others in the [Firestore locations](https://firebase.google.com/docs/firestore/locations) | `europe-west1` |
| Deployment ID | Lowercase letters, digits, hyphens; names your deployment in builds | `acme` |
| App name | 1–30 characters, shown under the app icon | `Acme Field` |

## Step 3: Create the repository

1. In your Git hosting service, create a **private** repository, for example
   `acme-app-deployment`, and clone it **inside** the source code folder, at
   `deployments/<deployment ID>`:

   ```
   git clone <your repository URL> deployments/acme
   ```

   This folder is ignored by our repository, so it never mixes with it.
2. Copy the example file into it:

   ```
   cp deployments/example/deployment.json deployments/acme/
   ```

   (On Windows PowerShell: `Copy-Item deployments\example\deployment.json deployments\acme\`.)

## Step 4: Fill in deployment.json

Open `deployments/<deployment ID>/deployment.json` in a text editor. Delete
the line `"internal": true,`. Then set:

| Field | Value |
| --- | --- |
| `deploymentId` | Your deployment ID; must equal the folder name |
| `appName` | Your app name |
| `appId` | Your App ID |
| `firebase.projectId` | Your Firebase project ID |
| `firebase.authActionHost` | `<Firebase project ID>.firebaseapp.com` |
| `firebase.functionsRegion` | Your data location, for example `europe-west1` |
| `firebase.firestoreLocation` | Optional; the database location if different from `functionsRegion` |
| `stores.appleId` | Leave `""` for now; filled in [guide 4](4-apple.md), Step 5 |
| `links.privacyPolicyUrl` | Your public privacy policy page (**required by both stores**) |
| `links.termsOfServiceUrl` | Your terms page, or empty |
| `links.supportEmail` | The address users write to |
| `links.authActionContinueUrl` | Empty, unless you host email links on your own domain |
| `api.baseUrl` | Empty, unless we tell you otherwise |
| `seedColor` | Your brand color, `#RRGGBB` |
| `features.*` | `true` or `false` per module (below) |

| Module | What it does | Note |
| --- | --- | --- |
| `authentication` | Sign-up, sign-in, email verification, password reset | Most modules need it |
| `phoneVerification` | SMS-verified phone number at sign-up | Sends SMS, billed by Google |
| `home` | Home screen | |
| `profile` | Name and photo | |
| `settings`, `appearanceSettings`, `languageSettings` | Settings screens: theme and language | |
| `deviceAuthentication` | App lock with fingerprint, face, or device PIN | |
| `pushNotifications`, `notificationInbox` | Notifications and the in-app inbox | |
| `crashReporting` | Crash reports in Firebase Crashlytics | |

The Firebase files (`firebase/` folder) are created in
[guide 3](3-google-cloud-firebase.md).

## Step 5: Let Codemagic read the repository

1. Create a key pair for it:

   ```
   ssh-keygen -t ed25519 -f deployment_repo_key -q -N "" -C "codemagic-deployment"
   ```

2. In your Git hosting service, add `deployment_repo_key.pub` to the
   repository as a **read-only deploy key** (GitHub: repository → **Settings
   → Deploy keys → Add deploy key**, leave **Allow write access** unticked).
3. In Codemagic, group `deployment`
   ([how to paste a secret](1-codemagic.md#how-to-paste-a-secret-into-codemagic)):
   - `DEPLOYMENT_REPO` (Secret off): the repository's SSH URL, for example
     `git@github.com:acme/acme-app-deployment.git`;
   - `DEPLOYMENT_REPO_SSH_KEY` (Secret **on**): the content of
     `deployment_repo_key`;
   - `DEPLOYMENT_ID` (Secret off): your deployment ID.
4. Delete both `deployment_repo_key` files.

## Check

- [ ] The source code is cloned and on the latest release tag
- [ ] `deployments/<deployment ID>/deployment.json` is filled in, without
      `internal`
- [ ] Codemagic group `deployment` has `DEPLOYMENT_ID`, `DEPLOYMENT_REPO`,
      `DEPLOYMENT_REPO_SSH_KEY`, and `CM_PUBLISH_EMAIL`

Do not commit yet: the deployment check needs the Firebase files of
[guide 3](3-google-cloud-firebase.md).
