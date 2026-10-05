// Supabase Edge Function: send-push
//
// Sends an FCM push for one Firestore `notifications/{id}` document.
// Replaces the Firebase Cloud Functions triggers, which need the paid Blaze
// plan; Supabase Edge Functions and FCM are both free at this scale.
//
// Request:  POST { notificationId }   header  x-firebase-token: <Firebase ID token>
// Rules:    the caller must be the notification's senderId, each doc is
//           pushed at most once, and the receiver's notification settings
//           are respected.
//
// Secret:   FIREBASE_SERVICE_ACCOUNT = the full service-account JSON from
//           Firebase console > Project settings > Service accounts.

import { createRemoteJWKSet, importPKCS8, jwtVerify, SignJWT } from "npm:jose@5.9.6";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  private_key_id: string;
}

const serviceAccount: ServiceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}");
const PROJECT_ID = serviceAccount.project_id;
const FIRESTORE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const firebaseKeys = createRemoteJWKSet(
  new URL("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"),
);

// Android channel ids created by LocalNotificationService in the app.
const CHANNELS: Record<string, string> = {
  chat_message: "chat_message",
  chat: "chat_message",
  swap_request: "swap_request",
  swap: "swap_request",
  completion_request: "swap_request",
  session: "sessions",
  asset_upload: "asset_upload",
  assignment: "assignment",
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-firebase-token",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ── Google OAuth token for the service account (cached ~55 min) ──────────
let cachedAccess: { token: string; expires: number } | null = null;

async function googleAccessToken(): Promise<string> {
  if (cachedAccess && cachedAccess.expires > Date.now()) return cachedAccess.token;
  const key = await importPKCS8(serviceAccount.private_key, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/datastore",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT", kid: serviceAccount.private_key_id })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(key);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  if (!res.ok) throw new Error(`OAuth token request failed: ${res.status} ${await res.text()}`);
  const { access_token, expires_in } = await res.json();
  cachedAccess = { token: access_token, expires: Date.now() + (expires_in - 300) * 1000 };
  return access_token;
}

// ── Firestore REST helpers ────────────────────────────────────────────────
// deno-lint-ignore no-explicit-any
function decodeValue(v: any): unknown {
  if (v == null) return null;
  if ("stringValue" in v) return v.stringValue;
  if ("integerValue" in v) return Number(v.integerValue);
  if ("doubleValue" in v) return v.doubleValue;
  if ("booleanValue" in v) return v.booleanValue;
  if ("timestampValue" in v) return v.timestampValue;
  if ("nullValue" in v) return null;
  if ("mapValue" in v) return decodeFields(v.mapValue.fields ?? {});
  if ("arrayValue" in v) return (v.arrayValue.values ?? []).map(decodeValue);
  return null;
}

// deno-lint-ignore no-explicit-any
function decodeFields(fields: Record<string, any>): Record<string, any> {
  return Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, decodeValue(v)]));
}

