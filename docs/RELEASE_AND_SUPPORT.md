# Release, Upgrade, and Support Policy

This guide is for the deployment team. It defines how a new version reaches
every customer, which versions we support, and when support for an old
version ends.

How to set up a customer is in [DEPLOYMENT.md](DEPLOYMENT.md). Ownership,
bug triage, and incident handling are in
[CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md).

## 1. The rule: one version line, every customer on it

- There is **one codebase and one version line**: the `main` branch and the
  release tags made from it (`v1.1.0`, `v1.2.0`, ...).
- **Every customer is upgraded to every new version.** A customer can be
  behind for a short, defined time (§4), never permanently.
- **No customer branches, no customer forks, no customer-only builds.** A
  customer's difference from another customer is only its
  `deployments/<id>/` folder: the deployment file, its public Firebase files,
  and the module switches.
- **Fixes are made once, on `main`, and shipped in the next version.** We do
  not patch an old version for one customer. The fix for an old version is
  the upgrade.

Why: with one version line, a fix is written, tested, and released once, and
every customer gets it. Each fork or customer branch would multiply that work
and would eventually stop receiving fixes.

## 2. Version numbers

The version is set only in `frontend/pubspec.yaml` (`version: X.Y.Z+build`).
Codemagic sets the build number. The same version is used for the app and
the backend (Cloud Functions and rules) of a release.

| Part | Raise it when | Example | Upgrade effort |
| --- | --- | --- | --- |
| **Patch** `X.Y.Z+1` | Bug and security fixes only. No new settings, no data changes. | `1.2.0` → `1.2.1` | Rebuild and release; nothing to configure |
| **Minor** `X.Y+1.0` | New features or modules, new deployment-file fields (with defaults), backward-compatible backend changes | `1.2.1` → `1.3.0` | Review the changelog's upgrade notes; customer accepts on staging |
| **Major** `X+1.0.0` | A change that needs work or a decision per customer: data migration, removed field or module, new required account setup | `1.3.0` → `2.0.0` | Planned migration per customer |

Each release is:

1. merged to `main` with all checks passing (`frontend-ci`, `backend-ci`);
2. given an entry in `CHANGELOG.md`, with an **Upgrade notes** section (order
   of backend and app deployment, new settings, manual steps);
3. tagged `vX.Y.Z` on that commit. Every customer build of that version is
   made from this tag, never from a branch.

## 3. Release flow for a new version

For each release, the release operator follows these steps in order.

### Step 1: Prepare (once per release)

- [ ] Tag created and `CHANGELOG.md` upgrade notes written.
- [ ] `node tool/deployment.mjs list` shows every deployment as valid at the
      tag.
- [ ] New deployment-file fields have defaults, so existing deployment files
      work unchanged. If a customer needs a non-default value, update their
      file on `main` before tagging.
- [ ] Release announcement sent to every customer contact: version, what
      changed, upgrade deadline (§4), and the end-of-support date of the
      version being replaced (§5).

### Step 2: Roll out in waves

Upgrade deployments in this order. Start a wave only when the previous one is
healthy for the stated time.

| Wave | Deployments | Wait before next wave |
| --- | --- | --- |
| 0 | `dev`, `test` | Smoke test passes |
| 1 | Customer staging projects (`<customer>-staging`) | Customer acceptance where required |
| 2 | One pilot customer production | 2 days with no new crash or error trend (patch: 1 day) |
| 3 | All other customer production deployments | — |

A security release (§4) may skip the waiting times, but not wave 0.

### Step 3: Upgrade one deployment

For each deployment, in the customer's Codemagic team, with the tag selected:

1. **Backend first.** Run `backend-deploy`. The new backend must keep working
   with the app version users still have installed.
2. **Apps.** Run `android-release` and `ios-release`. Then promote the build
   from the Play internal track and from TestFlight to production in the
   customer's store accounts, using staged rollout where available.
3. **Verify** on a real device with a test account: sign-in, the changed
   features, push notification. Check Crashlytics and the Functions logs.
4. **Record** in the deployment register: version, tag, commit, build
   numbers, date, operator, and customer acceptance (if required).
5. **After the store release is live**, raise `minimum_app_version` in the
   customer's Remote Config when §5 requires it. Never raise it before the new
   build can be downloaded from both stores.

### Step 4: Close the release

- [ ] Every deployment in the register shows the new version, or has an
      approved deferral with a date (§4).
- [ ] Customers who are late have been contacted.

## 4. Upgrade deadlines

The deadline counts from the day the version is tagged. The customer agrees
to these deadlines in their contract; we schedule the work.

| Release type | Every production deployment upgraded within |
| --- | --- |
| Security fix (patch) | 3 working days |
| Patch | 14 days |
| Minor | 30 days |
| Major | 90 days, following an upgrade plan agreed with the customer |

**Deferral.** A customer can ask to postpone an upgrade, for example during
their busy season. The product owner may approve one deferral of at most 30
days, recorded with its reason and new date in the register. A deferral never
extends past the end of support of the customer's current version (§5), and
security fixes cannot be deferred.

**Skipping versions.** A customer who is more than one version behind is
upgraded directly to the latest version, not one version at a time. The
upgrade notes of every version in between are applied together, and the
upgrade is tested on the customer's staging project first.

