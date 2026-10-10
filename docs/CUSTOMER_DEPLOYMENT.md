# Customer Deployment and Bug-Fix Guide

## 1. Purpose and deployment model

This guide is for our team. It defines who does what in a customer's
deployment, and how we decide, fix, and ship a reported defect.

The model is **one shared product codebase, deployed by each customer in its
own isolated environment**:

- We maintain the product in one repository, with one version line: `main`
  and the release tags made from it.
- Every customer has its own app identifiers, Firebase project, Apple and
  Google accounts, Codemagic team, and deployment repository, all owned and
  paid for by the customer.
- **The customer's technical team deploys and runs its environment itself**,
  following [customer-setup/](customer-setup/README.md). We never access a
  customer's accounts, never deploy for a customer, and never handle its
  secrets ([CUSTOMER_PREREQUISITES.md](CUSTOMER_PREREQUISITES.md)).
- Customers build every release from a release tag, and upgrade to every new
  version within the deadlines in [RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md).
- Customer differences are only configuration, in the customer's
  `deployment.json`: identity, links, branding, region, and module switches.
  Never customer branches, forks, or customer-specific code.
- A customer request that configuration cannot cover becomes a product
  feature (a module or option any customer can enable) once the product
  owner approves it, or is declined.

**One deployment = one Firebase project = one backend.** No two deployments
ever share a project, a database, or Cloud Functions.

## 2. Responsibilities

| Who | Responsible for |
|---|---|
| Product owner (us) | Architecture, roadmap, releases, supported versions, feature decisions |
| Developers (us) | Fixes and features on `main`, release notes and upgrade notes, the tools and workflows |
| Customer owner (us) | Contract, onboarding (repository access), release and end-of-support notices, the customer register |
| Support (us) | Answers by documentation and email; keeps the guides and FAQ right |
| Customer's technical team | Its accounts, secrets, deployment repository, deployments, upgrades, store publishing, and monitoring of its environment |

The customer register (no secrets, never in this repository) is described in
[CUSTOMER_PREREQUISITES.md](CUSTOMER_PREREQUISITES.md) §3.

## 3. Customer onboarding

1. **Scope.** Record the customer's requirements, and identify which are
   standard modules or deployment settings, which are feature requests for the
   product owner, and which are out of scope. Define supported platforms,
   languages, data-residency needs, and support level.
2. **Licensing.** Do not treat client-side module switches as license
   enforcement; server-side operations must enforce entitlements where
   applicable.
3. **Onboarding** as in [CUSTOMER_PREREQUISITES.md](CUSTOMER_PREREQUISITES.md)
   §2: contract, guides, repository access, register.
4. **Deployment** by the customer's team, guides 1–6. We answer questions;
   when a question reveals a gap, we fix the guide or the FAQ.
5. **First release** reported by the customer, recorded in the register.

Never fork the repository or keep a branch for a customer, not even
temporarily.

## 4. Bug intake and triage

For every report, capture:

- customer ID and affected environment;
- app version/build number and platform/OS version;
- affected module and account role;
- steps to reproduce, expected result, actual result, and frequency;
- timestamp/time zone and relevant non-sensitive diagnostic IDs/logs;
- whether the issue blocks work, risks data/security, or has a workaround.

Do not request passwords, verification codes, access tokens, or unnecessary
personal data. Ask customers to redact sensitive screenshots/logs.

### Severity guide

Use the agreed support contract/SLA; this table is a triage baseline, not an
SLA promise.

| Severity | Examples | Default handling |
|---|---|---|
| Critical | Confirmed cross-customer data exposure, credential compromise, destructive data loss, or all users unable to use a core workflow | Escalate immediately; tell affected customers how to contain exposure in their own environment (for example switch a module off or lock down a rule); ship a security fix; coordinate security/legal response as required. |
| High | A customer's core workflow is unavailable with no reasonable workaround, or a serious security/integrity risk is suspected | Prioritize diagnosis and customer communication; prepare a targeted or shared hotfix based on scope. |
| Medium | A significant feature is impaired but a safe workaround exists | Schedule a fix based on impact and planned release window. |
| Low | Cosmetic issue, minor inconvenience, or documentation defect | Add to backlog and handle in normal maintenance. |

