#!/usr/bin/env node
// Selects, checks, and deploys one deployment described by
// deployments/<id>/deployment.json. See docs/DEPLOYMENT.md.
//
//   node tool/deployment.mjs list
//   node tool/deployment.mjs check  [id]
//   node tool/deployment.mjs use    [id]
//   node tool/deployment.mjs deploy-backend [id]
//   node tool/deployment.mjs release-check  [id]
//   node tool/deployment.mjs fetch  [id]
//
// [id] defaults to the DEPLOYMENT_ID environment variable.
// Our own deployments are committed here; a customer's deployment folder
// comes from that customer's own repository (see docs/DEPLOYMENT.md).
// Secrets never live in a deployment folder; this script refuses to continue
// if it finds one.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const deploymentsDir = path.join(root, "deployments");
const frontend = path.join(root, "frontend");

/**
 * Public Firebase client files, as downloaded from the Firebase console:
 * deployment copy -> app location. `use` generates firebase_options.dart and
 * the FlutterFire firebase.json from them.
 */
const firebaseFiles = {
  "google-services.json": "android/app/google-services.json",
  "GoogleService-Info.plist": "ios/Runner/GoogleService-Info.plist",
};

/** deployment.json feature key -> compile-time define read by AppFeatures. */
const featureDefines = {
  authentication: "FEATURE_AUTHENTICATION",
  phoneVerification: "FEATURE_PHONE_VERIFICATION",
  home: "FEATURE_HOME",
  profile: "FEATURE_PROFILE",
  settings: "FEATURE_SETTINGS",
  appearanceSettings: "FEATURE_APPEARANCE_SETTINGS",
  languageSettings: "FEATURE_LANGUAGE_SETTINGS",
  deviceAuthentication: "FEATURE_DEVICE_AUTHENTICATION",
  pushNotifications: "FEATURE_PUSH_NOTIFICATIONS",
  notificationInbox: "FEATURE_NOTIFICATION_INBOX",
  crashReporting: "FEATURE_CRASH_REPORTING",
};

/** Content that must never be committed with a deployment. */
const secretPatterns = [
  [/-----BEGIN [A-Z ]*PRIVATE KEY-----/, "a private key"],
  [/"private_key"\s*:/, "a service-account key"],
  [/"type"\s*:\s*"service_account"/, "a service-account key"],
];
const secretFileExtensions = [".p8", ".p12", ".jks", ".keystore", ".pem", ".mobileprovision"];

class DeploymentError extends Error {}

function fail(message) {
  throw new DeploymentError(message);
}

function deploymentIdFrom(arg) {
  const id = arg ?? process.env.DEPLOYMENT_ID;
  if (!id) fail("Pass a deployment ID or set DEPLOYMENT_ID.");
  if (!/^[a-z0-9][a-z0-9-]*$/.test(id)) fail(`Invalid deployment ID "${id}".`);
  return id;
}

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    fail(`Cannot read ${path.relative(root, file)}: ${error.message}`);
  }
}

function plistValue(plist, key) {
  return plist.match(new RegExp(`<key>${key}</key>\\s*<string>([^<]*)</string>`))?.[1];
}

