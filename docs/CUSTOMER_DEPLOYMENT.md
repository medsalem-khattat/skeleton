# Customer Deployment and Bug-Fix Guide

## 1. Purpose and deployment model

This guide defines how to configure, test, release, and support a dedicated
deployment for each customer, and how to decide whether a fix goes to one
customer or to every customer.

The recommended model is **one shared product codebase with customer-specific
configuration and isolated deployments**:

- Maintain the platform core and standard modules in one canonical repository.
- Give every customer their own app identifiers, Firebase project, credentials,
  release configuration, and deployment record.
- Pin each customer release to a known platform version and commit.
- Put customer-only behavior in an isolated extension/module or configuration
  layer, not in shared core code.
- Keep customer changes out of the shared product unless they are approved as
  reusable roadmap features.

**One deployment = one Firebase project = one backend.** Every deployment gets
its own Firebase project. The customer owns that project and pays its Firebase
billing; no two deployments ever share a project, a database, or Cloud
Functions. As part of each deployment, we create the customer's Firebase
project under the customer's account and choose the app identifiers (see
[Step 3](#step-3-create-the-customer-owned-firebase-project)).

Each deployment is one file, `deployments/<id>/deployment.json`, plus its
public Firebase client files. One `codemagic.yaml` builds every deployment,
and every secret stays in the customer's accounts. The technical steps are in
[DEPLOYMENT.md](DEPLOYMENT.md); this guide covers ownership, policy, and
support.

## 2. Ownership and deployment records

Assign these responsibilities before the first customer release:

| Role | Responsibility |
|---|---|
| Product/platform owner | Owns shared architecture, roadmap, supported platform versions, and release approval. |
| Customer owner | Confirms requirements, acceptance criteria, branding, and customer-specific configuration. |
| Developer/on-call | Reproduces and fixes defects, identifies affected deployments, and prepares releases. |
| Release operator | Controls signing credentials, Firebase deployment, store submission, and release records. |

Maintain a private deployment register outside source control. Record at least:

| Field | Example |
|---|---|
| Customer ID | `customer-abc` (use a stable internal ID, not a display name in code) |
| Contract/license | Plan, licensed modules, dates, support level, user/device limits |
| App identity | Display name, Android application ID, iOS bundle ID |
| Firebase environment | Project ID per environment (development/staging/production) |
| Firebase ownership | Customer Google account or organization that owns each project, customer billing account, our granted IAM roles and when they were granted |
| Release | Platform version/tag, commit SHA, customer extension version, build number |
| Enabled modules | Standard and customer-specific modules, with dependencies |
| Deployment state | Planned, testing, submitted, released, rolled back/forward-fixed |
| Approvals | Customer acceptance and internal release approval |

Never put customer secrets, signing credentials, service account keys, or
personal data in this register if it is stored in source control. Keep the
actual register and credentials in approved access-controlled systems.

## 3. Customer onboarding and first deployment

### Step 1: Confirm scope and acceptance

1. Record the customer requirements and expected user workflows.
2. Identify which requested capabilities are:
   - already supported standard modules;
   - new reusable platform roadmap items; or
   - customer-specific extensions/integrations.
3. Define acceptance criteria, supported platforms, languages, environments,
   data residency/retention requirements, support level, and release cadence.
4. Agree how licensed modules and contract expiry are handled. Do not treat
   client-side feature flags as license enforcement; server-side operations and
   customer data access must enforce entitlements where applicable.
5. Identify external dependencies and who owns their configuration, including
   Apple/Google developer accounts, Firebase billing, APNs, App Check, domains,
   and store listings.

### Step 2: Create the deployment

Follow [DEPLOYMENT.md](DEPLOYMENT.md) §4. In policy terms:

1. Start from a reviewed platform tag, not an arbitrary developer branch.
2. Assign a stable customer identifier (the deployment ID) and a unique app
   display name.
3. We choose the app identifier, the same for Android and iOS, for example
   `<our-reverse-domain>.<customer-id>`. It must be unique, is permanent once
   the app is published, and is recorded in the deployment register before
   the Firebase apps are registered. Confirm the customer owns or controls
   the related store listings.
4. Branding, links, and module switches go in
   `deployments/<id>/deployment.json`; `node tool/deployment.mjs check <id>`
   validates module dependencies and landing destinations.
5. Keep customer-only code isolated in an extension package or module. Avoid
   editing shared core just to customize text, color, URLs, or enabled modules.
6. Record the exact base platform tag and customer extension version.

Do not create an untracked long-lived fork for ordinary customization. If an
exceptional core divergence is unavoidable, document its owner, reason,
upstream synchronization plan, and expiry/review date.

### Step 3: Create the customer-owned Firebase project

Each deployment has its own backend: a Firebase project that the customer
owns and pays for. Creating it is part of our deployment work
([DEPLOYMENT.md](DEPLOYMENT.md) §4, Step 1):

1. **Customer account.** Use the customer's Google account or Google Cloud
   organization. If the customer has none, create one with the customer, in
   the customer's name and with the customer's contact address. Never create
   the project under our own account.
2. **Billing.** The customer provides a Cloud Billing account with their own
   payment method. Cloud Functions require the Blaze plan.
3. **Project.** Created under the customer's account (`<customer-id>-prod`)
   and linked to the customer's billing account. When the support model
   requires environment isolation, also create `<customer-id>-staging` as a
   separate deployment.
4. **Our access.** The customer grants our team the narrowest IAM roles needed
   (for example **Firebase Admin**) and stays the project **Owner**. Record the
   roles and the date in the deployment register; the customer removes them
   when the support agreement ends.
5. Seed no real user data into test environments. Use synthetic test accounts.

### Step 4: Configure release credentials and CI

All secrets are created in and stay in the customer's accounts; see
[DEPLOYMENT.md](DEPLOYMENT.md) §3 for the full inventory.

1. The workflows run in a Codemagic team owned by the customer, with our
   staff invited as members. Limit membership to staff who need it.
2. The customer's signing credentials, App Store Connect key, and Firebase
   deploy credential are stored only there, as secure variables or code
   signing identities. Never download them to personal machines or commit them.
3. The `deployment` group's `DEPLOYMENT_ID` selects the deployment;
   `backend-deploy` refuses to run unless the deploy credential belongs to
   that deployment's Firebase project.
4. Every build runs dependency installation, static analysis, client tests,
   and, for the backend, Functions and rules tests.
5. Check the produced artifact identity and signing profile before submission.
   `ios-release` verifies the profile's entitlements automatically.

### Step 5: Verify, accept, and release

1. Deploy backend changes to the customer's staging project first.
2. Install the exact candidate build on supported test devices.
3. Run acceptance tests with customer test accounts and test data.
4. Test relevant permissions, email links, push, offline/retry behavior,
   update policy, and account lifecycle features.
5. Obtain customer acceptance for customer-visible changes.
6. Promote the same reviewed commit and configuration to production; do not
   rebuild from a different source revision after acceptance.
7. Submit the signed artifact to the agreed distribution channel and monitor
   release status.
8. Record the release tag, commit, artifact/build number, Firebase deployment,
   configuration version, approvals, and date in the deployment register.
9. Monitor Crashlytics, Functions logs, Firebase usage, support reports, and
   store rollout status.

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
| Critical | Confirmed cross-customer data exposure, credential compromise, destructive data loss, or all users unable to use a core workflow | Escalate immediately; contain exposure first; consider disabling affected server capability; coordinate security/legal response as required. |
| High | A customer's core workflow is unavailable with no reasonable workaround, or a serious security/integrity risk is suspected | Prioritize diagnosis and customer communication; prepare a targeted or shared hotfix based on scope. |
| Medium | A significant feature is impaired but a safe workaround exists | Schedule a fix based on impact and planned release window. |
| Low | Cosmetic issue, minor inconvenience, or documentation defect | Add to backlog and handle in normal maintenance. |

Severity is based on impact and risk, not on how many customers reported it.
A defect affecting one customer can still be critical; a broad defect with a
workaround may be high or medium under the support agreement.

## 5. Decide: customer-only fix or all-customer fix

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
3. **Is it caused by a customer-only module, data mapping, integration,
   branding/configuration, or customer-specific environment?**
   - Yes: implement the fix in that isolated customer extension/configuration.
     Do not alter shared core unless a reusable defect is found.
4. **Is the behavior intended differently by contract or customer
   configuration?**
   - Yes: treat it as a requirement/change request, not automatically as a
     platform bug. Confirm acceptance criteria and license/support scope.
5. **Is the same issue likely to recur for other customers?**
   - If so, consider a configurable standard capability or a shared feature
     after product review. Do not copy customer-specific data or business rules
     into the core by default.

### Deployment choice matrix

| Cause/impact | Code/configuration location | Release scope |
|---|---|---|
| Shared core defect | Canonical platform repository | Patch every affected supported customer deployment; stagger if operationally necessary. |
| Customer extension defect | That customer's isolated extension | Patch that customer's deployment only. |
| Customer environment/configuration error | Customer environment/deployment config | Correct and validate that environment; no app release unless code changes are needed. |
| New customer-requested behavior | Extension or approved shared roadmap feature | Customer-only unless product owner approves standardization. |
| Shared security/data-integrity defect | Shared core/backend; contain via server/config if possible | All affected deployments; prioritize regardless of release calendar. |
| Third-party outage or store issue | Operational response or vendor escalation | Communicate scope and workaround; release only if a code fix is justified. |

## 6. Bug-fix and release procedure

### 6.1 Shared platform fix

1. Reproduce on the deployed version and identify the first affected platform
   tag/commit.
2. Create a bug record with severity, impact, affected customers, regression
   risk, and test plan.
3. Fix the defect on the canonical platform branch with a regression test.
4. Run analysis, unit/widget tests, Functions build, security-rules tests, and
   relevant platform builds.
5. Review customer extensions/configurations for compatibility.
6. Merge the fix into the canonical release line. Backport the same reviewed
   fix to any still-supported release lines that need it; avoid parallel
   hand-edited variants.
7. Build a candidate from a tagged commit.
8. Deploy backend/rules changes to staging first. For incompatible schema or
   API changes, use an expand/migrate/contract sequence:
   - add backward-compatible fields/API first;
   - deploy clients/backend that tolerate old and new formats;
   - migrate data if required;
   - remove old behavior only after supported clients no longer depend on it.
9. Release to each affected customer using that customer's configuration,
   credentials, Firebase project, and distribution channel.
10. Verify and record each deployment separately. A merged code fix is not
    deployed to a customer until that customer's release is built and promoted.

### 6.2 Customer-only fix

1. Verify that the defect is confined to the customer's extension or
   environment.
2. Branch from the exact customer release tag/commit currently deployed.
3. Make the smallest isolated change in the customer extension/configuration;
   do not silently change shared platform behavior.
4. Add regression tests for the customer's scenario and any shared interface
   that the extension consumes.
5. Check that the patch does not expose customer data, secrets, identifiers, or
   code to other customer builds.
6. Build and test only against that customer's staging environment and
   configuration, while still running all relevant shared tests.
7. Obtain customer acceptance when the contract/process requires it.
8. Release a customer-specific version with a traceable tag/build number.
9. Record the fix and monitor the deployment.
10. If the root cause reveals a shared defect, upstream the fix into the
    canonical platform and follow the shared-platform process for other
    deployments.

### 6.3 Configuration-only correction

1. Confirm the expected configuration against the approved customer record.
2. Change only the target customer's environment/configuration.
3. Review access, impact, and rollback values before publishing.
4. Test against staging or a safe test account.
5. Publish, verify behavior, and record who changed what and when.

Never use a customer Remote Config value as a substitute for an authorization
rule. Remote Config is suitable for rollout policy and behavior configuration,
not for protecting customer data or server operations.

## 7. Release, rollback, and recovery

### Mobile releases

- Keep customer app identifiers and store listings distinct where the
  deployment agreement requires separate apps.
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
- Record incident timeline, customer communications, affected versions, and
  recovery verification.

## 8. Customer support and maintenance policy

- Support applies to the versions and modules included in the customer's
  agreement. State the supported release window and end-of-support process.
- Separate defect correction from feature requests, paid customization,
  integration changes, and environment administration.
- For customer-specific modules, record code ownership, support owner,
  dependency versions, and compatibility with platform upgrades.
- Before a platform release, run compatibility tests for each supported
  extension and module configuration.
- When a customer is several platform versions behind, estimate and schedule
  upgrades; do not assume every intermediate migration is safe without tests.
- A customer can defer routine releases according to the agreement, but
  security fixes and end-of-support expectations need a documented escalation
  path.

## 9. Recommended automation to add later

Already in place: a validated deployment file per customer
(`deployments/<id>/deployment.json`), CI that builds from it with an explicit
`DEPLOYMENT_ID`, customer-owned secret groups, a guard that rejects a deploy
credential for the wrong Firebase project, a secret scan, and client,
Functions, and rules tests on every change. Still to add:

1. A build matrix for supported module combinations and customer extensions.
2. Artifact provenance recording commit SHA, deployment file version,
   dependency lockfiles, and build number.
3. Staging promotion and human approval before production deployment.
4. A deployment register/inventory for customer app versions and Firebase
   backend versions.

Do not add a customer license server or remote entitlement enforcement without
first specifying licensing policy, offline behavior, expiry behavior,
entitlement signing/verification, privacy, and server-side enforcement. Never
embed a signing secret in the mobile application.

## 10. Release checklists

### New customer

- [ ] Scope, acceptance, support, and license recorded
- [ ] App identifiers and distribution ownership confirmed
- [ ] Customer extension boundary and base platform version recorded
- [ ] App identifier chosen and recorded
- [ ] Firebase project created under the customer's account, linked to the customer's billing account (Blaze), our IAM roles recorded
- [ ] Firebase providers provisioned
- [ ] Rules, Functions, App Check, Remote Config, and domains reviewed
- [ ] CI credentials isolated and workflow target verified
- [ ] Staging acceptance completed
- [ ] Signed artifact identity verified
- [ ] Production release and backend versions recorded
- [ ] Monitoring and support contacts ready

### Shared bug fix

- [ ] Severity and affected customer/version matrix assessed
- [ ] Regression test added and relevant checks pass
- [ ] Compatibility with active extensions verified
- [ ] Candidate built from a tagged commit
- [ ] Staging backend/client validation completed
- [ ] Every affected customer deployment scheduled and tracked
- [ ] Store rollout/forward-fix strategy ready
- [ ] Release records and monitoring updated

### Customer-only bug fix

- [ ] Root cause proven customer-specific
- [ ] Patch based on the deployed customer commit
- [ ] Shared interfaces and common tests remain passing
- [ ] No customer-only data/configuration leaks into other builds
- [ ] Staging validation and customer acceptance completed as required
- [ ] Customer release tagged and deployed
- [ ] Shared root cause upstreamed if discovered
