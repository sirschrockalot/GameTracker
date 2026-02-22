const jwt = require('jsonwebtoken');

function authJwt(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'unauthorized', message: 'Missing or invalid Authorization header' });
  }
  const token = authHeader.slice(7);
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'] });
    if (!decoded.sub) {
      return res.status(401).json({ error: 'unauthorized', message: 'Invalid token' });
    }
    req.userId = decoded.sub;
    req.displayName = decoded.displayName ?? null;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'unauthorized', message: 'Invalid or expired token' });
  }
}

module.exports = { authJwt };
