import { SignedInUser } from '../models/hr.models';

const TOKEN_KEY = 'hr_token';
const USER_KEY = 'hr_user';
const ACTIVITY_KEY = 'hr_last_activity';
const EXPIRES_KEY = 'hr_session_expires';

export const IDLE_LIMIT_MS = 15 * 60 * 1000;

export interface StoredSession {
  token: string | null;
  user: SignedInUser | null;
}

export function loadSession(): StoredSession {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);

  const token = sessionStorage.getItem(TOKEN_KEY);
  const user = readUser();
  if (!token || !user || sessionStaleReason()) {
    clearStoredSession();
    return { token: null, user: null };
  }

  return { token, user };
}

export function saveSession(token: string, user: SignedInUser): void {
  sessionStorage.setItem(TOKEN_KEY, token);
  sessionStorage.setItem(USER_KEY, JSON.stringify(user));
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
  const expiresAt = readTokenExpiry(token);
  if (expiresAt) {
    sessionStorage.setItem(EXPIRES_KEY, String(expiresAt));
  }
  markActivity(true);
}

export function clearStoredSession(): void {
  sessionStorage.removeItem(TOKEN_KEY);
  sessionStorage.removeItem(USER_KEY);
  sessionStorage.removeItem(ACTIVITY_KEY);
  sessionStorage.removeItem(EXPIRES_KEY);
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

export function markActivity(force = false): void {
  if (!sessionStorage.getItem(TOKEN_KEY)) return;
  const now = Date.now();
  const previous = Number(sessionStorage.getItem(ACTIVITY_KEY) || 0);
  if (!force && now - previous < 5000) return;
  sessionStorage.setItem(ACTIVITY_KEY, String(now));
}

export function sessionStaleReason(): 'idle' | 'expired' | null {
  if (!sessionStorage.getItem(TOKEN_KEY)) return null;
  const expires = Number(sessionStorage.getItem(EXPIRES_KEY) || 0);
  if (expires && Date.now() >= expires) return 'expired';
  const activity = Number(sessionStorage.getItem(ACTIVITY_KEY) || 0);
  if (!activity || Date.now() - activity > IDLE_LIMIT_MS) return 'idle';
  return null;
}

function readUser(): SignedInUser | null {
  try {
    const raw = sessionStorage.getItem(USER_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as SignedInUser;
  } catch {
    return null;
  }
}

function readTokenExpiry(token: string): number | null {
  try {
    const body = token.split('.')[0];
    if (!body) return null;
    const bytes = Uint8Array.from(atob(body), (char) => char.charCodeAt(0));
    const payload = JSON.parse(new TextDecoder().decode(bytes)) as { expiresAt?: number };
    return typeof payload.expiresAt === 'number' ? payload.expiresAt * 1000 : null;
  } catch {
    return null;
  }
}
