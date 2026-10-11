# 7. Upgrades and Changes

After the first release, your team runs three kinds of updates: a new
version from us, a change of your own settings, and a secret replacement.

## A new version

We email every release: the version tag, what changed, the **upgrade
notes**, your **upgrade deadline**, and the date when the version you run
stops being supported. Fixes come only in new versions: staying up to date is
what keeps your app supported.

| Release type | Upgrade within |
| --- | --- |
| Security fix | 3 working days |
| Patch (`1.2.0` → `1.2.1`) | 14 days |
| Minor (`1.2` → `1.3`) | 30 days |
| Major (`1.x` → `2.0`) | 90 days |

A version stays supported until 60 days after the next minor or major version,
or until a security fix replaces it. If you are several versions behind, go
straight to the latest one, applying every upgrade note in between.

### Steps (about 30 minutes, plus builds)

1. **Read the upgrade notes** of the new version in `CHANGELOG.md` (in the
   source code, or in our release email). They say whether anything is needed
   besides rebuilding: a new setting in `deployment.json`, a command to run, or
   a console step.
2. **Update your local copy** and switch to the new tag:

   ```
   git fetch --tags
   git checkout v1.2.0
   ```

3. **Apply the upgrade notes**, if any. If they change `deployment.json`,
   check it (`node tool/deployment.mjs check <deployment ID>`), then commit and
   push your deployment repository.
4. **If you have a staging deployment**, upgrade it first and test it.
5. In Codemagic, on the **new tag**
   ([how to start a workflow](6-first-release.md#how-to-start-a-workflow-in-codemagic)):
   1. **Backend deploy** first;
   2. then **Android release** and **iOS release**.
6. **Test** the builds from the testing tracks
   ([guide 6, Step 6](6-first-release.md#step-6-test-the-app-about-15-minutes)).
7. **Publish**: promote the Android release to production and submit the iOS
   build for review ([guide 6, Step 7](6-first-release.md#step-7-publish-to-the-stores)).
8. **Raise the minimum version** only when the upgrade notes or our release
   email ask for it (for example a security fix), and only once the new
   version can be downloaded from **both** stores: Firebase → **Run → Remote
   Config** → `minimum_app_version` → the new version → **Publish changes**.
   Users of older versions then see an "update required" screen.
9. **Tell us** the version and date.

## A change of your settings

Name, colors, links, or modules on or off: no new version is needed.

1. Edit `deployment.json` in your deployment repository, check it
   (`node tool/deployment.mjs check <deployment ID>`), commit, and push.
2. In Codemagic, start **Android release** and **iOS release** on the **same
   tag you already run**.
3. Publish the new builds as usual.

The App ID, the Firebase project ID, and the data location cannot be changed
this way: a new value means a new app or a new project.

## A secret replacement

Replace a secret when it may have been exposed, when someone who had it
leaves, or once a year:

1. Create a new one exactly as its guide describes, and paste it into
   Codemagic in place of the old one.
2. Delete the old one where it was created: the old key in Google Cloud
   (**Service account → Keys**), the old App Store Connect API key, or the old
   SSH deploy key.
3. Run the **Readiness check** to confirm that the new secret works.

## A staging deployment (recommended)

A second, identical deployment lets you test every upgrade before your users
get it: a second Firebase project (for example `acme-field-staging`), a
second deployment repository with its own `deployment.json` (its own App ID,
for example `com.acme.field.staging`), and a second application in Codemagic.
Follow guides 2–6 for it once.
