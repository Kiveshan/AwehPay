const { google } = require('googleapis');
const { JWT } = require('google-auth-library');

// Google Play Developer API access uses a DIFFERENT service account from the Firebase
// Admin one (server.js's loadServiceAccount) — it must be created under Play Console ->
// Setup -> API access and granted Finance + view-app-info permissions scoped to this app.
// - Cloud (Elastic Beanstalk): GOOGLE_PLAY_SERVICE_ACCOUNT_B64 — base64 of the JSON key,
//   mirroring FIREBASE_SERVICE_ACCOUNT_B64 so it survives EB env-var transport intact.
// - Local dev: GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS points at the JSON key file on disk.
function loadPlayServiceAccount() {
  if (process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_B64) {
    const json = Buffer.from(
      process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_B64,
      'base64'
    ).toString('utf8');
    try {
      return JSON.parse(json);
    } catch (err) {
      throw new Error(
        `GOOGLE_PLAY_SERVICE_ACCOUNT_B64 did not decode to valid JSON: ${err.message}`
      );
    }
  }

  if (process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS) {
    return require(process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS);
  }

  throw new Error(
    'No Google Play Developer API credentials found. Set ' +
      'GOOGLE_PLAY_SERVICE_ACCOUNT_B64 (base64 JSON, preferred for cloud/Beanstalk) or ' +
      'GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS (file path, for local dev).'
  );
}

let androidPublisherClient = null;

function getAndroidPublisher() {
  if (androidPublisherClient) return androidPublisherClient;

  const credentials = loadPlayServiceAccount();
  const authClient = new JWT({
    email: credentials.client_email,
    key: credentials.private_key,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  androidPublisherClient = google.androidpublisher({
    version: 'v3',
    auth: authClient,
  });
  return androidPublisherClient;
}

const PACKAGE_NAME = process.env.GOOGLE_PLAY_PACKAGE_NAME || 'com.awehpay.app';

// Fetches the current state of a subscription purchase directly from Google Play —
// the source of truth for status/expiry. RTDN notifications only signal "something
// changed"; they don't carry the actual subscription state, so callers must re-fetch.
async function getSubscriptionPurchase(purchaseToken, packageName = PACKAGE_NAME) {
  const androidPublisher = getAndroidPublisher();
  const { data } = await androidPublisher.purchases.subscriptionsv2.get({
    packageName,
    token: purchaseToken,
  });
  return data;
}

async function acknowledgeSubscriptionPurchase(
  purchaseToken,
  productId,
  packageName = PACKAGE_NAME
) {
  const androidPublisher = getAndroidPublisher();
  await androidPublisher.purchases.subscriptions.acknowledge({
    packageName,
    subscriptionId: productId,
    token: purchaseToken,
    requestBody: {},
  });
}

module.exports = {
  PACKAGE_NAME,
  getSubscriptionPurchase,
  acknowledgeSubscriptionPurchase,
};