/** Loads and validates a deployment; returns it with defaults applied. */
function load(id) {
  const dir = path.join(deploymentsDir, id);
  const file = path.join(dir, "deployment.json");
  if (!fs.existsSync(file)) fail(`No deployment "${id}" (expected ${path.relative(root, file)}).`);
  const config = readJson(file);
  const errors = [];
  const check = (condition, message) => condition || errors.push(message);

  check(config.deploymentId === id, `deploymentId must be "${id}" (the folder name).`);
  check(typeof config.appName === "string" && config.appName.trim().length > 0 && config.appName.length <= 30
    && !/[<>&"'$\\\n]/.test(config.appName),
    "appName must be 1-30 characters without < > & \" ' $ or \\.");
  check(/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/.test(config.appId ?? ""),
    "appId must be a reverse-domain ID such as com.example.app (lowercase letters, digits, _).");

  const firebase = config.firebase ?? {};
  check(/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(firebase.projectId ?? ""),
    "firebase.projectId must be a valid Firebase project ID.");
  firebase.authActionHost ??= `${firebase.projectId}.firebaseapp.com`;
  check(/^[a-z0-9.-]+\.[a-z]{2,}$/.test(firebase.authActionHost), "firebase.authActionHost must be a host name.");
  firebase.functionsRegion ??= "us-central1";
  check(/^[a-z]+-[a-z]+\d+$/.test(firebase.functionsRegion),
    "firebase.functionsRegion must be a Cloud Functions region such as europe-west1.");

  const links = config.links ?? {};
  for (const key of ["privacyPolicyUrl", "termsOfServiceUrl", "authActionContinueUrl"]) {
    links[key] ??= "";
    check(links[key] === "" || /^https:\/\/\S+$/.test(links[key]), `links.${key} must be empty or an https URL.`);
  }
  links.supportEmail ??= "";
  check(links.supportEmail === "" || /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(links.supportEmail),
    "links.supportEmail must be empty or an email address.");

  const api = config.api ?? {};
  api.baseUrl ??= "";
  check(api.baseUrl === "" || /^https:\/\/\S+$/.test(api.baseUrl), "api.baseUrl must be empty or an https URL.");

  config.internal ??= false;
  check(typeof config.internal === "boolean", "internal must be true or false.");

  config.seedColor ??= "#3F51B5";
  check(/^#[0-9A-Fa-f]{6}$/.test(config.seedColor), "seedColor must look like #3F51B5.");

  const features = config.features ?? {};
  for (const [key, value] of Object.entries(features)) {
    check(key in featureDefines, `features.${key} is not a known module.`);
    check(typeof value === "boolean", `features.${key} must be true or false.`);
  }
  for (const key of Object.keys(featureDefines)) features[key] ??= true;
  // Same landing-destination rules as AppFeatures.validate().
  const settingsEnabled = (features.settings && (features.authentication || features.appearanceSettings
    || features.languageSettings)) || features.pushNotifications;
  if (features.authentication) {
    check(features.home || features.profile || features.notificationInbox || settingsEnabled,
      "With authentication on, enable home, profile, notificationInbox, or a settings module.");
  } else {
    check(features.home || settingsEnabled, "With authentication off, enable home or a settings module.");
  }

  // Public Firebase client files must belong to this project and app ID.
  const firebaseDir = path.join(dir, "firebase");
  const missing = Object.keys(firebaseFiles).filter((name) => !fs.existsSync(path.join(firebaseDir, name)));
  for (const name of missing) errors.push(`Missing deployments/${id}/firebase/${name}.`);
  for (const name of ["firebase_options.dart", "firebase.json"]) {
    check(!fs.existsSync(path.join(firebaseDir, name)),
      `Remove deployments/${id}/firebase/${name}; it is now generated by "use".`);
  }
  let firebaseApps;
  if (missing.length === 0) {
    const services = readJson(path.join(firebaseDir, "google-services.json"));
    const android = services.client?.find((c) => c.client_info?.android_client_info?.package_name === config.appId);
    check(services.project_info?.project_id === firebase.projectId,
      "google-services.json belongs to a different Firebase project.");
    check(android, "google-services.json has no Android app for appId.");
    const plist = fs.readFileSync(path.join(firebaseDir, "GoogleService-Info.plist"), "utf8");
    check(plistValue(plist, "PROJECT_ID") === firebase.projectId,
      "GoogleService-Info.plist belongs to a different Firebase project.");
    check(plistValue(plist, "BUNDLE_ID") === config.appId, "GoogleService-Info.plist is for a different bundle ID.");
    firebaseApps = {
      android: {
        apiKey: android?.api_key?.[0]?.current_key,
        appId: android?.client_info?.mobilesdk_app_id,
        messagingSenderId: services.project_info?.project_number,
        projectId: services.project_info?.project_id,
        storageBucket: services.project_info?.storage_bucket,
      },
      ios: {
        apiKey: plistValue(plist, "API_KEY"),
        appId: plistValue(plist, "GOOGLE_APP_ID"),
        messagingSenderId: plistValue(plist, "GCM_SENDER_ID"),
        projectId: plistValue(plist, "PROJECT_ID"),
        storageBucket: plistValue(plist, "STORAGE_BUCKET"),
        iosBundleId: plistValue(plist, "BUNDLE_ID"),
      },
    };
    for (const [platform, options] of Object.entries(firebaseApps)) {
      for (const [key, value] of Object.entries(options)) {
        check(typeof value === "string" && /^[\w.:-]+$/.test(value),
          `The ${platform} Firebase file has no valid ${key}; download it again from the Firebase console.`);
      }
    }
  }

  errors.push(...findSecrets(dir));

  // In CI, the customer's deploy credential must target this project.
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (serviceAccount) {
    let accountProject;
    try {
      accountProject = JSON.parse(serviceAccount).project_id;
    } catch {
      errors.push("FIREBASE_SERVICE_ACCOUNT is not valid JSON.");
    }
    if (accountProject && accountProject !== firebase.projectId) {
      errors.push(`FIREBASE_SERVICE_ACCOUNT belongs to ${accountProject}, not ${firebase.projectId}.`);
    }
  }

  if (errors.length > 0) fail(`Deployment "${id}" is invalid:\n  - ${errors.join("\n  - ")}`);
  return { ...config, firebase, links, api, features, firebaseApps };
}

function findSecrets(dir) {
  const found = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true, recursive: true })) {
    if (!entry.isFile()) continue;
    const file = path.join(entry.parentPath ?? entry.path, entry.name);
    const relative = path.relative(root, file);
    // A customer deployment folder can be a clone of the customer's repository.
    if (path.relative(dir, file).split(path.sep).includes(".git")) continue;
    if (secretFileExtensions.includes(path.extname(entry.name).toLowerCase())) {
      found.push(`${relative} looks like a secret file; keep it in the customer's accounts only.`);
      continue;
    }
    const content = fs.readFileSync(file, "utf8");
    const match = secretPatterns.find(([pattern]) => pattern.test(content));
    if (match) found.push(`${relative} contains ${match[1]}; remove it from the repository.`);
  }
  return found;
}