Severity is based on impact and risk, not on how many customers reported it.
A defect affecting one customer can still be critical; a broad defect with a
workaround may be high or medium under the support agreement.

## 5. Decide: code fix or configuration fix

Use the following decision sequence:

1. **Is data, security, billing, or shared backend behavior at risk?**
   - Yes: treat as a platform-wide incident until evidence proves the scope is
     narrower. Contain first, identify every affected deployment, then patch
     all supported customer releases that are vulnerable.
2. **Can the issue be reproduced on the shared platform with standard
   configuration?**
   - Yes: fix shared platform code and test across the supported module/config
     matrix. Release the fix to all affected customers, each on its own approved
     schedule.
3. **Is it caused only by the customer's deployment file or their
   environment (Firebase, store, Apple/Google account settings)?**
   - Yes: tell the customer what to correct, with the guide or FAQ reference
     (§6.3). If the code fails only with that customer's combination of
     settings, it is a shared defect: fix it on `main` (§6.1).
4. **Is the behavior intended differently by contract or customer
   configuration?**
   - Yes: treat it as a requirement/change request, not automatically as a
     platform bug. Confirm acceptance criteria and license/support scope.
5. **Is the customer on an old version?**
   - Check whether the defect is already fixed in the current version. If so,
     the remedy is the upgrade. We do not patch old versions.

### Deployment choice matrix

| Cause/impact | Where the change is made | Release scope |
|---|---|---|
| Code defect, whichever customer reported it | `main` | Next patch release; every customer upgrades ([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md) §3). |
| Customer deployment-file error | The customer's deployment repository, by the customer | The customer rebuilds on its current tag. |
| Customer environment error (Firebase, stores, accounts) | The customer's console, by the customer | No release; we point to the guide or FAQ step. |
| New customer-requested behavior | Product feature on `main`, if the product owner approves | Next minor release; every customer can enable it. |
| Security/data-integrity defect | `main`; tell customers about any containment they can apply in their configuration | Security patch; customers upgrade within 3 working days. |
| Third-party outage or store issue | Operational response or vendor escalation | Communicate scope and workaround; release only if a code fix is justified. |

## 6. Bug-fix and release procedure

### 6.1 Shared platform fix

1. Reproduce the defect in our own environment (`test` or `demo`) on the
   version the customer runs, from the customer's description and build log,
   and identify the first affected tag/commit. Never in the customer's
   environment.
2. Create a bug record with severity, impact, affected customers, regression
   risk, and test plan.
3. Fix the defect on the canonical platform branch with a regression test.
4. Run analysis, unit/widget tests, Functions build, security-rules tests, and
   relevant platform builds.
5. Check every deployment file for compatibility
   (`node tool/deployment.mjs list`).
6. Merge the fix into `main`. There are no other release lines to backport
   to: customers on older versions get the fix by upgrading.
7. Tag a patch release and build from that tag.
8. Deploy it to `test` and `demo` first. For incompatible schema or API
   changes, use an expand/migrate/contract sequence:
   - add backward-compatible fields/API first;
   - deploy clients/backend that tolerate old and new formats;
   - migrate data if required;
   - remove old behavior only after supported clients no longer depend on it.
9. Announce the release ([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md)
   §3), naming the defect, so the customers affected upgrade first.
10. A merged fix reaches a customer only when that customer has upgraded.
    Record each customer's reported version in the register.

### 6.2 Defect reported on an unsupported version

1. Reproduce on the current version.
2. If it does not reproduce there, the fix is the upgrade: point the
   customer to [customer guide 7](customer-setup/7-upgrades-and-changes.md).
3. If it does reproduce, fix it on `main` (§6.1); the customer receives it
   with the upgrade.

### 6.3 Configuration-only correction

