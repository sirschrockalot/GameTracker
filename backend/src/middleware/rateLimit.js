const rateLimit = require('express-rate-limit');

function rateLimitHandler(options) {
  return (req, res, next) => {
    const retryAfter = req.rateLimit?.resetTime
      ? Math.max(0, Math.ceil((req.rateLimit.resetTime - Date.now()) / 1000))
      : 60;
    res.status(429).json({
      error: 'rate_limited',
      message: options.message || 'Too many requests',
      retryAfterSeconds: retryAfter,
    });
  };
}

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  message: 'Too many requests',
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler({ message: 'Too many requests' }),
});

const registerLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: 'Too many registration attempts',
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler({ message: 'Too many registration attempts' }),
});

const joinLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 20,
  message: 'Too many join attempts',
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler({ message: 'Too many join attempts' }),
});

module.exports = { globalLimiter, registerLimiter, joinLimiter };
