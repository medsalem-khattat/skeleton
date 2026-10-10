#!/usr/bin/env node
// Sets up a deployment's Firebase project from its deployment.json: the
// console work of docs/customer-setup/2-google-cloud-firebase.md (Part 2B),
// in minutes. Safe to run again: every step checks first and skips what is
// already done, and the summary lists what is left by hand.
//
//   node tool/provision.mjs <id> [--create] [--billing-account <ID>]
//
//   --create            create the Firebase project if it does not exist
//   --billing-account   link this Cloud Billing account (Blaze plan)
//
// Signs in with the Firebase CLI login (`firebase login`), or with
// GOOGLE_APPLICATION_CREDENTIALS. Needs `npm ci` in backend/functions.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const functionsDir = path.join(root, "backend", "functions");
const require = createRequire(path.join(functionsDir, "package.json"));

const deployRoles = [
  "roles/firebase.admin",
  "roles/cloudfunctions.admin",
  "roles/iam.serviceAccountUser",
  "roles/artifactregistry.admin",
];
const apis = [
  "firebase.googleapis.com",
  "identitytoolkit.googleapis.com",
  "firestore.googleapis.com",
  "firebaseremoteconfig.googleapis.com",
  "iam.googleapis.com",
];
const blazeApis = ["firebasestorage.googleapis.com", "storage.googleapis.com"];

class ProvisionError extends Error {}
const manual = [];

function args() {
  const [id, ...rest] = process.argv.slice(2);
  if (!id || !/^[a-z0-9][a-z0-9-]*$/.test(id)) {
    throw new ProvisionError("Usage: node tool/provision.mjs <id> [--create] [--billing-account <ID>]");
  }
  const billing = rest.indexOf("--billing-account");
  return {
    id,
    create: rest.includes("--create"),
    billingAccount: billing >= 0 ? rest[billing + 1] : undefined,
  };
}

function readDeployment(id) {
  const file = path.join(root, "deployments", id, "deployment.json");
  if (!fs.existsSync(file)) throw new ProvisionError(`No ${path.relative(root, file)}; create it first.`);
  const config = JSON.parse(fs.readFileSync(file, "utf8"));
  const region = config.firebase?.functionsRegion ?? "us-central1";
  return {
    appName: config.appName,
    appId: config.appId,
    projectId: config.firebase?.projectId,
    region,
    firestoreLocation: config.firebase?.firestoreLocation ?? region,
    phone: config.features?.authentication !== false && config.features?.phoneVerification !== false,
    appleId: config.stores?.appleId ?? "",
  };
}

async function accessToken(projectId) {
  const apiv2 = require("firebase-tools/lib/apiv2");
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    const auth = require("firebase-tools/lib/auth");
    const { requireAuth } = require("firebase-tools/lib/requireAuth");
    const account = auth.getGlobalDefaultAccount();
    if (!account) throw new ProvisionError("Not signed in: run `firebase login` (in backend/functions: npx firebase login).");
    await requireAuth({ project: projectId, ...account });
  } else {
    const { requireAuth } = require("firebase-tools/lib/requireAuth");
    await requireAuth({ project: projectId });
  }
  return apiv2.getAccessToken();
}

function client(token, projectId) {
  return async function call(method, url, body, headers = {}) {
    const response = await fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        "x-goog-user-project": projectId,
        "Content-Type": "application/json; charset=UTF-8",
        ...headers,
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await response.text();
    const json = text ? JSON.parse(text) : {};
    return { status: response.status, json, etag: response.headers.get("etag") };
  };
}

async function wait(call, url, what) {
  for (let i = 0; i < 90; i++) {
    const { json } = await call("GET", url);
    if (json.done) {
      if (json.error) throw new ProvisionError(`${what} failed: ${json.error.message}`);
      return json.response;
    }
    await new Promise((resolve) => setTimeout(resolve, 2000));
  }
  throw new ProvisionError(`${what} did not finish in 3 minutes.`);
}

