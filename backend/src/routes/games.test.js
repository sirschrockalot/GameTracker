'use strict';

// Lightweight test: completed quarter protection blocks edits to locked quarters.
function parseCompletedQuarters(jsonStr) {
  if (!jsonStr || typeof jsonStr !== 'string') return new Set();
  try {
    const arr = JSON.parse(jsonStr);
    return new Set(Array.isArray(arr) ? arr.filter((n) => Number.isInteger(n)) : []);
  } catch (_) {
    return new Set();
  }
}

function completedQuarterProtectionViolation(existingCompleted, incomingLineups) {
  const incoming = incomingLineups || {};
  for (const q of existingCompleted) {
    if (incoming[String(q)] !== undefined) return true;
  }
  return false;
}

function test() {
  let passed = 0;
  let failed = 0;
  const existingCompleted = parseCompletedQuarters('[1, 2]');

  if (completedQuarterProtectionViolation(existingCompleted, { '1': ['a', 'b', 'c', 'd', 'e'] })) {
    passed++;
  } else {
    failed++;
    console.error('Expected violation when incoming changes completed quarter 1');
  }

  if (!completedQuarterProtectionViolation(existingCompleted, { '3': ['a', 'b', 'c', 'd', 'e'] })) {
    passed++;
  } else {
    failed++;
    console.error('Expected no violation when incoming only changes quarter 3');
  }

  if (completedQuarterProtectionViolation(existingCompleted, { '2': [] })) {
    passed++;
  } else {
    failed++;
    console.error('Expected violation when incoming changes completed quarter 2');
  }

  console.log(`Games route protection: ${passed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

test();