function dartDefines(config) {
  const defines = {
    DEPLOYMENT_ID: config.deploymentId,
    APP_NAME: config.appName,
    APP_ID: config.appId,
    FIREBASE_PROJECT_ID: config.firebase.projectId,
    AUTH_ACTION_HOST: config.firebase.authActionHost,
    FUNCTIONS_REGION: config.firebase.functionsRegion,
    AUTH_ACTION_CONTINUE_URL: config.links.authActionContinueUrl,
    PRIVACY_POLICY_URL: config.links.privacyPolicyUrl,
    TERMS_OF_SERVICE_URL: config.links.termsOfServiceUrl,
    SUPPORT_EMAIL: config.links.supportEmail,
    API_BASE_URL: config.api.baseUrl,
    SEED_COLOR: `0xFF${config.seedColor.slice(1).toUpperCase()}`,
  };
  for (const [key, define] of Object.entries(featureDefines)) {
    defines[define] = String(config.features[key]);
  }
  return defines;
}

/** The FlutterFire CLI's firebase_options.dart, built from the two console files. */
function firebaseOptionsDart(apps, header) {
  const options = (values) => Object.entries(values).map(([key, value]) => `    ${key}: '${value}',`).join("\n");
  const unsupported = (platform) => `        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ${platform}.',
        );`;
  return `// ${header}
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the selected deployment.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
${unsupported("web").replace(/^ {2}/gm, "")}
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
${unsupported("this platform")}
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
${options(apps.android)}
  );

  static const FirebaseOptions ios = FirebaseOptions(
${options(apps.ios)}
  );
}
`;
}

/** The FlutterFire CLI's firebase.json metadata for the two apps. */
function flutterFireJson(apps) {
  const projectId = apps.android.projectId;
  return {
    flutter: {
      platforms: {
        android: {
          default: { projectId, appId: apps.android.appId, fileOutput: "android/app/google-services.json" },
        },
        dart: {
          "lib/firebase_options.dart": {
            projectId,
            configurations: { android: apps.android.appId, ios: apps.ios.appId },
          },
        },
      },
    },
  };
}

function writeGenerated(relative, content) {
  const file = path.join(frontend, relative);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content);
}

