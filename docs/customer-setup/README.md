# Deploying Your App: Guide for Your Technical Team

This guide is for the customer's technical team. It takes you through the
whole deployment of your app, step by step: accounts, backend, Android and
iOS builds, store publishing, and later upgrades.

**Your team does every step, in your own accounts.** You own and pay for
every account (Codemagic, Google Cloud and Firebase, Apple, Google Play), and
you are responsible for your environment. We never ask for access to your
accounts, never log in to them, and never deploy for you. We support you with
these guides, the [FAQ](FAQ.md), and answers to your questions.

## What we provide

| We provide | How |
| --- | --- |
| The app's source code, at each release | Read-only access to our repository (guide 1, Step 3) |
| Releases | A version tag such as `v1.2.0`, with release notes and upgrade notes |
| Build and deployment automation | The workflows in Codemagic and the tools in the repository |
| Documentation and support | These guides, the [FAQ](FAQ.md), and answers by email |

## What your team needs

- **People:** one person who can create and pay for company accounts (an
  administrator), and one technical person comfortable with a terminal and
  Git. No app development is needed: you configure, you never change code.
- **A computer** (Windows, macOS, or Linux) with:
  - [Git](https://git-scm.com/downloads);
  - [Node.js 22](https://nodejs.org/) (LTS);
  - Java 17 or later, only to create the Android upload key (it comes with
    [Android Studio](https://developer.android.com/studio), or use
    [Temurin](https://adoptium.net/)).
- **A Git hosting account** for a small private repository of your own
  (GitHub, GitLab, or Bitbucket).

## The rule for secrets

Some steps create a **secret**: a key file, a password, or a private key. Your
team:

1. **Pastes or uploads it straight into your Codemagic team**, in the place
   the guide shows. The one exception is the Apple push key, which goes
   straight into your Firebase project.
2. **Never sends it to anyone**, including us: not by email, chat, ticket, or
   shared folder. We will never ask for one.
3. **Deletes the downloaded file** afterwards, unless the guide says to keep
   it in your company's password manager.

Codemagic hides a secret once it is saved; nobody can read it back. If a
secret is ever exposed, replace it (see the [FAQ](FAQ.md#a-secret-was-sent-by-mistake-what-now)).

## The guides

**On day one, start the two account approvals that take time:** the Apple
Developer Program ([guide 4](4-apple.md), Steps 1–2: 1–3 weeks) and the
Google Play developer account ([guide 5](5-google-play.md), Step 1: several
days). Then follow the guides in order:

| # | Guide | Hands-on time |
| --- | --- | --- |
| 1 | [Codemagic](1-codemagic.md): the build service, where every secret goes | 20 min |
| 2 | [Your deployment repository](2-deployment-repository.md): your app's settings | 30 min |
| 3 | [Google Cloud and Firebase](3-google-cloud-firebase.md): your backend | 20 min by command, or 1 hour in the console |
| 4 | [Apple](4-apple.md) | 45 min |
| 5 | [Google Play](5-google-play.md) | 1 hour |
| 6 | [First release](6-first-release.md): check, build, publish | 1.5 hours, most of it waiting for builds |
| 7 | [Upgrades and changes](7-upgrades-and-changes.md): every new version afterwards | 30 min per version |

Each guide ends with a **Check** list. Do not start the next guide until every
line of it is ticked.

The screens of these websites change from time to time. If a menu name
differs slightly from the guide, look for the closest match, or check the
[FAQ](FAQ.md).

## Getting help

1. Look in the [FAQ](FAQ.md): it covers the common errors of each step.
2. Write to us with the guide and step number, what you did, and the error
   message or the log of the failed Codemagic build. Build logs never show
   your secrets.
3. Never send us passwords, keys, key files, or screenshots that show them.