// deno-lint-ignore no-explicit-any
async function getDoc(path: string, token: string): Promise<Record<string, any> | null> {
  const res = await fetch(`${FIRESTORE}/${path}`, { headers: { Authorization: `Bearer ${token}` } });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Firestore GET ${path}: ${res.status} ${await res.text()}`);
  return decodeFields((await res.json()).fields ?? {});
}

async function listDocIds(path: string, token: string): Promise<string[]> {
  const res = await fetch(`${FIRESTORE}/${path}?pageSize=50&mask.fieldPaths=token`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) return [];
  const { documents = [] } = await res.json();
  // deno-lint-ignore no-explicit-any
  return documents.map((d: any) => decodeURIComponent(d.name.split("/").pop()));
}

async function deleteDoc(path: string, token: string) {
  await fetch(`${FIRESTORE}/${path}`, { method: "DELETE", headers: { Authorization: `Bearer ${token}` } });
}

async function markPushed(notificationId: string, token: string) {
  await fetch(
    `${FIRESTORE}/notifications/${notificationId}?updateMask.fieldPaths=pushedAt&currentDocument.exists=true`,
    {
      method: "PATCH",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ fields: { pushedAt: { timestampValue: new Date().toISOString() } } }),
    },
  );
}

// ── Receiver preferences (same fields the app's settings screen writes) ──
// deno-lint-ignore no-explicit-any
async function receiverWantsPush(receiverId: string, notification: Record<string, any>, token: string) {
  const settings = (await getDoc(`users/${receiverId}/settings/notifications`, token)) ?? {};
  if (settings.pushEnabled === false) return false;
  const type = String(notification.type ?? "");
  const isChat = type === "chat_message" || type === "chat";
  if (isChat) {
    if (settings.chatMessagesEnabled === false || settings.directMessagesEnabled === false ||
        settings.chatNotificationsMuted === true) return false;
    const convoId = notification.data?.conversationId ?? notification.actionId;
    if (convoId) {
      const convo = await getDoc(`conversations/${convoId}`, token);
      if (convo?.muted?.[receiverId] === true) return false;
    }
  }
  if ((type === "swap_request" || type === "swap") && settings.swapRequestsEnabled === false) return false;
  return true;
}

// FCM data values must all be strings; nested `data` is flattened.
// deno-lint-ignore no-explicit-any
function fcmData(notificationId: string, n: Record<string, any>): Record<string, string> {
  const out: Record<string, string> = {};
  const put = (k: string, v: unknown) => {
    if (v == null || typeof v === "object") return;
    out[k] = String(v);
  };
  for (const [k, v] of Object.entries(n.data ?? {})) put(k, v);
  for (const k of ["type", "senderId", "senderName", "actionRoute", "actionId", "courseId", "assetId"]) put(k, n[k]);
  out.notificationId = notificationId;
  return out;
}

// ── Handler ───────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method-not-allowed" }, 405);
  if (!PROJECT_ID) return json({ error: "FIREBASE_SERVICE_ACCOUNT secret is not set" }, 500);

  // 1. Who is calling?
  let callerUid: string;
  try {
    const idToken = req.headers.get("x-firebase-token") ?? "";
    const { payload } = await jwtVerify(idToken, firebaseKeys, {
      issuer: `https://securetoken.google.com/${PROJECT_ID}`,
      audience: PROJECT_ID,
    });
    callerUid = String(payload.sub ?? "");
    if (!callerUid) throw new Error("no uid");
  } catch {
    return json({ error: "unauthenticated" }, 401);
  }

  const { notificationId } = await req.json().catch(() => ({}));
  if (typeof notificationId !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(notificationId)) {
    return json({ error: "invalid notificationId" }, 400);
  }

  try {
    const access = await googleAccessToken();

    // 2. Load the notification and check the caller created it.
    const n = await getDoc(`notifications/${notificationId}`, access);
    if (!n) return json({ error: "not-found" }, 404);
    if (n.senderId !== callerUid) return json({ error: "forbidden" }, 403);
    if (n.pushedAt) return json({ skipped: "already-sent" });

    const receiverId = String(n.receiverId ?? n.recipientId ?? "");
    if (!receiverId || receiverId === callerUid) return json({ skipped: "no-receiver" });

    await markPushed(notificationId, access);
    if (!(await receiverWantsPush(receiverId, n, access))) return json({ skipped: "receiver-settings" });

    // 3. Collect the receiver's device tokens.
    const tokens = new Set(await listDocIds(`users/${receiverId}/deviceTokens`, access));
    const user = await getDoc(`users/${receiverId}`, access);
    if (typeof user?.fcmToken === "string" && user.fcmToken) tokens.add(user.fcmToken);
    if (tokens.size === 0) return json({ skipped: "no-devices" });

    // 4. Send through FCM HTTP v1.
    const type = String(n.type ?? "system");
    const data = fcmData(notificationId, n);
    const title = String(n.title || "Skill SwapX");
    const body = String(n.body ?? n.message ?? "");
    let sent = 0;

    await Promise.all([...tokens].map(async (token) => {
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`, {
        method: "POST",
        headers: { Authorization: `Bearer ${access}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data,
            android: {
              priority: "HIGH",
              notification: {
                channel_id: CHANNELS[type] ?? "system",
                sound: "default",
                // Newer messages in the same chat replace the older banner.
                ...(data.conversationId && type === "chat_message" ? { tag: data.conversationId } : {}),
              },
            },
            apns: { payload: { aps: { sound: "default" } } },
          },
        }),
      });
      if (res.ok) {
        sent++;
        return;
      }
      const err = await res.text();
      console.warn(`FCM send failed for ${receiverId}: ${res.status} ${err}`);
      // Token is stale (app uninstalled / data cleared): forget it.
      if (res.status === 404 || err.includes("UNREGISTERED") || err.includes("registration token is not a valid")) {
        await deleteDoc(`users/${receiverId}/deviceTokens/${encodeURIComponent(token)}`, access);
      }
    }));

    return json({ sent, devices: tokens.size });
  } catch (e) {
    console.error("send-push failed", e);
    return json({ error: "internal", message: String(e) }, 500);
  }
});
