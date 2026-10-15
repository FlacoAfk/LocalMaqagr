import { test } from 'node:test';
import { strictEqual, throws } from 'node:assert/strict';
import { requireSessionToken } from '../../src/lib/sessionToken.js';

test('uses the persistent session token when present', () => {
  const localStorageRef = { getItem: () => 'access-token' };
  const sessionStorageRef = { getItem: () => 'fallback-token' };

  strictEqual(requireSessionToken(localStorageRef, sessionStorageRef), 'access-token');
});

test('falls back to the session storage token', () => {
  const localStorageRef = { getItem: () => null };
  const sessionStorageRef = { getItem: () => 'session-token' };

  strictEqual(requireSessionToken(localStorageRef, sessionStorageRef), 'session-token');
});

test('fails instead of silently returning a mock result without a token', () => {
  const emptyStorage = { getItem: () => null };

  throws(() => requireSessionToken(emptyStorage, emptyStorage), {
    code: 'UNAUTHORIZED',
    message: 'Inicia sesión para realizar este cálculo.',
  });
});

test('treats inaccessible browser storage as a missing session', () => {
  const inaccessibleStorage = {
    getItem() {
      throw new Error('Storage is blocked');
    },
  };

  throws(() => requireSessionToken(inaccessibleStorage, inaccessibleStorage), {
    code: 'UNAUTHORIZED',
  });
});
