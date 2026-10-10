# Release, Upgrade, and Support Policy

This guide is for our team. It defines how we release a new version, how
customers upgrade to it, which versions we support, and when support for an
old version ends.

Customers deploy and upgrade their own environments, following
[customer-setup/](customer-setup/README.md); the upgrade steps they follow are
in [customer guide 7](customer-setup/7-upgrades-and-changes.md). Ownership,
bug triage, and incident handling are in
[CUSTOMER_DEPLOYMENT.md](CUSTOMER_DEPLOYMENT.md).

## 1. The rule: one version line, every customer on it

- There is **one codebase and one version line**: the `main` branch and the
  release tags made from it (`v1.1.0`, `v1.2.0`, ...).
- **Every customer upgrades to every new version**, with its own team. A
  customer can be behind for a short, defined time (§4), never permanently.
- **No customer branches, no customer forks, no customer-only builds.** A
  customer's difference from another customer is only its deployment folder:
  the deployment file, its public Firebase files, and the module switches.
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

This is enforced: `backend-deploy`, `android-release`, and `ios-release`
run `node tool/deployment.mjs release-check`, which stops a customer build
unless the commit has the tag `v<version>` of `frontend/pubspec.yaml` and no
local changes. `dev` and `test` are marked `"internal": true` in their
deployment file and can build any commit, so QA can test a release candidate
before it is tagged. `demo` is ours but not internal: it shows only released
versions.

## 3. Release flow for a new version

### Step 1: Prepare (our team, once per release)

- [ ] The release candidate on `main` is deployed to `test` and the QA team
      has signed it off.
- [ ] Tag created on that same commit and `CHANGELOG.md` upgrade notes
      written for a customer's technical team: every new setting, command, or
      console step, and whether `minimum_app_version` must be raised.
- [ ] `node tool/deployment.mjs list` shows our deployments as valid at the
      tag.
- [ ] New deployment-file fields have defaults, so customers' existing
      deployment files work unchanged.

### Step 2: Deploy our demo

Deploy `demo` from the tag by following the customer guides
([customer guide 7](customer-setup/7-upgrades-and-changes.md)), and smoke test
it with all modules on. This proves the upgrade notes before customers use
them. A security release may shorten the smoke test, but never skips QA on
`test` or the `demo` deployment.

### Step 3: Announce

Email every customer's technical contact:

- the version tag and what changed;
- the upgrade notes;
- the upgrade deadline (§4);
- the end-of-support date of the version being replaced (§5);
- whether `minimum_app_version` must be raised once the new version is in
  both stores.

### Step 4: Customers upgrade

Each customer's team upgrades with
[customer guide 7](customer-setup/7-upgrades-and-changes.md): backend first,
then apps, then store publishing, then reports the version to us. We
recommend each customer keeps a staging deployment and upgrades it first.

We answer questions, and never run the upgrade for a customer.

### Step 5: Follow up

- [ ] Each customer's reported version is recorded in the register.
- [ ] Customers who have not reported by their deadline are reminded.

## 4. Upgrade deadlines

The deadline counts from the day the version is announced. The customer
agrees to these deadlines in its contract, and its team does the upgrade.

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
upgrade notes of every version in between are applied together, preferably
on the customer's staging deployment first.

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

The customer sets it in its own Firebase project; our release announcement
says when.

| When | Set `minimum_app_version` to |
| --- | --- |
| A security fix is live in both stores | The fixed version, right away |
| A version reaches end of support | The oldest version still supported |
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

| Customer asks for | Answer |
| --- | --- |
| Their name, colors, links, region, modules on or off | Their team changes their deployment file and rebuilds on their current tag ([customer guide 7](customer-setup/7-upgrades-and-changes.md#a-change-of-your-settings)) |
| A setting that changes how a feature behaves | We add a general option to the deployment file (with a default), named after the capability, in a normal release |
| A new feature | Product owner decides. If accepted, it becomes a product module that any customer can turn on, released in a minor version |
| A fix only for them, on their old version | Not possible. The fix is made on `main` and they receive it by upgrading |
| To stay on an old version | Allowed until its end-of-support date (§5), then the deployment is unsupported |
| Code written only for them | Not possible. Never write `if (deploymentId == ...)` or customer names in code |
| That we deploy or upgrade for them, or access their accounts | Not possible. We support them with the guides, the FAQ, and answers |

**Configuration-only release.** Changing a deployment file (for example a new
link or a module switched off) does not need a new version: the customer's
team commits it to its deployment repository and rebuilds from the **same
tag** it runs. If the change needs code, it waits for a version.

## 7. Version register

The customer register ([CUSTOMER_PREREQUISITES.md](CUSTOMER_PREREQUISITES.md)
§3) records, per customer, for this policy:

| Field | Example |
| --- | --- |
| Reported version | `1.2.1`, published 2026-11-03 |
| Support status | Current / Previous until 2026-12-30 / Unsupported |
| Upgrade deadline for the latest release | 2026-11-17 |
| Deferral | none, or reason and date approved by the product owner |

Review it at the end of every release and once a month. Any customer past a
deadline is reminded, then escalated to the product owner.

## 8. Roles

| Role | In this process |
| --- | --- |
| Product owner | Approves releases, deferrals, and feature requests; owns end-of-support decisions |
| Release operator | Tags, deploys `test` and `demo`, sends the announcement |
| Customer owner | Follows up on reported versions and deadlines; handles late customers |
| Developer / on-call | Fixes on `main`, writes the changelog and upgrade notes, answers customer questions |
| Customer's technical team | Upgrades its own deployments and reports the version |

## 9. Checklists

### Each release

- [ ] QA sign-off on `test` before tagging
- [ ] Tag `vX.Y.Z` on `main`, `CHANGELOG.md` with upgrade notes for customers
- [ ] Our deployments valid at the tag; `demo` deployed from it with the customer guides
- [ ] Announcement sent: upgrade deadline, end-of-support date, `minimum_app_version` instruction
- [ ] Customers' reported versions recorded

### Each upgrade of our own environments

- [ ] Built from the release tag (`demo`), or from `main` (`dev`, `test`)
- [ ] Backend deployed before the apps
- [ ] Android and iOS released
- [ ] Tested on a device; Crashlytics and Functions logs clean

### Monthly

- [ ] Every customer on Current or Previous
- [ ] Reminders sent for versions reaching end of support within 30 days
- [ ] Overdue customers escalated
