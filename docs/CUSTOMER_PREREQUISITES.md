# Customer Onboarding

This guide is for our team. It defines what we do, and what we never do, when
a new customer deploys the app.

## 1. The rule: customers deploy themselves

Every customer deployment is done by the **customer's own technical team**,
in the customer's own accounts, following the step-by-step guides in
[customer-setup/](customer-setup/README.md). The customer owns and pays for
every account and is responsible for its environment.

Our team:

- **never** asks for, accepts, or uses access to a customer account (Google
  Cloud, Firebase, Apple, Google Play, Codemagic, or their Git hosting);
- **never** deploys, builds, or configures anything in a customer's
  environment;
- **never** asks for, receives, or keeps a customer secret (keys, key files,
  passwords), or screenshots that show one;
- **supports** the customer with the guides, the
  [FAQ](customer-setup/FAQ.md), releases, and answers to their questions.

If a customer sends us a secret by mistake: do not use it, delete the
message, and ask them to replace the secret
([FAQ](customer-setup/FAQ.md#a-secret-was-sent-by-mistake-what-now)).

## 2. Onboarding steps (our side)

1. **Contract.** Signed, including: the customer deploys and runs its own
   environment, the support level (documentation and email), and the release
   and support policy ([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md)):
   upgrade deadlines and end of support.
2. **Kick-off.** Send the customer's technical contact:
   - the guides of [customer-setup/](customer-setup/README.md) (export the
     folder to PDF: they cannot read the repository before step 3);
   - the release tag to start from (the latest);
   - our support email address.

   Point out the two long lead times: Apple organization enrollment (1–3
   weeks) and Google Play organization verification (several days).
3. **Source code access.** The customer sends us **public** SSH keys (`.pub`
   files, starting with `ssh-ed25519`): one for their Codemagic application
   ([guide 1, Step 3](customer-setup/1-codemagic.md#step-3-get-access-to-the-apps-source-code)),
   and one per computer of their technical team
   ([guide 2, Step 1](customer-setup/2-deployment-repository.md#step-1-prepare-your-computer)).
   For each:
   1. Check that it is a public key (one line starting with `ssh-`). If it is
      a private key (`-----BEGIN ... PRIVATE KEY-----`), do not add it: delete
      the message and ask for a new pair.
   2. Add it on GitHub: repository → **Settings → Deploy keys → Add deploy
      key**, titled `<customer-id>-codemagic` or `<customer-id>-<person>`,
      with **Allow write access unticked**.
   3. Confirm to the customer within one working day.
4. **Record** the customer in the customer register (§3).
5. **Support** during the deployment: answer questions with the guide and FAQ
   references. Ask for the guide and step number, the error message, and the
   Codemagic build log (it never shows secrets). When a question shows a gap
   in the guides or the FAQ, fix the documentation.
6. **First release.** The customer tells us the version and date they
   published ([guide 6, Step 8](customer-setup/6-first-release.md#step-8-tell-us)).
   Record it.
7. **Offboarding.** When the contract ends, delete the customer's deploy keys
   from the repository. Everything else is theirs; there is nothing else to
   remove.

## 3. Customer register

Kept in an access-controlled system, never in this repository. It contains
no secrets.

| Field | Example |
| --- | --- |
| Customer ID | `acme` |
| Contacts | Business owner, technical contact, billing contact |
| Contract | Dates, support level, modules |
| Deploy keys | Titles and dates added |
| Reported version | `1.2.1`, published 2026-11-03 |
| Support status | Current / Previous until 2026-12-30 / Unsupported ([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md) §5) |
| Upgrade deadline | For the latest release |

## 4. What the customer decides

The customer decides every value of its deployment, including the permanent
ones ([guide 2, Step 2](customer-setup/2-deployment-repository.md#step-2-choose-your-values)):
App ID (in the customer's own reverse domain), Firebase project ID, data
location, deployment ID, app name, and modules. We advise when asked; we do
not choose.

## 5. Keeping the guides right

The guides are the product for the customer's technical team. After every
customer deployment, and whenever a store, Firebase, or Codemagic screen
changes:

- update the step or the [FAQ](customer-setup/FAQ.md) where a customer got
  stuck;
- deploy our own `demo` environment by following the customer guides, not our
  internal shortcuts, at least once per minor version
  ([DEPLOYMENT_RUNBOOK.md](DEPLOYMENT_RUNBOOK.md)).
