# Customer Prerequisites and Readiness Check

This guide is for the deployment team. A customer deployment
([DEPLOYMENT.md](DEPLOYMENT.md) §4) **does not start** until everything in
this guide has been collected from the customer and validated (§4). This
avoids starting work that then stops for weeks on a missing account or an
access request.

Every account below belongs to the customer: Google Cloud and Firebase,
Apple, Google Play, and Codemagic. The customer pays for them and stays their
owner. We only get access, and the customer can remove that access at any
time.

## 1. Start early: lead times

Send the customer the list in §3 when the contract is signed. Some items take
time that we cannot shorten:

| Item | Typical delay | Why |
| --- | --- | --- |
| Apple Developer Program, organization membership | 1–3 weeks | Apple checks the organization; it needs a D-U-N-S number, which can itself take days to obtain |
| Google Play Console, organization account | Several days | Google verifies the organization's identity |
| Google Play Console, **personal** account | Do not use | New personal accounts must run a closed test with at least 12 testers for 14 days before they can publish to production. Ask for an organization account |
| Firebase, Google Cloud billing, Codemagic | Same day | — |
| Custom email-link domain (optional) | Depends on the customer's IT team | They must host files on the domain and change DNS |

## 2. Permanent choices

Confirm these in writing before the deployment starts. They cannot be
changed later without a new app or a data migration:

| Choice | Why it is permanent |
| --- | --- |
| App ID (`appId`), for example `<our-reverse-domain>.<customer-id>` | Android and iOS bind the store listing to it after the first release |
| Firestore location and Cloud Functions region (`firebase.functionsRegion`) | The Firestore location cannot be changed after the database is created; choose it to match the customer's data-residency needs |
| Firebase project ID | Fixed when the project is created |

## 3. What to collect

Each line says who provides it and how we validate it in §4.

### A. Contract and people

| Item | Provided by | How we validate |
| --- | --- | --- |
| Signed contract, including support level and acceptance of the release and support policy ([RELEASE_AND_SUPPORT.md](RELEASE_AND_SUPPORT.md)) | Customer + us | Copy filed; reference in the deployment register |
| Business owner, technical contact, acceptance approver, billing contact (names and emails) | Customer | Recorded in the register |

### B. App identity and content

| Item | Provided by | How we validate |
| --- | --- | --- |
| App name (1–30 characters) | Customer | `node tool/deployment.mjs check` passes with it |
| App icon: 1024×1024 PNG, no transparency | Customer | Opened and checked for size and transparency |
| Brand color (`#RRGGBB`) | Customer | `check` passes |
| Privacy policy URL, public HTTPS. **Required by both stores** | Customer | Opens in a private browser window |
| Terms of service URL (optional) and support email | Customer | URL opens; test email to the support address is received |
| Modules to enable (see [docs/README.md](README.md), "Optional feature modules") | Customer, with us | `check` passes with the `features` section |
| Data region (Firestore location and Functions region) | Customer, with us | Written confirmation (§2) |
| Store listing: short and full description, category, contact details, screenshots (we can produce them) | Customer | Complete in the shared folder |
| Store questionnaires: Google Play content rating and Data safety, Apple App Privacy. We prepare the answers for the enabled modules, the customer confirms them | Us + customer | Customer's written confirmation |
| Custom email-link domain (optional) | Customer | They can host `/.well-known/` files and change DNS on it |

### C. Google Cloud and Firebase

| Item | Provided by | How we validate |
| --- | --- | --- |
| Google Cloud organization, or a Google account in the customer's name | Customer | We see the organization or account owner in the IAM page |
| Cloud Billing account with the customer's payment method | Customer | Billing page shows the account as active |
| Firebase project under the customer's account (`<customer-id>-prod`), linked to that billing account, on the **Blaze** plan | Customer, or us during a shared call | Firebase console shows the project on Blaze; owner is the customer |
| A budget alert on the billing account | Customer | Visible in Billing → Budgets |
| Access for our team's Google group: **Firebase Admin**. For the setup only, also **Project IAM Admin**, **Service Account Admin**, and **Service Account Key Admin**, removed after setup | Customer | We open the project with our account and the roles show in IAM |