function use(id) {
  const config = load(id);
  for (const [name, target] of Object.entries(firebaseFiles)) {
    fs.copyFileSync(path.join(deploymentsDir, id, "firebase", name), path.join(frontend, target));
  }
  const header = `Generated by tool/deployment.mjs from deployments/${id}/deployment.json. Do not edit.`;
  writeGenerated("lib/firebase_options.dart", firebaseOptionsDart(config.firebaseApps, header));
  writeGenerated("firebase.json", `${JSON.stringify(flutterFireJson(config.firebaseApps), null, 2)}\n`);
  writeGenerated("deployment.g.json", `${JSON.stringify(dartDefines(config), null, 2)}\n`);
  writeGenerated("android/deployment.properties", [
    `# ${header}`,
    `appId=${config.appId}`,
    `appName=${config.appName}`,
    `authActionHost=${config.firebase.authActionHost}`,
    "",
  ].join("\n"));
  // Firebase phone auth returns from reCAPTCHA through the encoded iOS app ID.
  const iosPlist = fs.readFileSync(path.join(deploymentsDir, id, "firebase", "GoogleService-Info.plist"), "utf8");
  const iosAppId = plistValue(iosPlist, "GOOGLE_APP_ID") ?? fail("GoogleService-Info.plist has no GOOGLE_APP_ID.");
  writeGenerated("ios/Flutter/Deployment.xcconfig", [
    `// ${header}`,
    `APP_ID=${config.appId}`,
    `APP_DISPLAY_NAME=${config.appName}`,
    `AUTH_ACTION_HOST=${config.firebase.authActionHost}`,
    `FIREBASE_IOS_URL_SCHEME=app-${iosAppId.replaceAll(":", "-")}`,
    "",
  ].join("\n"));

  // Expose the identity to later Codemagic steps.
  if (process.env.CM_ENV) {
    fs.appendFileSync(process.env.CM_ENV, [
      `APP_ID=${config.appId}`,
      `FIREBASE_PROJECT_ID=${config.firebase.projectId}`,
      `AUTH_ACTION_HOST=${config.firebase.authActionHost}`,
      "",
    ].join("\n"));
  }
  console.log(`Using deployment "${id}": ${config.appName} (${config.appId}) on Firebase ${config.firebase.projectId}.`);
  console.log("Run the app with: cd frontend && flutter run --dart-define-from-file=deployment.g.json");
}

function git(...args) {
  try {
    return execFileSync("git", args, { cwd: root, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    fail(`git ${args.join(" ")} failed; release builds need a git checkout.`);
  }
}

/**
 * Customer deployments are built only from the release tag of the version in
 * pubspec.yaml (docs/RELEASE_AND_SUPPORT.md). Internal deployments may build
 * from any commit.
 */
function releaseCheck(config) {
  const id = config.deploymentId;
  if (config.internal) {
    console.log(`Deployment "${id}" is internal; any commit may be built.`);
    return;
  }
  const pubspec = fs.readFileSync(path.join(frontend, "pubspec.yaml"), "utf8");
  const version = pubspec.match(/^version:\s*(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)(?:\+\d+)?\s*$/m)?.[1]
    ?? fail("frontend/pubspec.yaml has no version such as 1.2.0+1.");
  const expected = `v${version}`;
  const tags = process.env.CM_TAG ? [process.env.CM_TAG] : git("tag", "--points-at", "HEAD").split("\n");
  if (!tags.includes(expected)) {
    fail(`Deployment "${id}" is built only from release tag ${expected} (the version in pubspec.yaml), `
      + `but this commit is ${tags.filter(Boolean).join(", ") || "untagged"}. `
      + "Start the build on the release tag; see docs/RELEASE_AND_SUPPORT.md.");
  }
  if (git("status", "--porcelain", "--untracked-files=no") !== "") {
    fail(`Deployment "${id}" is built only from release tag ${expected} without local changes; commit or discard them.`);
  }
  console.log(`Deployment "${id}" is building release ${expected}.`);
}

/**
 * Puts a customer's deployment folder in place from the customer's own
 * repository: DEPLOYMENT_REPO (git URL), with DEPLOYMENT_REPO_SSH_KEY (a
 * read-only deploy key) for a private SSH URL. Without DEPLOYMENT_REPO, the
 * deployment must be one of ours, committed in this repository.
 */
function fetchDeployment(id) {
  const target = path.join(deploymentsDir, id);
  const tracked = git("ls-files", "--", `deployments/${id}/deployment.json`) !== "";
  const repo = process.env.DEPLOYMENT_REPO;
  if (!repo) {
    if (!tracked) fail(`Deployment "${id}" is not in this repository; set DEPLOYMENT_REPO to the customer's deployment repository.`);
    console.log(`Deployment "${id}" is committed in this repository.`);
    return;
  }
  if (tracked) fail(`Deployment "${id}" is committed in this repository; remove DEPLOYMENT_REPO for it.`);

  fs.rmSync(target, { recursive: true, force: true });
  const env = { ...process.env };
  let keyDir;
  if (process.env.DEPLOYMENT_REPO_SSH_KEY) {
    keyDir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "deployment-key-"));
    const keyFile = path.join(keyDir, "key");
    fs.writeFileSync(keyFile, `${process.env.DEPLOYMENT_REPO_SSH_KEY.trim()}\n`, { mode: 0o600 });
    env.GIT_SSH_COMMAND = `ssh -i "${keyFile}" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new`;
  }
  try {
    execFileSync("git", ["clone", "--quiet", "--depth", "1", repo, target], { env, stdio: "inherit" });
  } catch {
    fail(`Cannot clone ${repo}; check DEPLOYMENT_REPO and that its deploy key is added to that repository.`);
  } finally {
    if (keyDir) fs.rmSync(keyDir, { recursive: true, force: true });
  }
  const commit = execFileSync("git", ["-C", target, "rev-parse", "--short", "HEAD"], { encoding: "utf8" }).trim();
  fs.rmSync(path.join(target, ".git"), { recursive: true, force: true });
  const config = load(id);
  if (process.env.CM_ENV) fs.appendFileSync(process.env.CM_ENV, `DEPLOYMENT_REPO_COMMIT=${commit}\n`);
  console.log(`Fetched deployment "${id}" (${config.appName}) from ${repo} at commit ${commit}.`);
}

