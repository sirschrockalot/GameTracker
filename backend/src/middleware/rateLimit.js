const rateLimit = require('express-rate-limit');

function rateLimitHandler(options) {
  return (req, res, next) => {
    const resetTime = req.rateLimit?.resetTime ?? Date.now() + 60000;
    const retryAfterSeconds = Math.max(0, Math.ceil((resetTime - Date.now()) / 1000));
    res.status(429).json({
      error: 'rate_limited',
      message: options.message || 'Too many requests',
      retryAfterSeconds,
    });
  };
}

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler({ message: 'Too many requests' }),
});

const registerLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler({ message: 'Too many registration attempts' }),
});

const joinLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler({ message: 'Too many join attempts' }),
});

const bootstrapLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler({ message: 'Too many bootstrap attempts' }),
});

module.exports = { globalLimiter, registerLimiter, joinLimiter, bootstrapLimiter };