## 5. Supported versions and end of support

We support only the **latest release** and, for a short overlap, the one
before it.

| Status | Which version | What the customer gets |
| --- | --- | --- |
| **Current** | The latest release | Full support: bug reports, fixes, SLA |
| **Previous** | The release before it, until its end-of-support date | Help and diagnosis. Fixes ship only in a newer version, so the answer to a defect is an upgrade |
| **Unsupported** | Anything older, or Previous after its end-of-support date | No SLA, no fixes, no investigation beyond "upgrade to the current version" |

**End-of-support date.** A version becomes unsupported **60 days after the
next minor or major version is tagged**, or **when a security fix replaces
it**, whichever comes first. A patch that is not a security fix does not
shorten support of the previous minor version, but the customer still has to
take it within 14 days (§4).

Example: `1.2.0` is tagged on 1 March. `1.1.x` is Previous until 30 April,
then Unsupported.

**Each release announcement states the end-of-support date** of the version
it replaces. Remind the customer again 30 days and 7 days before that date
if they are still on it.

### Enforcing end of support on users' phones

A customer's deployment can be on the current version while some of their
users still run an old app. The `minimum_app_version` Remote Config value
makes the old app show a blocking "update required" screen that opens the
store.

| When | Set `minimum_app_version` in that customer's Firebase project to |
| --- | --- |
| A security fix is live in both stores | The fixed version, right away |
| A version reaches end of support | The oldest version still supported for that customer |
| A backend change no longer works with an older app | The first app version that works with it, **before** deploying that backend |

Before raising it, check that `android_store_url` and `ios_store_url` are set
and that the new build is downloadable from both stores. Changes reach
devices within about one hour.

### A customer who does not upgrade

If a production deployment reaches the end-of-support date of its version:

1. The customer owner informs the customer in writing that the deployment is
   unsupported and what that means (§5 table).
2. The deployment is marked **Unsupported** in the register. Support requests
   for it are answered with the upgrade offer only.
3. Security issues found in their version are reported to them, with the
   upgrade as the remedy.
4. The product owner and the customer owner decide on contract steps. We do
   not create a separate version to keep them running.

## 6. What a customer can and cannot get

| Customer asks for | We do |
| --- | --- |
| Their name, colors, links, region, modules on or off | Change their deployment file; ships with the next release, or a configuration-only release of the current version |
| A setting that changes how a feature behaves | Add a general option to the deployment file (with a default), named after the capability, in a normal release |
| A new feature | Product owner decides. If accepted, it becomes a product module that any customer can turn on, released in a minor version |
| A fix only for them, on their old version | Not possible. The fix is made on `main` and they receive it by upgrading |
| To stay on an old version | Allowed until its end-of-support date (§5), then the deployment is unsupported |
| Code written only for them | Not possible. Never write `if (deploymentId == ...)` or customer names in code |

**Configuration-only release.** Changing a deployment file (for example a new
link or a module switched off) does not need a new version: commit the change
to `main`, then rebuild that customer from the **same tag they are on** with
the updated deployment folder. Record it in the register as the same version
with a new build number. If the change touches code, it waits for the next
version.

## 7. Deployment register

Every deployment has one row in the deployment register (kept in the
access-controlled system described in
[CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md) §2). For this policy it must
show at least:

| Field | Example |
| --- | --- |
| Deployment ID | `acme` |
| Current version and tag | `1.2.1`, `v1.2.1` |
| Build numbers | Android 57, iOS 57 |
| Backend version deployed | `1.2.1`, 2026-11-03 |
| `minimum_app_version` | `1.2.0` |
| Support status | Current / Previous until 2026-12-30 / Unsupported |
| Upgrade deadline for the latest release | 2026-11-17 |
| Deferral | none, or reason and date approved by the product owner |
| Last upgrade | 2026-11-03, operator, customer acceptance reference |

Review the register at the end of every release and once a month. Any
deployment that is past a deadline is escalated to the product owner.

## 8. Roles

| Role | In this process |
| --- | --- |
| Product owner | Approves releases, deferrals, and feature requests; owns end-of-support decisions |
| Release operator | Tags, rolls out the waves, upgrades each deployment, keeps the register up to date |
| Customer owner | Announces releases and end-of-support dates to the customer, collects acceptance, handles late customers |
| Developer / on-call | Fixes on `main`, writes changelog and upgrade notes, supports the operator during rollout |

## 9. Checklists

### Each release

- [ ] Tag `vX.Y.Z` on `main`, `CHANGELOG.md` with upgrade notes
- [ ] All deployment files valid at the tag
- [ ] Announcement with upgrade deadline and end-of-support date sent
- [ ] Wave 0 → 3 completed and verified
- [ ] Register updated for every deployment
- [ ] `minimum_app_version` raised where §5 requires it

### Each deployment upgrade

- [ ] Built from the release tag
- [ ] Backend deployed before the apps
- [ ] Android and iOS released and promoted
- [ ] Tested on a device; Crashlytics and Functions logs clean
- [ ] Register row updated

### Monthly

- [ ] Every deployment on Current or Previous
- [ ] Reminders sent for versions reaching end of support within 30 days
- [ ] Overdue deployments escalated
