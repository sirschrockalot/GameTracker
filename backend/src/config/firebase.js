const admin = require('firebase-admin');

let initialized = false;

async function initFirebase() {
  if (initialized) return;
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const cred = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    admin.initializeApp({ credential: admin.credential.cert(cred) });
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
  } else {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON or GOOGLE_APPLICATION_CREDENTIALS required');
  }
  initialized = true;
}

function getAuth() {
  return admin.auth();
}

module.exports = { initFirebase, getAuth };