1. Identify the wrong value, and the guide or FAQ step that sets it.
2. Tell the customer what to change: in its deployment repository (then a
   rebuild on its current tag,
   [customer guide 7](customer-setup/7-upgrades-and-changes.md#a-change-of-your-settings)),
   or in one of its consoles.
3. If the guide was unclear, fix the guide.

Never use a customer Remote Config value as a substitute for an authorization
rule. Remote Config is suitable for rollout policy and behavior configuration,
not for protecting customer data or server operations.

## 7. Release, rollback, and recovery

### Mobile releases

- Keep customer app identifiers and store listings distinct where the
  deployment agreement requires separate apps.
These rules are part of the customer guides; we apply them to our own
environments and explain them to customers when asked.

- Promote a tested artifact; keep its source commit and build number recorded.
- Use staged rollout where the store/channel supports it.
- A released mobile binary generally cannot be rolled back on devices already
  updated. If a defect is found, stop or pause the rollout when possible, use a
  safe server/configuration mitigation if one exists, and prepare a forward
  fix.
- Do not raise `minimum_app_version` until the replacement build is available
  through the customer's store/channel and its URL is verified. An overly high
  minimum can lock users out before the fix is installable.
- Keep the previous app version compatible with any backend changes during the
  rollout window.

### Backend, Firebase rules, and Functions

- Deploy to the explicitly named customer project; verify project ID before
  every deployment.
- Deploy only the intended Functions or rules changes. Review existing
  production rules and functions before replacement.
- Prefer backward-compatible backend releases. Keep the last known-good source
  revision and deployment instructions.
- If a backend change causes failures, revert/forward-fix the backend when
  safe. For rules, restore the reviewed previous ruleset only after checking
  whether doing so reopens access or blocks newer clients.
- For data migrations, take the backup/restore approach defined by the
  customer's data-retention agreement and validate restore procedures before
  production use.
- For our own incidents and product defects, record the timeline, customer
  communications, affected versions, and recovery verification.

## 8. Customer support and maintenance policy

Supported versions, upgrade deadlines, deferrals, and end of support are
defined in [RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md). In short:

- Only the current version and, for 60 days after a new minor or major
  version, the previous one are supported. Fixes ship only in new versions.
- Every customer upgrades to every release, by its own team; security fixes
  within 3 working days.
- A deployment that stays on a version past its end-of-support date is
  unsupported until it is upgraded.
- Separate defect correction from feature requests, integration changes, and
  environment administration. Feature requests become product features or are
  declined; there is no paid customer-only code.

## 9. Recommended automation to add later

Already in place: a validated deployment file per customer
(`deployments/<id>/deployment.json`), CI that builds from it with an explicit
`DEPLOYMENT_ID`, customer deployment folders in per-customer repositories,
customer-owned secret groups, a `readiness-check` workflow, a guard that rejects a deploy
credential for the wrong Firebase project, a guard that builds customer
deployments only from the release tag, a secret scan, and client,
Functions, and rules tests on every change. Still to add:

1. A build matrix for supported module combinations.
2. Artifact provenance recording commit SHA, deployment file version,
   dependency lockfiles, and build number.
3. Staging promotion and human approval before production deployment.
4. A way for customers to report their deployed version automatically, for
   the register.

Do not add a customer license server or remote entitlement enforcement without
first specifying licensing policy, offline behavior, expiry behavior,
entitlement signing/verification, privacy, and server-side enforcement. Never
embed a signing secret in the mobile application.

## 10. Release checklists

### New customer

- [ ] Contract signed, including self-deployment, support level, and release policy
- [ ] Guides and the starting release tag sent
- [ ] Public keys received and added as read-only deploy keys
- [ ] Customer recorded in the register
- [ ] First release reported by the customer and recorded

### Bug fix

- [ ] Severity and affected customer/version matrix assessed
- [ ] Reproduced on the current version
- [ ] Fixed on `main` with a regression test; relevant checks pass
- [ ] Every deployment file still valid
- [ ] Patch release tagged; `test` and `demo` deployed from it
- [ ] Release announced with its upgrade deadline
- [ ] Customers' reported versions recorded; late customers reminded

### Configuration correction

- [ ] Wrong value and its guide step identified
- [ ] Customer told what to change, with the reference
- [ ] Guide or FAQ improved if it was unclear