function fail(what, result) {
  throw new ProvisionError(`${what}: HTTP ${result.status} ${result.json?.error?.message ?? ""}`.trim());
}

async function step(name, run) {
  const started = Date.now();
  const outcome = await run();
  const seconds = ((Date.now() - started) / 1000).toFixed(0);
  console.log(`${outcome.startsWith("skipped") || outcome.startsWith("manual") ? "-" : "✓"} ${name}: ${outcome} (${seconds}s)`);
}

async function main() {
  const { id, create, billingAccount } = args();
  const d = readDeployment(id);
  const started = Date.now();
  console.log(`Provisioning deployment "${id}" in Firebase project ${d.projectId}...`);

  const token = await accessToken(d.projectId);
  const call = client(token, d.projectId);
  const P = `projects/${d.projectId}`;
  let blaze = false;

  await step("Firebase project", async () => {
    const { status } = await call("GET", `https://firebase.googleapis.com/v1beta1/${P}`);
    if (status === 200) return "exists";
    if (!create) throw new ProvisionError(`Project ${d.projectId} not found; pass --create to create it.`);
    execFileSync("npx", ["--no-install", "firebase", "projects:create", d.projectId,
      "--display-name", d.appName, "--non-interactive"],
    { cwd: functionsDir, stdio: "inherit", shell: process.platform === "win32" });
    return "created";
  });

  await step("Blaze plan (billing)", async () => {
    const info = await call("GET", `https://cloudbilling.googleapis.com/v1/${P}/billingInfo`);
    if (info.json.billingEnabled) {
      blaze = true;
      return `linked to ${info.json.billingAccountName}`;
    }
    if (!billingAccount) {
      manual.push("Link an open Cloud Billing account (rerun with --billing-account <ID>), then rerun: Storage and the backend need Blaze.");
      return "manual: no open billing account linked";
    }
    const name = billingAccount.startsWith("billingAccounts/") ? billingAccount : `billingAccounts/${billingAccount}`;
    const result = await call("PUT", `https://cloudbilling.googleapis.com/v1/${P}/billingInfo`, { billingAccountName: name });
    if (result.status !== 200) fail("Linking billing", result);
    blaze = true;
    return `linked to ${name}`;
  });

  await step("APIs", async () => {
    const wanted = blaze ? [...apis, ...blazeApis] : apis;
    const listed = await call("GET", `https://serviceusage.googleapis.com/v1/${P}/services?filter=state:ENABLED&pageSize=200`);
    const enabled = new Set((listed.json.services ?? []).map((s) => s.config.name));
    const missing = wanted.filter((api) => !enabled.has(api));
    if (missing.length === 0) return "enabled";
    const result = await call("POST", `https://serviceusage.googleapis.com/v1/${P}/services:batchEnable`, { serviceIds: missing });
    if (result.status !== 200) fail("Enabling APIs", result);
    if (!result.json.done) await wait(call, `https://serviceusage.googleapis.com/v1/${result.json.name}`, "Enabling APIs");
    return `enabled ${missing.join(", ")}`;
  });

  await step("Authentication", async () => {
    const url = `https://identitytoolkit.googleapis.com/admin/v2/${P}/config`;
    const current = await call("GET", url);
    if (current.status === 404) {
      manual.push(`Firebase console → Build → Authentication → Get started (https://console.firebase.google.com/project/${d.projectId}/authentication), then rerun.`);
      return "manual: click Get started once in the console";
    }
    if (current.status !== 200) fail("Reading Authentication", current);
    const signIn = current.json.signIn ?? {};
    if (signIn.email?.enabled && signIn.email?.passwordRequired && Boolean(signIn.phoneNumber?.enabled) === d.phone) {
      return d.phone ? "email/password and phone on" : "email/password on";
    }
    const result = await call("PATCH",
      `${url}?updateMask=signIn.email.enabled,signIn.email.passwordRequired,signIn.phoneNumber.enabled`,
      { signIn: { email: { enabled: true, passwordRequired: true }, phoneNumber: { enabled: d.phone } } });
    if (result.status !== 200) fail("Configuring Authentication", result);
    return d.phone ? "enabled email/password and phone" : "enabled email/password";
  });

  await step("Firestore", async () => {
    const url = `https://firestore.googleapis.com/v1/${P}/databases/(default)`;
    const current = await call("GET", url);
    if (current.status === 200) return `exists in ${current.json.locationId}`;
    if (current.status !== 404) fail("Reading Firestore", current);
    const result = await call("POST", `https://firestore.googleapis.com/v1/${P}/databases?databaseId=(default)`,
      { type: "FIRESTORE_NATIVE", locationId: d.firestoreLocation });
    if (result.status !== 200) fail("Creating Firestore", result);
    await wait(call, `https://firestore.googleapis.com/v1/${result.json.name}`, "Creating Firestore");
    return `created in ${d.firestoreLocation}`;
  });

  await step("Storage bucket", async () => {
    if (!blaze) return "skipped: needs Blaze";
    const listed = await call("GET", `https://firebasestorage.googleapis.com/v1beta/${P}/buckets`);
    if (listed.status === 200 && (listed.json.buckets ?? []).length > 0) return "exists";
    const result = await call("POST", `https://firebasestorage.googleapis.com/v1alpha/${P}/defaultBucket`,
      { location: d.firestoreLocation });
    if (result.status !== 200) fail("Creating the Storage bucket", result);
    return `created ${result.json.bucket?.name ?? ""} in ${d.firestoreLocation}`.trim();
  });

  const apps = {};
  for (const [platform, collection, idField, body] of [
    ["android", "androidApps", "packageName", { packageName: d.appId, displayName: `${d.appName} Android` }],
    ["ios", "iosApps", "bundleId", { bundleId: d.appId, displayName: `${d.appName} iOS` }],
  ]) {
    await step(`${platform === "ios" ? "iOS" : "Android"} app`, async () => {
      const listed = await call("GET", `https://firebase.googleapis.com/v1beta1/${P}/${collection}?pageSize=100`);
      if (listed.status !== 200) fail(`Listing ${platform} apps`, listed);
      const found = (listed.json.apps ?? []).find((app) => app[idField] === d.appId);
      if (found) {
        apps[platform] = found.appId;
        return `registered (${found.appId})`;
      }
      const result = await call("POST", `https://firebase.googleapis.com/v1beta1/${P}/${collection}`, body);
      if (result.status !== 200) fail(`Registering the ${platform} app`, result);
      const app = await wait(call, `https://firebase.googleapis.com/v1beta1/${result.json.name}`, `Registering the ${platform} app`);
      apps[platform] = app.appId;
      return `registered now (${app.appId})`;
    });
  }

  await step("Firebase config files", async () => {
    const dir = path.join(root, "deployments", id, "firebase");
    fs.mkdirSync(dir, { recursive: true });
    const written = [];
    for (const [platform, collection] of [["android", "androidApps"], ["ios", "iosApps"]]) {
      const result = await call("GET", `https://firebase.googleapis.com/v1beta1/${P}/${collection}/${apps[platform]}/config`);
      if (result.status !== 200) fail(`Downloading the ${platform} config`, result);
      const file = path.join(dir, result.json.configFilename);
      const content = Buffer.from(result.json.configFileContents, "base64").toString("utf8");
      // Compare without line endings: a Windows checkout has CRLF.
      const normalize = (text) => text.replace(/\r\n/g, "\n");
      if (!fs.existsSync(file) || normalize(fs.readFileSync(file, "utf8")) !== normalize(content)) {
        fs.writeFileSync(file, content);
        written.push(result.json.configFilename);
      }
    }
    return written.length ? `wrote ${written.join(", ")}` : "up to date";
  });

  await step("Remote Config", async () => {
    const url = `https://firebaseremoteconfig.googleapis.com/v1/${P}/remoteConfig`;
    const current = await call("GET", url);
    if (current.status !== 200) fail("Reading Remote Config", current);
    const template = current.json;
    const parameters = template.parameters ?? {};
    // The minimum version is only seeded; it is raised by hand at end of support.
    const seeded = { minimum_app_version: "0.0.0" };
    // Store links follow the deployment file.
    const derived = { android_store_url: `https://play.google.com/store/apps/details?id=${d.appId}` };
    if (d.appleId) derived.ios_store_url = `https://apps.apple.com/app/id${d.appleId}`;
    else manual.push("Remote Config: set stores.appleId in deployment.json once the App Store Connect app exists, then rerun.");
    const changed = [
      ...Object.keys(seeded).filter((key) => !parameters[key]),
      ...Object.keys(derived).filter((key) => parameters[key]?.defaultValue?.value !== derived[key]),
    ];
    if (changed.length === 0) return "up to date";
    const values = { ...seeded, ...derived };
    for (const key of changed) parameters[key] = { defaultValue: { value: values[key] }, valueType: "STRING" };
    delete template.version;
    const result = await call("PUT", url, { ...template, parameters }, { "If-Match": current.etag ?? "*" });
    if (result.status !== 200) fail("Publishing Remote Config", result);
    return `published ${changed.join(", ")}`;
  });

  await step("Deploy service account", async () => {
    const email = `codemagic-deploy@${d.projectId}.iam.gserviceaccount.com`;
    const get = await call("GET", `https://iam.googleapis.com/v1/${P}/serviceAccounts/${email}`);
    let outcome = "exists";
    if (get.status === 404) {
      const result = await call("POST", `https://iam.googleapis.com/v1/${P}/serviceAccounts`,
        { accountId: "codemagic-deploy", serviceAccount: { displayName: "Codemagic deploy" } });
      if (result.status !== 200) fail("Creating the deploy service account", result);
      outcome = "created";
    } else if (get.status !== 200) {
      fail("Reading the deploy service account", get);
    }
    const iam = `https://cloudresourcemanager.googleapis.com/v1/${P}`;
    const policy = await call("POST", `${iam}:getIamPolicy`, {});
    if (policy.status !== 200) fail("Reading IAM", policy);
    const member = `serviceAccount:${email}`;
    const bindings = policy.json.bindings ?? [];
    const missing = deployRoles.filter((role) => !bindings.some((b) => b.role === role && b.members?.includes(member)));
    if (missing.length > 0) {
      for (const role of missing) {
        const binding = bindings.find((b) => b.role === role);
        if (binding) binding.members.push(member);
        else bindings.push({ role, members: [member] });
      }
      const result = await call("POST", `${iam}:setIamPolicy`, { policy: { ...policy.json, bindings } });
      if (result.status !== 200) fail("Granting the deploy roles", result);
      outcome += `, granted ${missing.length} role(s)`;
    }
    manual.push(`Create a JSON key for ${email} (Google Cloud console → IAM & Admin → Service Accounts → Keys) and paste it straight into Codemagic: group firebase_deploy, FIREBASE_SERVICE_ACCOUNT, Secret. Skip if it is already there.`);
    return outcome;
  });

  manual.push(`Upload the team's APNs key in Firebase → Project settings → Cloud Messaging (https://console.firebase.google.com/project/${d.projectId}/settings/cloudmessaging), if not done.`);

  if (fs.existsSync(path.join(root, "deployments", id, "firebase", "google-services.json"))) {
    try {
      execFileSync("node", [path.join(root, "tool", "deployment.mjs"), "check", id], { stdio: "inherit" });
    } catch {
      throw new ProvisionError(`deployments/${id} does not pass the check; see above.`);
    }
  }

  console.log(`\nDone in ${((Date.now() - started) / 1000).toFixed(0)}s.`);
  if (manual.length) console.log(`Left by hand:\n${manual.map((m) => `  - ${m}`).join("\n")}`);
}

main().catch((error) => {
  if (!(error instanceof ProvisionError)) throw error;
  console.error(error.message);
  process.exit(1);
});
