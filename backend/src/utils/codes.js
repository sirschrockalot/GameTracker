const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function randomCode(length = 6) {
  let s = '';
  for (let i = 0; i < length; i++) {
    s += CHARS[Math.floor(Math.random() * CHARS.length)];
  }
  return s;
}

function generateUniqueCode(existingSet, length = 6, maxAttempts = 20) {
  for (let i = 0; i < maxAttempts; i++) {
    const code = randomCode(length);
    if (!existingSet.has(code)) return code;
  }
  return randomCode(length + 1);
}

module.exports = { randomCode, generateUniqueCode };
