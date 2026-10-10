# Setting Up Your Accounts

This guide is for the customer's administrator. It explains how to prepare
the accounts your app needs, step by step. Nothing here needs programming.

Your app runs on accounts that **you own and pay for**: Google Cloud and
Firebase, Apple, Google Play, and Codemagic. We never own them. You can
remove our access at any time.

## Choose how you want to work

For Google Cloud and Firebase, Apple, and Google Play, choose one option per
platform. You can choose differently for each one.

| | Option A: give us access | Option B: you do the setup |
| --- | --- | --- |
| What you do | Create the account, pay for it, and invite us | Follow the step-by-step guide yourself |
| What we do | The whole setup, in your account | Check your setup and help you on a call when you need it |
| Time for you | About 30 minutes per platform, plus the platform's own waiting time | About 1–2 hours per platform |
| Our access afterwards | The access you gave us, which you can remove at any time | None on that platform |

**Codemagic is the same in both options.** It is the service that builds and
publishes your app. You create the team and invite us, because we run the
builds there.

## The rule for secrets

Some steps create a **secret**: a key file, a password, or a private key.
Whoever creates a secret, you or us:

1. **Pastes or uploads it straight into your Codemagic team**, in the place
   the guide shows. The one exception is the Apple push key, which is uploaded
   straight into your Firebase project.
2. **Never sends it to anyone**: not by email, chat, ticket, or shared folder,
   and not to us.
3. **Deletes the downloaded file** afterwards, unless the guide says to keep
   a copy in your own password manager.

Codemagic hides a secret once it is saved. Nobody can read it back, including
us. If a secret is ever sent by mistake, tell us: we will help you replace it.

Everything you **send** us in these guides is public information, for example
a project ID, a team ID, or a Firebase configuration file that ships inside
the app anyway.

## Values we give you

Before you start, we send you these values. Use them exactly as given:

| Value | Example | Used in |
| --- | --- | --- |
| Customer ID | `acme` | Project and account names |
| App ID (Android package name and iOS bundle ID) | `com.ourcompany.acme` | Firebase, Apple, Google Play |
| App name | `Acme` | Apple, Google Play |
| Firebase project ID | `acme-prod` | Firebase |
| Data location | `europe-west1` | Firebase |
| Our team's email address | `apps-team@ourcompany.example` | Every invitation |

## The guides

**On day one, start the Apple membership** ([guide 3](3-apple.md), Part 1)
and the **Google Play account** ([guide 4](4-google-play.md), Part 1): their
approval can take days or weeks. Then follow the guides in order. Each one
ends with a **Send us** list and a **Check** list.

1. [Codemagic](1-codemagic.md): the place where every secret goes
2. [Google Cloud and Firebase](2-google-cloud-firebase.md)
3. [Apple](3-apple.md)
4. [Google Play](4-google-play.md)

The screens of these websites change from time to time. If a menu name
differs slightly from the guide, look for the closest match, or ask us.
