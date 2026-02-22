const { getAuth } = require('../config/firebase');

async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'unauthorized', message: 'Missing or invalid Authorization header' });
  }
  const token = authHeader.slice(7);
  try {
    const decoded = await getAuth().verifyIdToken(token);
    req.userId = decoded.uid;
    next();
  } catch (err) {
    if (err.code === 'auth/id-token-expired' || err.code === 'auth/argument-error') {
      return res.status(401).json({ error: 'unauthorized', message: 'Invalid or expired token' });
    }
    return res.status(403).json({ error: 'forbidden', message: 'Token verification failed' });
  }
}

module.exports = { authMiddleware };