function deployBackend(id) {
  const config = load(id);
  releaseCheck(config);
  // Firebase loads functions/.env.<projectId> at deploy time (git-ignored).
  fs.writeFileSync(
    path.join(root, "backend", "functions", `.env.${config.firebase.projectId}`),
    `# Generated by tool/deployment.mjs from deployments/${id}/deployment.json.\n`
      + `FUNCTIONS_REGION=${config.firebase.functionsRegion}\n`,
  );
  console.log(`Deploying Functions (${config.firebase.functionsRegion}) and rules to ${config.firebase.projectId}...`);
  try {
    execFileSync("npx", [
      "firebase", "deploy",
      "--config", "../firebase.json",
      "--only", "functions,firestore:rules,storage",
      "--project", config.firebase.projectId,
      "--non-interactive",
    ], { cwd: path.join(root, "backend", "functions"), stdio: "inherit", shell: process.platform === "win32" });
  } catch {
    fail(`Firebase deploy to ${config.firebase.projectId} failed; see the Firebase CLI output above.`);
  }
}

function list() {
  const ids = fs.existsSync(deploymentsDir)
    ? fs.readdirSync(deploymentsDir, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => e.name)
    : [];
  for (const id of ids) {
    try {
      const config = load(id);
      console.log(`${id}\t${config.appName}\t${config.appId}\t${config.firebase.projectId}`);
    } catch (error) {
      console.log(`${id}\tINVALID: ${error.message.split("\n")[0]}`);
    }
  }
}

const [command, arg] = process.argv.slice(2);
try {
  switch (command) {
    case "list": list(); break;
    case "check": {
      const config = load(deploymentIdFrom(arg));
      console.log(`Deployment "${config.deploymentId}" is valid.`);
      break;
    }
    case "use": use(deploymentIdFrom(arg)); break;
    case "deploy-backend": deployBackend(deploymentIdFrom(arg)); break;
    case "release-check": releaseCheck(load(deploymentIdFrom(arg))); break;
    case "fetch": fetchDeployment(deploymentIdFrom(arg)); break;
    default:
      console.error("Usage: node tool/deployment.mjs <list|check|use|deploy-backend|release-check|fetch> [deployment-id]");
      process.exit(2);
  }
} catch (error) {
  if (!(error instanceof DeploymentError)) throw error;
  console.error(error.message);
  process.exit(1);
}
