// functions/ai_proxy.js
// Cloud Function: OpenAI Embeddings Proxy
// Uses Secret Manager to keep the API key off the client.
//
// Deployed as: getEmbedding (HTTPS Callable)

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Secret Manager — key stored as: openai-api-key (version latest)
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const secretClient = new SecretManagerServiceClient();

let _cachedKey = null;

async function getOpenAiKey() {
  if (_cachedKey) return _cachedKey;
  const [version] = await secretClient.accessSecretVersion({
    name: 'projects/' + process.env.GCLOUD_PROJECT + '/secrets/openai-api-key/versions/latest',
  });
  _cachedKey = version.payload.data.toString('utf8').trim();
  return _cachedKey;
}

/**
 * Callable: getEmbedding
 * Request:  { texts: string[] }
 * Response: { embeddings: number[][] }
 */
exports.getEmbedding = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const texts = data.texts;
  if (!Array.isArray(texts) || texts.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'texts must be a non-empty array.');
  }
  if (texts.length > 100) {
    throw new functions.https.HttpsError('invalid-argument', 'Maximum 100 texts per request.');
  }

  const apiKey = await getOpenAiKey();

  const fetch = (...args) => import('node-fetch').then(({ default: f }) => f(...args));
  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'text-embedding-3-small',
      input: texts,
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    console.error('OpenAI embedding error:', err);
    throw new functions.https.HttpsError('internal', 'OpenAI API error: ' + err);
  }

  const json = await response.json();
  const embeddings = json.data.map((d) => d.embedding);

  // Log usage for monitoring
  await admin.firestore().collection('ai_usage_logs').add({
    type: 'embedding',
    userId: context.auth.uid,
    tokenCount: json.usage?.total_tokens ?? 0,
    textCount: texts.length,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { embeddings };
});
