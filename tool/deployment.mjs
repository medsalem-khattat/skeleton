#!/usr/bin/env node
// Selects, checks, and deploys one deployment described by
// deployments/<id>/deployment.json. See docs/DEPLOYMENT.md.
//
//   node tool/deployment.mjs list
//   node tool/deployment.mjs check  [id]
//   node tool/deployment.mjs use    [id]
//   node tool/deployment.mjs deploy-backend [id]
//
// [id] defaults to the DEPLOYMENT_ID environment variable.
// Secrets never live in this repository; this script refuses to continue if
// it finds one in a deployment folder.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const deploymentsDir = path.join(root, "deployments");
const frontend = path.join(root, "frontend");

/** Public Firebase client files: deployment copy -> app location. */
const firebaseFiles = {
  "firebase_options.dart": "lib/firebase_options.dart",
  "google-services.json": "android/app/google-services.json",
  "GoogleService-Info.plist": "ios/Runner/GoogleService-Info.plist",
  "firebase.json": "firebase.json",
};

/** deployment.json feature key -> compile-time define read by AppFeatures. */
const featureDefines = {
  authentication: "FEATURE_AUTHENTICATION",
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
  if (missing.length === 0) {
    const services = readJson(path.join(firebaseDir, "google-services.json"));
    check(services.project_info?.project_id === firebase.projectId,
      "google-services.json belongs to a different Firebase project.");
    check(services.client?.some((c) => c.client_info?.android_client_info?.package_name === config.appId),
      "google-services.json has no Android app for appId.");
    const plist = fs.readFileSync(path.join(firebaseDir, "GoogleService-Info.plist"), "utf8");
    check(plistValue(plist, "PROJECT_ID") === firebase.projectId,
      "GoogleService-Info.plist belongs to a different Firebase project.");
    check(plistValue(plist, "BUNDLE_ID") === config.appId, "GoogleService-Info.plist is for a different bundle ID.");
    const options = fs.readFileSync(path.join(firebaseDir, "firebase_options.dart"), "utf8");
    const optionProjects = [...options.matchAll(/projectId:\s*'([^']*)'/g)].map((m) => m[1]);
    check(optionProjects.length > 0 && optionProjects.every((p) => p === firebase.projectId),
      "firebase_options.dart belongs to a different Firebase project.");
    const bundleIds = [...options.matchAll(/iosBundleId:\s*'([^']*)'/g)].map((m) => m[1]);
    check(bundleIds.every((b) => b === config.appId), "firebase_options.dart is for a different iOS bundle ID.");
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
  return { ...config, firebase, links, api, features };
}

function findSecrets(dir) {
  const found = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true, recursive: true })) {
    if (!entry.isFile()) continue;
    const file = path.join(entry.parentPath ?? entry.path, entry.name);
    const relative = path.relative(root, file);
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
  writeGenerated("deployment.g.json", `${JSON.stringify(dartDefines(config), null, 2)}\n`);
  writeGenerated("android/deployment.properties", [
    `# ${header}`,
    `appId=${config.appId}`,
    `appName=${config.appName}`,
    `authActionHost=${config.firebase.authActionHost}`,
    "",
  ].join("\n"));
  writeGenerated("ios/Flutter/Deployment.xcconfig", [
    `// ${header}`,
    `APP_ID=${config.appId}`,
    `APP_DISPLAY_NAME=${config.appName}`,
    `AUTH_ACTION_HOST=${config.firebase.authActionHost}`,
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

function deployBackend(id) {
  const config = load(id);
  console.log(`Deploying Functions and rules to ${config.firebase.projectId}...`);
  execFileSync("npx", [
    "firebase", "deploy",
    "--config", "../firebase.json",
    "--only", "functions,firestore:rules,storage",
    "--project", config.firebase.projectId,
    "--non-interactive",
  ], { cwd: path.join(root, "backend", "functions"), stdio: "inherit", shell: process.platform === "win32" });
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
    default:
      console.error("Usage: node tool/deployment.mjs <list|check|use|deploy-backend> [deployment-id]");
      process.exit(2);
  }
} catch (error) {
  if (!(error instanceof DeploymentError)) throw error;
  console.error(error.message);
  process.exit(1);
}