### D. Apple

| Item | Provided by | How we validate |
| --- | --- | --- |
| Apple Developer Program membership as an organization, fee paid | Customer | Membership page shows the organization and an expiry date |
| Latest Apple Developer Program License Agreement accepted by the Account Holder | Customer | App Store Connect → Business shows no pending agreement (uploads fail otherwise) |
| Our team invited in App Store Connect → Users and Access as **Admin** (or App Manager with access to Certificates, Identifiers & Profiles) | Customer | We sign in and can open Certificates, Identifiers & Profiles |
| A team App Store Connect API key with **App Manager** or **Admin** access, pasted straight into the customer's Codemagic team (§F) | Customer, or us with that access | Codemagic accepts the key (§4) |

### E. Google Play

| Item | Provided by | How we validate |
| --- | --- | --- |
| Google Play Console **organization** developer account, fee paid, identity verification finished | Customer | Play Console shows no verification banner |
| Our team invited in Users and permissions as **Admin**, or with release permissions for the app | Customer | We sign in and see the account |
| Google Play Android Developer API enabled in the customer's Google Cloud project, a service account with a JSON key, and that service account invited in Play Console with release permissions | Customer, or us with the roles in §C | The service account is listed in Users and permissions |

### F. Codemagic

| Item | Provided by | How we validate |
| --- | --- | --- |
| A Codemagic team owned by the customer, with billing set up (iOS builds need macOS build minutes) | Customer | Team billing page shows an active plan or payment method |
| Our team invited as **Admin** (needed to create environment groups and signing identities) | Customer | We open the team settings |
| Access to this repository from that team, with a **read-only deploy key for that customer only** | Us | The team's application lists the repository's branches and tags |

## 4. Readiness check (go / no-go)

The release operator runs this check, with the customer's technical contact
if possible, before [DEPLOYMENT.md](DEPLOYMENT.md) §4 starts.

1. Go through every line of §3 and do its validation yourself, signed in with
   our own account. "The customer said it is done" does not count.
2. In the customer's Codemagic team, confirm we can create a test environment
   group, then delete it.
3. Record the result in the deployment register: date, operator, and every
   item as ✅ or ❌.
4. Decide:
   - **Go**: every item in A–F is ✅. The product owner approves, and the
     deployment starts.
   - **No-go**: send the customer the list of ❌ items, each with what is
     missing and who must do it. Run the check again when they report it is
     done.

There are no partial starts. A deployment that starts without Apple access,
for example, stops later at the iOS release and leaves a half-configured
customer.

## 5. After the deployment

Once the deployment is released, remove the setup-only roles (§C), and
record the access we keep in the register: Firebase Admin, Apple and Play
Console access, and Codemagic Admin. When support ends, the customer removes
all of it ([DEPLOYMENT.md](DEPLOYMENT.md) §3, "Offboarding").

## 6. Checklist to send to the customer

Send this list with the contract. It uses no internal terms.

- [ ] Signed contract and four contacts: business owner, technical contact,
      acceptance approver, billing contact
- [ ] App name, 1024×1024 app icon, brand color
- [ ] Public privacy policy page (required by Apple and Google), support
      email, terms of service (optional)
- [ ] Modules wanted and the region where user data must be stored
- [ ] Store texts: short and full description, category
- [ ] Google Cloud: a billing account with your payment method; we will
      create the Firebase project with you
- [ ] Apple Developer Program membership for your organization (start now:
      it can take 1–3 weeks), latest agreement accepted, our team invited
- [ ] Google Play Console account for your organization, identity verified,
      our team invited
- [ ] Codemagic team for your organization with billing, our team invited as
      Admin
